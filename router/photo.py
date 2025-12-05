from fastapi import APIRouter, File, UploadFile, Form, HTTPException, Depends
from fastapi.responses import JSONResponse, FileResponse
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from PIL import Image
from io import BytesIO
import os
import uuid
import numpy as np
import pickle
from uuid import UUID
from PIL import Image
from sqlalchemy.future import select
from .auth import get_current_user
from .lobby_utils import ensure_user_in_lobby
from database import get_db
from face_recognation.model import FaceClassifier
import models

UPLOAD_DIR = "uploads/photos"
ENCODINGS_DIR = "uploads/encodings"
os.makedirs(UPLOAD_DIR, exist_ok=True)
os.makedirs(ENCODINGS_DIR, exist_ok=True)

router = APIRouter(prefix="/photos", tags=["photos"])


def save_encoding(encoding: np.ndarray, user_id: int) -> str:
    encoding_filename = f"{user_id}_{uuid.uuid4()}.pkl"
    encoding_path = os.path.join(ENCODINGS_DIR, encoding_filename)

    with open(encoding_path, 'wb') as f:
        pickle.dump(encoding, f)

    return encoding_path


def load_encoding(encoding_path: str) -> np.ndarray:
    with open(encoding_path, 'rb') as f:
        return pickle.load(f)


@router.post("/{lobby_id}/upload")
async def upload_photo(
        lobby_id: str,
        file: UploadFile = File(...),
        current_user=Depends(get_current_user),
        db: AsyncSession = Depends(get_db)
):
    await ensure_user_in_lobby(db, lobby_id, current_user.id)
    lobby_uuid = UUID(lobby_id)

    if file.content_type not in ["image/jpeg", "image/png"]:
        raise HTTPException(status_code=400, detail="Invalid image format")

    contents = await file.read()

    face_encoding = encode_face(contents)
    if face_encoding is None:
        raise HTTPException(status_code=400, detail="No face detected in the image")

    filename = f"{current_user.id}_{uuid.uuid4()}_{file.filename}"
    file_path = os.path.join(UPLOAD_DIR, filename)

    with open(file_path, "wb") as f:
        f.write(contents)

    encoding_path = save_encoding(face_encoding, current_user.id)

    photo = models.Photo(
        user_id=current_user.id,
        # filename=filename,
        lobby_id=lobby_uuid,
        file_path=file_path,
        encoding_path=encoding_path
    )
    db.add(photo)
    await db.commit()
    await db.refresh(photo)

    user_photos = await db.execute(
        select(models.Photo).filter(
            models.Photo.user_id == current_user.id,
            models.Photo.id != photo.id
        )
    )
    existing_photos = user_photos.scalars().all()

    matches = []
    for existing_photo in existing_photos:
        try:
            saved_encoding = load_encoding(existing_photo.encoding_path)
            distance = np.linalg.norm(face_encoding - saved_encoding)
            if distance < 0.6:
                matches.append({
                    "photo_id": existing_photo.id,
                    "distance": float(distance),
                    "match": True
                })
            else:
                matches.append({
                    "photo_id": existing_photo.id,
                    "distance": float(distance),
                    "match": False
                })
        except Exception as e:
            print(f"Error loading encoding for photo {existing_photo.id}: {e}")
            continue

    has_match = any(match["match"] for match in matches)

    return JSONResponse({
        "status": "match" if has_match else "no_match",
        "message": "Face recognized as same person" if has_match else "New face detected",
        "matches": matches,
        "lobby_id": lobby_id,
        "user_id": current_user.id,
        "photo_id": photo.id
    })
