import encodings

from fastapi import APIRouter, File, UploadFile, Form, HTTPException
from fastapi.responses import JSONResponse
from PIL import Image
from io import BytesIO

import numpy as np
import json
import os

from face_recognation.detector import encode_face, compare_faces

router = APIRouter(prefix="/photos", tags=["photos"])

KNOWN_FACES_PATH = "face_recognation/known_faces.json"


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
    file: UploadFile = File(...)
):
    if file.content_type not in ["image/jpeg", "image/png"]:
        raise HTTPException(status_code=400, detail="Invalid image format")

    contents = await file.read()

    encoding = encode_face(contents)
    if encoding is None:
        raise HTTPException(status_code=400, detail="Face not found")

    known_faces, known_encodings = load_known_faces()
    if not known_encodings:
        raise HTTPException(status_code=404, detail="No registered faces found")

    result = compare_faces(known_encodings, encodings, tolerance=0.6)

    matched_name = None
    for name, encoding in zip(known_names, result):
        if is_match:
            matched_name = name
            break

    if matched_name:
        status = "recognized"
        person = matched_name
    else:
        status = "unknown"
        person = None

    # image = Image.open(BytesIO(contents))
    #
    # width, height = image.size

    return JSONResponse({
        "lobby_id": lobby_id,
        "user_id": user_id,
        "status": status,
        "recognized": person,
        # "image_size": {"width": width, "height": height}
    })
