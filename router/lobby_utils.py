# lobby_utils.py
from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
import uuid
import models


async def ensure_user_in_lobby(db: AsyncSession, lobby_id: int, user_id: int):
    result = await db.execute(
        select(models.LobbyPlayer).where(
            models.LobbyPlayer.lobby_id == uuid.UUID(lobby_id),
            models.LobbyPlayer.user_id == user_id
        )
    )
    player = result.scalar_one_or_none()

    if not player:
        raise HTTPException(status_code=403, detail="User is not in this lobby")
