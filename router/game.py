from fastapi import APIRouter, Depends
from sqlalchemy import update, select
from sqlalchemy.ext.asyncio import AsyncSession

from math import sqrt

from database import get_db
from models import UserProfile

router = APIRouter(prefix="/lobbies", tags=["lobbies"])


@router.post("/update-location")
async def update_location(user_id: int, lat: float, lon: float, db: AsyncSession = Depends(get_db)):
    await db.execute(
        update(UserProfile)
        .where(UserProfile.user_id == user_id)
        .values(location_lat=lat, location_lon=lon)
    )
    await db.commit()
    return {"status": "ok"}


@router.get("/players")
async def get_players_locations(db: AsyncSession = Depends(get_db)):
    res = await db.execute(select(UserProfile.user_id, UserProfile.location_lat, UserProfile.location_lon))
    return [{"id": r[0], "lat": r[1], "lon": r[2]} for r in res]


def in_zone(lat1, lon1, lat2, lon2, radius):
    return sqrt((lat1 - lat2)**2 + (lon1 - lon2)**2) <= radius