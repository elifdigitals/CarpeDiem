# photo.py
from fastapi import APIRouter, File, UploadFile, HTTPException, Depends
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession
from io import BytesIO
import os
import uuid
import torch
from PIL import Image
from sqlalchemy.future import select
from .auth import get_current_user
from .lobby_utils import ensure_user_in_lobby
from database import get_db
from face_recognation.detector import extract_face, encode_face
from face_recognation.model import FaceClassifier
import models


UPLOAD_DIR = "uploaded_photos"
os.makedirs(UPLOAD_DIR, exist_ok=True)

router = APIRouter(prefix="/photos", tags=["photos"])


@router.post("/{lobby_id}/upload")
async def upload_photo(
        lobby_id: str,
        file: UploadFile = File(...),
        current_user=Depends(get_current_user),
        db: AsyncSession = Depends(get_db)
):
    await ensure_user_in_lobby(db, lobby_id, current_user.id)

    if file.content_type not in ["image/jpeg", "image/png"]:
        raise HTTPException(status_code=400, detail="Invalid image format")

    contents = await file.read()
    face_image = extract_face(contents)
    if face_image is None:
        raise HTTPException(status_code=400, detail="No face detected in the image")

    unknown_encoding = encode_face(contents)
    if unknown_encoding is None:
        raise HTTPException(status_code=400, detail="Failed to encode the face")

    user_photo = await db.execute(select(models.Photo).filter(models.Photo.user_id == current_user.id))
    user_photos = user_photo.scalars().all()

    for photo in user_photos:
        saved_encoding = torch.load(photo.encoding_path)
        if saved_encoding is None:
            continue

        if compare_faces(saved_encoding, unknown_encoding):
            return JSONResponse({
                "status": "match",
                "message": "This is the same person",
                "lobby_id": lobby_id,
                "user_id": current_user.id
            })

    return JSONResponse({
        "status": "no_match",
        "message": "This face is not recognized",
        "lobby_id": lobby_id,
        "user_id": current_user.id
    })
