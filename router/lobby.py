from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from pydantic import BaseModel
import uuid
import models
from database import get_db
from router.auth import get_current_user
from uuid import UUID

router = APIRouter(prefix="/lobbies", tags=["lobbies"])

class LobbyCreate(BaseModel):
    name: str
    mode: str = "default"
    time_limit: int = 15

class ReadyStatus(BaseModel):
    is_ready: bool = True

@router.post("/create")
async def create_lobby(
    data: LobbyCreate, 
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    print(f"🎯 Creating lobby for user {current_user.id}: {data.name}, mode: {data.mode}")
    
    lobby = models.Lobby(
        id=uuid.uuid4(), 
        host_id=current_user.id, 
        mode=data.mode,
        name=data.name,
        time_limit=data.time_limit
    )
    db.add(lobby)
    await db.commit()
    await db.refresh(lobby)
    
    player = models.LobbyPlayer(lobby_id=lobby.id, user_id=current_user.id)
    db.add(player)
    await db.commit()
    
    print(f"✅ Lobby created: {lobby.id}")
    
    return {
        "lobby_id": str(lobby.id), 
        "host": current_user.id, 
        "mode": data.mode,
        "name": data.name,
        "time_limit": data.time_limit
    }

@router.post("/{lobby_id}/join")
async def join_lobby(
    lobby_id: str, 
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    print(f"🎮 User {current_user.id} attempting to join lobby {lobby_id}")

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
            models.LobbyPlayer.user_id == current_user.id
        )
    )
    existing_player = player_res.scalar_one_or_none()

    if existing_player:
        raise HTTPException(status_code=400, detail="User already in this lobby")

    player = models.LobbyPlayer(lobby_id=lobby.id, user_id=current_user.id)
    db.add(player)
    await db.commit()
    
    print(f"✅ User {current_user.id} successfully joined lobby {lobby_id}")
    
    return {
        "lobby_id": str(lobby.id), 
        "joined": current_user.id,
        "success": True,
        "message": f"User {current_user.id} joined lobby {lobby_id}"
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

    players_res = await db.execute(select(models.LobbyPlayer.user_id).where(models.LobbyPlayer.lobby_id == lobby.id))
    players = [row[0] for row in players_res]
    
    return {
        "lobby_id": str(lobby.id), 
        "host": lobby.host_id, 
        "mode": lobby.mode, 
        "status": lobby.status,
        "name": lobby.name,
        "time_limit": lobby.time_limit,
        "players": players
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
        players = [row[0] for row in players_res]
        result.append({
            "lobby_id": str(lobby.id),
            "host": lobby.host_id,
            "mode": lobby.mode,
            "status": lobby.status,
            "name": lobby.name,
            "time_limit": lobby.time_limit,
            "players": players
        })
    return result


@router.post("/{lobby_id}/ready")
async def set_ready_status(
    lobby_id: str,
    data: ReadyStatus,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Устанавливает статус готовности игрока в лобби"""
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
            models.LobbyPlayer.user_id == current_user.id
        )
    )
    player = player_res.scalar_one_or_none()
    if not player:
        raise HTTPException(status_code=404, detail="Player not in lobby")

    player.is_ready = data.is_ready
    await db.commit()
    
    print(f"✅ User {current_user.id} ready status set to {data.is_ready}")

    return {
        "status": "success",
        "message": f"Ready status set to {data.is_ready}",
        "is_ready": data.is_ready
    }


@router.post("/{lobby_id}/start")
async def start_game(
    lobby_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Хост запускает игру (все игроки должны быть готовы)"""
    try:
        lobby_uuid = UUID(lobby_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid lobby ID format")

    res = await db.execute(select(models.Lobby).where(models.Lobby.id == lobby_uuid))
    lobby = res.scalar_one_or_none()
    if not lobby:
        raise HTTPException(status_code=404, detail="Lobby not found")

    # Проверяем, что это хост
    if lobby.host_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only host can start game")

    # Проверяем, что все игроки готовы
    players_res = await db.execute(
        select(models.LobbyPlayer).where(models.LobbyPlayer.lobby_id == lobby_uuid)
    )
    players = players_res.scalars().all()
    
    if not all(p.is_ready for p in players):
        raise HTTPException(status_code=400, detail="Not all players are ready")

    # Обновляем статус лобби
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
    current_user: models.User = Depends(get_current_user)
):
    """Игрок покидает лобби"""
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
            models.LobbyPlayer.user_id == current_user.id
        )
    )
    player = player_res.scalar_one_or_none()
    if not player:
        raise HTTPException(status_code=404, detail="Player not in lobby")

    await db.delete(player)
    await db.commit()
    
    print(f"👋 User {current_user.id} left lobby {lobby_id}")

    return {
        "status": "success",
        "message": "Left lobby",
        "lobby_id": str(lobby.id)
    }
