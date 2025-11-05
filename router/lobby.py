from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from pydantic import BaseModel
import uuid
import models
from database import get_db

router = APIRouter(prefix="/lobbies", tags=["lobbies"])

class LobbyCreate(BaseModel):
    host_id: int
    mode: str = "default"

class LobbyJoin(BaseModel):
    user_id: int

@router.post("/")
async def create_lobby(data: LobbyCreate, db: AsyncSession = Depends(get_db)):
    lobby = models.Lobby(host_id=data.host_id, mode=data.mode)
    db.add(lobby)
    await db.commit()
    await db.refresh(lobby)
    player = models.LobbyPlayer(lobby_id=lobby.id, user_id=data.host_id)
    db.add(player)
    await db.commit()
    return {"lobby_id": int(lobby.id), "host": data.host_id, "mode": data.mode}

@router.post("/{lobby_id}/join")
async def join_lobby(lobby_id: int, data: LobbyJoin, db: AsyncSession = Depends(get_db)):
    res = await db.execute(select(models.Lobby).where(models.Lobby.id == uuid.UUID(lobby_id)))
    lobby = res.scalar_one_or_none()
    if not lobby:
        raise HTTPException(status_code=404, detail="Lobby not found")
    player = models.LobbyPlayer(lobby_id=lobby.id, user_id=data.user_id)
    db.add(player)
    await db.commit()
    return {"lobby_id": int(lobby.id), "joined": data.user_id}

@router.get("/{lobby_id}")
async def get_lobby(lobby_id: int, db: AsyncSession = Depends(get_db)):
    res = await db.execute(select(models.Lobby).where(models.Lobby.id == uuid.UUID(lobby_id)))
    lobby = res.scalar_one_or_none()
    if not lobby:
        raise HTTPException(status_code=404, detail="Lobby not found")
    players_res = await db.execute(select(models.LobbyPlayer.user_id).where(models.LobbyPlayer.lobby_id == lobby.id))
    players = [row[0] for row in players_res]
    return {"lobby_id": str(lobby.id), "host": lobby.host_id, "mode": lobby.mode, "status": lobby.status, "players": players}
