# from django.http import FileResponse
from fastapi import APIRouter, File, UploadFile, Form, HTTPException, Depends
from fastapi.responses import JSONResponse
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from PIL import Image
from io import BytesIO
import numpy as np
import json
import os
import uuid
import torch
from io import BytesIO

from database import get_db
from face_recognation.detector import encode_face, compare_faces
from face_recognation.model import FaceClassifier
import models

MODEL_PATH = "dataset/model.pt"
UPLOAD_DIR = "uploaded_photos"
os.makedirs(UPLOAD_DIR, exist_ok=True)

# ckpt = torch.load("dataset/model.pt", map_location="cpu")
# classes = ckpt["classes"]
#
# recognizer = FaceClassifier(num_classes=len(classes))
# recognizer.load_state_dict(ckpt["model_state_dict"])
# recognizer.eval()

# ckpt = torch.load("dataset/model.pt", map_location="cpu")
# classes = ckpt["classes"]
# print(classes)
recognize = FaceClassifier(num_classes=3)


router = APIRouter(prefix="/photos", tags=["photos"])


def load_known_faces():
    if not os.path.exists("face_recognation/known_faces.json"):
        return {}, []
    with open("face_recognation/known_faces.json", "r", encoding="utf-8") as f:
        data = json.load(f)
    names = list(data.keys())
    encodings = [np.array(v) for v in data.values()]
    return names, encodings


def save_new_face(name: str, encoding: np.ndarray):
    known_faces, known_encodings = load_known_faces()

    known_faces[name] = encoding.tolist()
    with open(KNOWN_FACES_PATH, "w", encoding="utf-8") as f:
        json.dump(known_faces, f, ensure_ascii=False, indent=4)

    return known_faces


@router.post("/upload")
async def upload_photo(
    lobby_id: str = Form(...),
    user_id: str = Form(...),
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db)
):
    if file.content_type not in ["image/jpeg", "image/png"]:
        raise HTTPException(status_code=400, detail="Invalid image format")

    contents = await file.read()

    img = Image.open(BytesIO(contents)).convert("RGB")

    results = recognizer.predict_from_pil(img, topk=1)

    if results:
        matched_name, confidence = results[0]
        status = "recognized"
        person = matched_name
    else:
        status = "unknown"
        person = None
        person = str(uuid.uuid4())
        encoding = recognizer.predict_from_bytes(contents)[0][1]
        save_new_face(person, encoding)

    file_ext = file.filename.split(".")[-1]
    file_name = f"{uuid.uuid4()}.{file_ext}"
    file_path = os.path.join(UPLOAD_DIR, file_name)

    with open(file_path, "wb") as f:
        f.write(contents)

    photo = models.Photo(
        user_id=user_id,
        lobby_id=uuid.UUID(lobby_id),
        file_path=file_path,
        status=status,
        recognized_person=person
    )
    db.add(photo)
    await db.commit()

    return JSONResponse({
        "lobby_id": lobby_id,
        "user_id": user_id,
        "status": status,
        "recognized": person,
        "file_path": file_path
    })


@router.get("/lobby/{lobby_id}")
async def get_lobby_photos(lobby_id: int, db: AsyncSession = Depends(get_db)):
    res = await db.execute(
        select(models.Photo).where(models.Photo.lobby_id == lobby_id)
    )
    photos = res.scalars().all()
    return [
        {
            "photo_id": p.id,
            "user_id": p.user_id,
            "status": p.status,
            "recognized": p.recognized_person,
            "file_path": p.file_path
        }
        for p in photos
    ]


@router.get("/{photo_id}/file")
async def get_photo_file(photo_id: str, db: AsyncSession = Depends(get_db)):
    res = await db.execute(
        select(models.Photo).where(models.Photo.id == photo_id)
    )
    photo = res.scalar_one_or_none()
    if not photo:
        raise HTTPException(status_code=404, detail="Photo not found")
    if not os.path.exists(photo.file_path):
        raise HTTPException(status_code=404, detail="File missing on server")
    return FileResponse(photo.file_path, media_type="image/jpeg")


