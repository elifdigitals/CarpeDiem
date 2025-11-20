from fastapi import APIRouter, File, UploadFile, Form, HTTPException, Depends
from fastapi.responses import JSONResponse, FileResponse
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from PIL import Image
from io import BytesIO
import os
import uuid
import torch
import numpy as np

from database import get_db
from face_recognation.model import FaceClassifier
import models


MODEL_PATH = "C:/CarpeDiem/dataset/model.pt"
UPLOAD_DIR = "uploaded_photos"
os.makedirs(UPLOAD_DIR, exist_ok=True)

ckpt = torch.load(MODEL_PATH, map_location="cpu")
classes = ckpt["classes"]

recognizer = FaceClassifier(num_classes=len(classes))
recognizer.load_state_dict(ckpt["model_state_dict"])
recognizer.eval()

print(f"{len(classes)} classes:", classes)

router = APIRouter(prefix="/photos", tags=["photos"])


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

    try:
        img = Image.open(BytesIO(contents)).convert("RGB")
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid image data")

    transform = torch.nn.Sequential(
        torch.nn.Identity()
    )

    preprocess = torch.hub.load("pytorch/vision", "transforms").Compose([
        torch.hub.load("pytorch/vision", "transforms").Resize((224, 224)),
        torch.hub.load("pytorch/vision", "transforms").ToTensor(),
        torch.hub.load("pytorch/vision", "transforms").Normalize(
            mean=[0.485, 0.456, 0.406],
            std=[0.229, 0.224, 0.225]
        )
    ])

    input_tensor = preprocess(img).unsqueeze(0)
    with torch.no_grad():
        logits = recognizer(input_tensor)
        probs = torch.softmax(logits, dim=1)
        conf, pred = torch.max(probs, dim=1)
        confidence = float(conf.item())
        predicted_class = classes[pred.item()]

    if confidence < 0.75:
        status = "unknown"
        person = None
    else:
        status = "recognized"
        person = predicted_class

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
        "confidence": confidence,
        "file_path": file_path
    })


@router.get("/{photo_id}/file")
async def get_photo_file(photo_id: str, db: AsyncSession = Depends(get_db)):
    res = await db.execute(select(models.Photo).where(models.Photo.id == photo_id))
    photo = res.scalar_one_or_none()
    if not photo:
        raise HTTPException(status_code=404, detail="Photo not found")
    if not os.path.exists(photo.file_path):
        raise HTTPException(status_code=404, detail="File missing on server")
    return FileResponse(photo.file_path, media_type="image/jpeg")