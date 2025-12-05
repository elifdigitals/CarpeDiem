# lobby.py
from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.ext.asyncio import AsyncSession
from .auth import SECRET_KEY, ALGORITHM
from sqlalchemy.future import select
from pydantic import BaseModel
from jose import jwt, JWTError
from typing import Optional
from database import get_db
from uuid import UUID
from .auth import get_current_user

import models

router = APIRouter(prefix="/lobbies", tags=["lobbies"])

class LobbyCreate(BaseModel):
    lobby_name: str
    selected_mode: str = "default"
    time_limit: int


class ReadyStatus(BaseModel):
    is_ready: bool = True


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
        # is_ready=is_ready
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
        lobby_uuid = UUID(lobby_id)
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
        # is_ready=is_ready
    )
    db.add(player)
    await db.commit()

    return {
        "lobby_id": str(lobby.id),
        "joined": current_user_id,
        "success": True,
        "message": f"User {current_user_id} joined lobby {lobby_id}"
    }


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

    players_res = await db.execute(
        select(models.LobbyPlayer).where(models.LobbyPlayer.lobby_id == lobby.id)
    )
    players = players_res.scalars().all()

    return {
        "lobby_id": str(lobby.id),
        "host": int(lobby.host_id),
        "lobby_name": lobby.lobby_name,
        "mode": lobby.mode,
        "time_limit": lobby.time_limit,
        "status": lobby.status,
        "players": [
            {
                "user_id": int(p.user_id),
                "is_ready": p.is_ready
            }
            for p in players
        ]
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


@router.post("/{lobby_id}/ready")
async def set_ready_status(
        lobby_id: str,
        ready_status: ReadyStatus,
        db: AsyncSession = Depends(get_db),
        authorization: Optional[str] = Header(default=None)
):
    try:
        lobby_uuid = UUID(lobby_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid lobby ID format")

    current_user_id = await get_current_user_id(db, authorization)

    res = await db.execute(select(models.Lobby).where(models.Lobby.id == lobby_uuid))
    lobby = res.scalar_one_or_none()
    if not lobby:
        raise HTTPException(status_code=404, detail="Lobby not found")

    player_res = await db.execute(
        select(models.LobbyPlayer).where(
            models.LobbyPlayer.lobby_id == lobby_uuid,
            models.LobbyPlayer.user_id == current_user_id
        )
    )
    player = player_res.scalar_one_or_none()
    if not player:
        raise HTTPException(status_code=404, detail="Player not in lobby")

    player.is_ready = ready_status.is_ready
    await db.commit()

    return {
        "status": "success",
        "message": f"Ready status set to {ready_status.is_ready}",
        "is_ready": ready_status.is_ready
    }


@router.post("/{lobby_id}/start")
async def start_game(
        lobby_id: str,
        db: AsyncSession = Depends(get_db),
        authorization: Optional[str] = Header(default=None)
):

    try:
        lobby_uuid = UUID(lobby_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid lobby ID format")

    current_user_id = await get_current_user_id(db, authorization)

    res = await db.execute(select(models.Lobby).where(models.Lobby.id == lobby_uuid))
    lobby = res.scalar_one_or_none()
    if not lobby:
        raise HTTPException(status_code=404, detail="Lobby not found")

    if lobby.host_id != current_user_id:
        raise HTTPException(status_code=403, detail="Only host can start game")

    players_res = await db.execute(
        select(models.LobbyPlayer).where(models.LobbyPlayer.lobby_id == lobby_uuid)
    )
    players = players_res.scalars().all()

    if not all(p.is_ready for p in players):
        raise HTTPException(status_code=400, detail="Not all players are ready")

    lobby.status = "in_progress"
    await db.commit()

    print(f"🎮 Game started in lobby {lobby_id}")

    return {
        "status": "success",
        "message": "Game started",
        "lobby_id": str(lobby.id)
    }


@router.post("/{lobby_id}/leave")
async def leave_lobby(
        lobby_id: str,
        db: AsyncSession = Depends(get_db),
        authorization: Optional[str] = Header(default=None)
):

    try:
        lobby_uuid = UUID(lobby_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid lobby ID format")

    current_user_id = await get_current_user_id(db, authorization)

    res = await db.execute(select(models.Lobby).where(models.Lobby.id == lobby_uuid))
    lobby = res.scalar_one_or_none()
    if not lobby:
        raise HTTPException(status_code=404, detail="Lobby not found")

    player_res = await db.execute(
        select(models.LobbyPlayer).where(
            models.LobbyPlayer.lobby_id == lobby_uuid,
            models.LobbyPlayer.user_id == current_user_id
        )
    )
    player = player_res.scalar_one_or_none()
    if not player:
        raise HTTPException(status_code=404, detail="Player not in lobby")

    await db.delete(player)
    await db.commit()

    return {
        "status": "success",
        "message": "Left lobby",
        "lobby_id": str(lobby.id)
    }


@router.delete("/{lobby_id}/kick/{user_id}")
async def kick_player(
        lobby_id: str,
        user_id: int,
        db: AsyncSession = Depends(get_db),
        authorization: Optional[str] = Header(default=None)
):
    current_user_id = await get_current_user_id(db, authorization)

    try:
        lobby_uuid = UUID(lobby_id)
    except ValueError:
        return HTTPException(status_code=400, detail="Invalid lobby ID format")

    res= await db.execute(select(models.Lobby).where(models.Lobby.id == lobby_uuid))
    lobby = res.scalar_one_or_none()

    if not lobby:
        raise HTTPException(status_code=404, detail="Lobby not found")

    if int(current_user_id) != int(lobby.host_id):
        raise HTTPException(status_code=404, detail="Only host can kick")

    players_res = await db.execute(
        select(models.LobbyPlayer).where(
            models.LobbyPlayer.lobby_id == lobby.uuid,
            models.LobbyPlayer.user_id == int(user_id)
        )
    )
    player = players_res.scalar_one_or_none()

    if not player:
        raise HTTPException(status_code=404, detail="Player not found")

    await db.delete(player)

    remaining_players_res = await db.execute(
        select(models.LobbyPlayer).where(models.LobbyPlayer.lobby_id == lobby.uuid)
    )
    remaining_players = remaining_players_res.scalars().all()

    if not remaining_players:
        await db.delete(lobby)

    await db.commit()

    return {
        "message": f"Player {user_id} has been kicked",
    }