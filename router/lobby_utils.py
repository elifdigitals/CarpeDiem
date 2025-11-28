# lobby_utils.py
from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
import uuid
import models


async def ensure_user_in_lobby(db: AsyncSession, lobby_id: int, user_id: int):
    try:
        lobby_uuid = uuid.UUID(int=lobby_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid lobby_id format")


    print(f"Checking if user {user_id} is in lobby {lobby_uuid}")

    result = await db.execute(
        select(models.LobbyPlayer).where(
            models.LobbyPlayer.lobby_id == lobby_uuid,
            models.LobbyPlayer.user_id == user_id
        )
    )
    player = result.scalar_one_or_none()

    if not player:
        raise HTTPException(status_code=403, detail="User is not in this lobby")

    print("User found in lobby.")
