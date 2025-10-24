from fastapi import APIRouter, File, UploadFile, Form, HTTPException, Depends
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession
from PIL import Image
from io import BytesIO
import numpy as np
import json
import os
import uuid

from database import get_db
from face_recognition.detector import encode_face, compare_faces
import models

router = APIRouter(prefix="/photos", tags=["photos"])

KNOWN_FACES_PATH = "face_recognation/known_faces.json"
UPLOAD_DIR = "uploaded_photos"
os.makedirs(UPLOAD_DIR, exist_ok=True)


def load_known_faces():
    if not os.path.exists(KNOWN_FACES_PATH):
        return [], []
    with open(KNOWN_FACES_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)
    names = list(data.keys())
    encodings = [np.array(v) for v in data.values()]
    return names, encodings


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

    encoding = encode_face(contents)
    if encoding is None:
        raise HTTPException(status_code=400, detail="Face not found")

    known_names, known_encodings = load_known_faces()
    if not known_encodings:
        raise HTTPException(status_code=404, detail="No registered faces found")

    results = compare_faces(known_encodings, encoding, tolerance=0.6)

    matched_name = None
    for name, is_match in zip(known_names, results):
        if is_match:
            matched_name = name
            break



    file_ext = file.filename.split(".")[-1]
    file_name = f"{uuid.uuid4()}.{file_ext}"
    file_path = os.path.join(UPLOAD_DIR, file_name)

    with open(file_path, "wb") as f:
        f.write(contents)

    if matched_name:
        status = "recognized"
        person = matched_name
    else:
        status = "unknown"
        person = None

    photo = models.Photo(
        user_id=str(user_id),
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
async def get_lobby_photos(lobby_id: str, db: AsyncSession = Depends(get_db)):
    res = await db.execute(
        select(models.Photo).where(models.Photo.lobby_id == lobby_id)
    )
    photos = res.scalars().all()
    return [
        {
            "photo_id": p.id,
            "user_id": p.user_id,
            "status": p.status,
            "recognized": p.recognized_name,
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