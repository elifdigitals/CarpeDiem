from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from pydantic import BaseModel
import models
from database import get_db

router = APIRouter(prefix="/lobbies", tags=["lobbies"])


class LobbyCreate(BaseModel):
    host_id: int
    lobby_name: str
    selected_mode: str = "default"
    time_limit: int


class LobbyJoin(BaseModel):
    user_id: int


@router.post("/create")
async def create_lobby(data: LobbyCreate, db: AsyncSession = Depends(get_db)):
    print(data)
    lobby = models.Lobby(
        host_id=data.host_id,
        name=data.lobby_name,
        mode=data.selected_mode,
        time_limit=data.time_limit,
    )


    db.add(lobby)
    await db.commit()
    await db.refresh(lobby)

    # auto-join host
    player = models.LobbyPlayer(lobby_id=lobby.id, user_id=data.host_id)
    db.add(player)
    await db.commit()

    return {
        "lobby_id": lobby.id,
        "host": data.host_id,
        "name": lobby.name,
        "mode": lobby.mode,
        "time_limit": lobby.time_limit
    }


@router.post("/{lobby_id}/join")
async def join_lobby(lobby_id: int, data: LobbyJoin, db: AsyncSession = Depends(get_db)):
    res = await db.execute(select(models.Lobby).where(models.Lobby.id == lobby_id))
    lobby = res.scalar_one_or_none()

    if not lobby:
        raise HTTPException(status_code=404, detail="Lobby not found")

    # check if user already joined
    check = await db.execute(
        select(models.LobbyPlayer).where(
            models.LobbyPlayer.lobby_id == lobby_id,
            models.LobbyPlayer.user_id == data.user_id
        )
    )
    exists = check.scalar_one_or_none()
    if exists:
        return {"detail": "User already in lobby"}

    player = models.LobbyPlayer(lobby_id=lobby.id, user_id=data.user_id)
    db.add(player)
    await db.commit()

    return {"lobby_id": lobby.id, "joined": data.user_id}


@router.get("/{lobby_id}")
async def get_lobby(lobby_id: int, db: AsyncSession = Depends(get_db)):
    res = await db.execute(select(models.Lobby).where(models.Lobby.id == lobby_id))
    lobby = res.scalar_one_or_none()

    if not lobby:
        raise HTTPException(status_code=404, detail="Lobby not found")

    players_res = await db.execute(
        select(models.LobbyPlayer.user_id).where(models.LobbyPlayer.lobby_id == lobby.id)
    )
    players = [row[0] for row in players_res]

    return {
        "lobby_id": lobby.id,
        "host": lobby.host_id,
        "name": lobby.name,
        "mode": lobby.mode,
        "time_limit": lobby.time_limit,
        "status": lobby.status,
        "players": players,
    }


@router.get("/")
async def get_lobbies(db: AsyncSession = Depends(get_db)):
    res = await db.execute(select(models.Lobby))
    lobbies = res.scalars().all()

    result = []

    for lobby in lobbies:
        players_res = await db.execute(
            select(models.LobbyPlayer.user_id).where(models.LobbyPlayer.lobby_id == lobby.id)
        )
        players = [row[0] for row in players_res]

        result.append({
            "lobby_id": lobby.id,
            "host": lobby.host_id,
            "name": lobby.name,
            "mode": lobby.mode,
            "time_limit": lobby.time_limit,
            "status": lobby.status,
            "players": players
        })

    return result
