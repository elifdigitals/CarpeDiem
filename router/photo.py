from fastapi import APIRouter, File, UploadFile, Form, HTTPException
from fastapi.responses import JSONResponse
from PIL import Image
from io import BytesIO

router = APIRouter(prefix="/photos", tags=["photos"])

@router.post("/upload")
async def upload_photo(
    lobby_id: str = Form(...),
    user_id: str = Form(...),
    file: UploadFile = File(...)
):
    if file.content_type not in ["image/jpeg", "image/png"]:
        raise HTTPException(status_code=400, detail="Invalid image format")

    contents = await file.read()

    image = Image.open(BytesIO(contents))

    width, height = image.size

    return JSONResponse({
        "lobby_id": lobby_id,
        "user_id": user_id,
        "status": "received",
        "image_size": {"width": width, "height": height}
    })
