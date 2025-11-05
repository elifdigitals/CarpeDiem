from fastapi import APIRouter, Depends, UploadFile, Form, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from datetime import datetime
import os
from database import get_db
from models import User, UserProfile

router = APIRouter(prefix="/profile", tags=["profile"])

UPLOAD_DIR = "uploads/photos"
os.makedirs(UPLOAD_DIR, exist_ok=True)


@router.post("/create")
async def create_profile(
    user_id: int = Form(...),
    full_name: str = Form(...),
    birth_date: str = Form(...),
    location: str = Form(...),
    phone: str = Form(...),
    photo: UploadFile = None,
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(UserProfile).where(UserProfile.user_id == user_id))
    if result.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Profile already exists")

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if not photo:
        raise HTTPException(status_code=400, detail="Photo is required")

    filename = f"user_{user_id}_{photo.filename}"
    filepath = os.path.join(UPLOAD_DIR, filename)

    with open(filepath, "wb") as f:
        f.write(await photo.read())

    profile = UserProfile(
        user_id=user_id,
        full_name=full_name,
        birth_date=datetime.strptime(birth_date, "%Y-%m-%d").date(),
        location=location,
        phone=phone,
        photo_path=filepath
    )

    db.add(profile)
    await db.commit()
    await db.refresh(profile)
    return {"msg": "Profile created", "profile_id": profile.id}


@router.get("/{user_id}")
async def get_profile(user_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(UserProfile).where(UserProfile.user_id == user_id))
    profile = result.scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")

    return {
        "full_name": profile.full_name,
        "birth_date": profile.birth_date,
        "location": profile.location,
        "phone": profile.phone,
        "photo_path": profile.photo_path
    }


@router.put("/update/{user_id}")
async def update_profile(
    user_id: int,
    full_name: str = Form(None),
    birth_date: str = Form(None),
    location: str = Form(None),
    phone: str = Form(None),
    photo: UploadFile = None,
    db: AsyncSession = Depends(get_db)
):
    # Проверяем, что профиль существует
    result = await db.execute(select(UserProfile).where(UserProfile.user_id == user_id))
    profile = result.scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")

    # Обновляем данные, если они переданы
    if full_name:
        profile.full_name = full_name
    if birth_date:
        try:
            profile.birth_date = datetime.strptime(birth_date, "%Y-%m-%d").date()
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD.")
    if location:
        profile.location = location
    if phone:
        profile.phone = phone

    # Обновляем фото, если новое загружено
    if photo:
        filename = f"user_{user_id}_{photo.filename}"
        filepath = os.path.join(UPLOAD_DIR, filename)

        # Удаляем старое фото, если оно есть
        if profile.photo_path and os.path.exists(profile.photo_path):
            os.remove(profile.photo_path)

        with open(filepath, "wb") as f:
            f.write(await photo.read())

        profile.photo_path = filepath

    await db.commit()
    await db.refresh(profile)

    return {"msg": "Profile updated successfully", "user_id": user_id}
