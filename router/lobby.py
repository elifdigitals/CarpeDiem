# lobby.py
from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from pydantic import BaseModel
from typing import Optional
import uuid
import models
from database import get_db

from .auth import SECRET_KEY, ALGORITHM
from jose import jwt, JWTError

router = APIRouter(prefix="/lobbies", tags=["lobbies"])

class LobbyCreate(BaseModel):
    lobby_name: str
    selected_mode: str = "default"
    time_limit: int


class LobbyJoin(BaseModel):
    user_id: int


async def get_current_user_from_token(authorization: Optional[str] = Header(default=None)):
    if not authorization:
        raise HTTPException(
            status_code=401,
            detail="Not authenticated"
        )

    try:
        scheme, token = authorization.split()
        if scheme.lower() != "bearer":
            raise HTTPException(status_code=401, detail="Invalid authentication scheme")

        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise HTTPException(status_code=401, detail="Invalid token")
        return username
    except (ValueError, JWTError):
        raise HTTPException(status_code=401, detail="Invalid token")


async def get_current_user_id(db: AsyncSession, authorization: Optional[str] = Header(default=None)):
    if not authorization:
        raise HTTPException(
            status_code=401,
            detail="Not authenticated"
        )

    try:
        scheme, token = authorization.split()
        if scheme.lower() != "bearer":
            raise HTTPException(status_code=401, detail="Invalid authentication scheme")

        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise HTTPException(status_code=401, detail="Invalid token")

        result = await db.execute(select(models.User).where(models.User.username == username))
        user = result.scalar_one_or_none()

        if not user:
            raise HTTPException(status_code=401, detail="User not found")

        return user.id
    except (ValueError, JWTError):
        raise HTTPException(status_code=401, detail="Invalid token")


@router.post("/create")
async def create_lobby(
        data: LobbyCreate,
        db: AsyncSession = Depends(get_db),
        authorization: Optional[str] = Header(default=None)
):
    current_user_id = await get_current_user_id(db, authorization)

    lobby = models.Lobby(
        host_id=str(current_user_id),
        lobby_name=data.lobby_name,
        mode=data.selected_mode,
        time_limit=data.time_limit,
    )

    db.add(lobby)
    await db.commit()
    await db.refresh(lobby)

    player = models.LobbyPlayer(
        lobby_id=lobby.id,
        user_id=str(current_user_id),
        lat=None,
        lon=None
    )
    db.add(player)
    await db.commit()

    return {
        "lobby_id": lobby.id,
        "host": current_user_id,
        "lobby_name": lobby.lobby_name,
        "mode": lobby.mode,
        "time_limit": lobby.time_limit
    }


@router.post("/{lobby_id}/join")
async def join_lobby(
        lobby_id: str,
        db: AsyncSession = Depends(get_db),
        authorization: Optional[str] = Header(default=None)
):
    try:
        lobby_uuid = uuid.UUID(lobby_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid lobby ID format")

    current_user_id = await get_current_user_id(db, authorization)

    res = await db.execute(select(models.Lobby).where(models.Lobby.id == lobby_uuid))
    lobby = res.scalar_one_or_none()

    if not lobby:
        raise HTTPException(status_code=404, detail="Lobby not found")

    check = await db.execute(
        select(models.LobbyPlayer).where(
            models.LobbyPlayer.lobby_id == lobby_uuid,
            models.LobbyPlayer.user_id == str(current_user_id)
        )
    )
    exists = check.scalar_one_or_none()
    if exists:
        return {"detail": "User already in lobby"}

    player = models.LobbyPlayer(
        lobby_id=lobby.id,
        user_id=str(current_user_id),
        lat=None,
        lon=None
    )
    db.add(player)
    await db.commit()

    return {"lobby_id": str(lobby.id), "joined": current_user_id}


@router.get("/{lobby_id}")
async def get_lobby(lobby_id: str, db: AsyncSession = Depends(get_db)):
    try:
        lobby_uuid = uuid.UUID(lobby_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid lobby ID format")

    res = await db.execute(select(models.Lobby).where(models.Lobby.id == lobby_uuid))
    lobby = res.scalar_one_or_none()

    if not lobby:
        raise HTTPException(status_code=404, detail="Lobby not found")

    players_res = await db.execute(
        select(models.LobbyPlayer.user_id).where(models.LobbyPlayer.lobby_id == lobby.id)
    )
    players = [int(row[0]) for row in players_res]

    return {
        "lobby_id": str(lobby.id),
        "host": int(lobby.host_id),
        "lobby_name": lobby.lobby_name,
        "mode": lobby.mode,
        "time_limit": lobby.time_limit,
        "status": lobby.status,
        "players": players,
    }


@router.get("/")
async def get_lobbies(db: AsyncSession = Depends(get_db)):
    res = await db.execute(select(models.Lobby))
    lobbies = res.scalars().all()
    if not lobbies:
        raise HTTPException(status_code=404, detail="No lobbies found")

    result = []

    for lobby in lobbies:
        players_res = await db.execute(
            select(models.LobbyPlayer.user_id).where(models.LobbyPlayer.lobby_id == lobby.id)
        )
        players = [int(row[0]) for row in players_res]

        result.append({
            "lobby_id": str(lobby.id),
            "host": int(lobby.host_id),
            "lobby_name": lobby.lobby_name,
            "mode": lobby.mode,
            "time_limit": lobby.time_limit,
            "status": lobby.status,
            "players": players
        })

    return result


