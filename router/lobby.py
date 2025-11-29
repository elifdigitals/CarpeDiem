from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from pydantic import BaseModel
import uuid
import models
from database import get_db

from uuid import UUID

router = APIRouter(prefix="/lobbies", tags=["lobbies"])

class LobbyCreate(BaseModel):
    host_id: int
    mode: str = "default"

class LobbyJoin(BaseModel):
    user_id: int


@router.post("/create")
async def create_lobby(data: LobbyCreate, db: AsyncSession = Depends(get_db)):
    lobby = models.Lobby(id=uuid.uuid4(), host_id=data.host_id, mode=data.mode)
    db.add(lobby)
    await db.commit()
    await db.refresh(lobby)
    player = models.LobbyPlayer(lobby_id=lobby.id, user_id=data.host_id)
    db.add(player)
    await db.commit()
    return {"lobby_id": str(lobby.id), "host": data.host_id, "mode": data.mode}


@router.post("/{lobby_id}/join")
async def join_lobby(lobby_id: str, data: LobbyJoin, db: AsyncSession = Depends(get_db)):

    try:
        lobby_uuid = UUID(lobby_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid lobby ID format")

    res = await db.execute(select(models.Lobby).where(models.Lobby.id == lobby_uuid))
    lobby = res.scalar_one_or_none()
    if not lobby:
        raise HTTPException(status_code=404, detail="Lobby not found")

    player_res = await db.execute(
        select(models.LobbyPlayer).where(
            models.LobbyPlayer.lobby_id == lobby_uuid,
            models.LobbyPlayer.user_id == data.user_id
        )
    )
    existing_player = player_res.scalar_one_or_none()

    if existing_player:
        raise HTTPException(status_code=400, detail="User already in this lobby")

    player = models.LobbyPlayer(lobby_id=lobby.id, user_id=data.user_id)
    db.add(player)
    await db.commit()
    return {"lobby_id": lobby.id, "joined": data.user_id}


@router.get("/{lobby_id}")
async def get_lobby(lobby_id: str, db: AsyncSession = Depends(get_db)):

    try:
        lobby_uuid = UUID(lobby_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid lobby ID format")

    res = await db.execute(select(models.Lobby).where(models.Lobby.id == lobby_uuid))
    lobby = res.scalar_one_or_none()
    if not lobby:
        raise HTTPException(status_code=404, detail="Lobby not found")

    players_res = await db.execute(select(models.LobbyPlayer.user_id).where(models.LobbyPlayer.lobby_id == lobby.id))
    players = [int(row[0]) for row in players_res]
    return {"lobby_id": lobby_uuid, "host": int(lobby.host_id), "mode": lobby.mode, "status": lobby.status,
            "players": players}


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
        players = [row[0] for row in players_res]
        result.append({
            "lobby_id": str(lobby.id),
            "host": lobby.host_id,
            "mode": lobby.mode,
            "status": lobby.status,
            "players": players
        })
    return result
