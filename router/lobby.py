from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import joinedload
from pydantic import BaseModel
import uuid
import random
import string
import models
from database import get_db
from router.auth import get_current_user
from uuid import UUID
from datetime import datetime, timedelta

# In-memory countdown store (dev only)
active_countdowns = {}

router = APIRouter(prefix="/lobbies", tags=["lobbies"])

class LobbyCreate(BaseModel):
    name: str
    mode: str = "default"
    time_limit: int = 15

class ReadyStatus(BaseModel):
    is_ready: bool = True

def generate_lobby_code():
    """Генерирует уникальный 6-значный код (буквы и цифры)"""
    chars = string.ascii_uppercase + string.digits
    return ''.join(random.choices(chars, k=6))

@router.post("/create")
async def create_lobby(
    data: LobbyCreate, 
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    print(f"🎯 Creating lobby for user {current_user.id}: {data.name}, mode: {data.mode}")
    
    # Генерируем уникальный код
    code = generate_lobby_code()
    
    lobby = models.Lobby(
        id=uuid.uuid4(), 
        host_id=current_user.id, 
        mode=data.mode,
        name=data.name,
        time_limit=data.time_limit,
        code=code
    )
    db.add(lobby)
    await db.commit()
    await db.refresh(lobby)
    
    # Добавляем создателя в лобби
    player = models.LobbyPlayer(lobby_id=lobby.id, user_id=current_user.id, is_ready=True)
    db.add(player)
    await db.commit()
    
    print(f"✅ Lobby created: {lobby.id} with code: {code}")
    
    return {
        "lobby_id": str(lobby.id), 
        "host_id": current_user.id,
        "host_username": current_user.username,
        "mode": data.mode,
        "name": data.name,
        "time_limit": data.time_limit,
        "code": code
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

    # Получаем лобби
    res = await db.execute(
        select(models.Lobby).where(models.Lobby.id == lobby_uuid)
    )
    lobby = res.scalar_one_or_none()
    
    if not lobby:
        raise HTTPException(status_code=404, detail="Lobby not found")
    
    # Проверяем статус лобби
    if lobby.status != "waiting":
        raise HTTPException(status_code=400, detail="Lobby is not in waiting state")

    # Проверяем, не в лобби ли уже пользователь
    player_res = await db.execute(
        select(models.LobbyPlayer).where(
            models.LobbyPlayer.lobby_id == lobby_uuid,
            models.LobbyPlayer.user_id == current_user.id
        )
    )
    existing_player = player_res.scalar_one_or_none()

    if existing_player:
        print(f"⚠️ User {current_user.id} already in lobby {lobby_id}")
        raise HTTPException(status_code=400, detail="User already in this lobby")

    # Добавляем игрока в лобби
    player = models.LobbyPlayer(lobby_id=lobby.id, user_id=current_user.id)
    db.add(player)
    await db.commit()
    
    print(f"✅ User {current_user.id} successfully joined lobby {lobby_id}")
    
    return {
        "lobby_id": str(lobby.id), 
        "joined": current_user.id,
        "joined_username": current_user.username,
        "success": True,
        "message": f"User {current_user.username} joined lobby {lobby_id}"
    }

@router.get("/{lobby_id}")
async def get_lobby(lobby_id: str, db: AsyncSession = Depends(get_db)):
    try:
        lobby_uuid = UUID(lobby_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid lobby ID format")

    # Получаем лобби
    res = await db.execute(
        select(models.Lobby).where(models.Lobby.id == lobby_uuid)
    )
    lobby = res.scalar_one_or_none()
    
    if not lobby:
        raise HTTPException(status_code=404, detail="Lobby not found")

    # Получаем игроков с их именами и статусом готовности
    players_res = await db.execute(
        select(models.LobbyPlayer, models.User)
        .join(models.User, models.LobbyPlayer.user_id == models.User.id)
        .where(models.LobbyPlayer.lobby_id == lobby.id)
    )
    
    players = []
    for player, user in players_res:
        players.append({
            "user_id": player.user_id,
            "username": user.username,
            "is_ready": player.is_ready
        })
    
    # Получаем информацию о хосте
    host_user_res = await db.execute(
        select(models.User).where(models.User.id == lobby.host_id)
    )
    host_user = host_user_res.scalar_one_or_none()
    
    return {
        "lobby_id": str(lobby.id), 
        "host_id": lobby.host_id,
        "host_username": host_user.username if host_user else "Unknown",
        "mode": lobby.mode, 
        "status": lobby.status,
        "name": lobby.name,
        "time_limit": lobby.time_limit,
        "code": lobby.code,
        "players": players,
        "players_count": len(players)
    }

@router.get("/")
async def get_lobbies(db: AsyncSession = Depends(get_db)):
    # Получаем только ожидающие лобби
    res = await db.execute(
        select(models.Lobby)
        .where(models.Lobby.status == "waiting")
        .order_by(models.Lobby.id)
    )
    lobbies = res.scalars().all()
    
    if not lobbies:
        return []

    result = []
    for lobby in lobbies:
        # Получаем игроков для этого лобби
        players_res = await db.execute(
            select(models.LobbyPlayer, models.User)
            .join(models.User, models.LobbyPlayer.user_id == models.User.id)
            .where(models.LobbyPlayer.lobby_id == lobby.id)
        )
        
        players = []
        for player, user in players_res:
            players.append({
                "user_id": player.user_id,
                "username": user.username,
                "is_ready": player.is_ready
            })
        
        # Получаем информацию о хосте
        host_user_res = await db.execute(
            select(models.User).where(models.User.id == lobby.host_id)
        )
        host_user = host_user_res.scalar_one_or_none()
        
        result.append({
            "lobby_id": str(lobby.id),
            "host_id": lobby.host_id,
            "host_username": host_user.username if host_user else "Unknown",
            "mode": lobby.mode,
            "status": lobby.status,
            "name": lobby.name,
            "time_limit": lobby.time_limit,
            "code": lobby.code,
            "players": players,
            "players_count": len(players)
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

    # Получаем лобби
    res = await db.execute(select(models.Lobby).where(models.Lobby.id == lobby_uuid))
    lobby = res.scalar_one_or_none()
    if not lobby:
        raise HTTPException(status_code=404, detail="Lobby not found")

    # Получаем игрока
    player_res = await db.execute(
        select(models.LobbyPlayer).where(
            models.LobbyPlayer.lobby_id == lobby_uuid,
            models.LobbyPlayer.user_id == current_user.id
        )
    )
    player = player_res.scalar_one_or_none()
    
    if not player:
        raise HTTPException(status_code=404, detail="Player not in lobby")

    # Обновляем статус готовности
    player.is_ready = data.is_ready
    await db.commit()
    
    print(f"✅ User {current_user.id} ready status set to {data.is_ready}")

    return {
        "status": "success",
        "message": f"Ready status set to {data.is_ready}",
        "is_ready": data.is_ready,
        "user_id": current_user.id,
        "username": current_user.username
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
    
    if len(players) < 2:
        raise HTTPException(status_code=400, detail="Need at least 2 players to start")
    
    if not all(p.is_ready for p in players):
        # Получаем список неготовых игроков
        not_ready_players = []
        for p in players:
            if not p.is_ready:
                user_res = await db.execute(
                    select(models.User).where(models.User.id == p.user_id)
                )
                user = user_res.scalar_one_or_none()
                not_ready_players.append(user.username if user else f"User {p.user_id}")
        
        raise HTTPException(
            status_code=400, 
            detail=f"Not all players are ready: {', '.join(not_ready_players)}"
        )

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

    # Получаем лобби
    res = await db.execute(select(models.Lobby).where(models.Lobby.id == lobby_uuid))
    lobby = res.scalar_one_or_none()
    if not lobby:
        raise HTTPException(status_code=404, detail="Lobby not found")

    # Получаем игрока
    player_res = await db.execute(
        select(models.LobbyPlayer).where(
            models.LobbyPlayer.lobby_id == lobby_uuid,
            models.LobbyPlayer.user_id == current_user.id
        )
    )
    player = player_res.scalar_one_or_none()
    
    if not player:
        raise HTTPException(status_code=404, detail="Player not in lobby")

    # Удаляем игрока
    await db.delete(player)
    # Сразу фиксируем удаление игрока, чтобы последующие запросы учитывали изменение
    await db.commit()

    # Проверяем, остались ли игроки в лобби
    remaining_players_res = await db.execute(
        select(models.LobbyPlayer).where(models.LobbyPlayer.lobby_id == lobby_uuid)
    )
    remaining_players = remaining_players_res.scalars().all()

    lobby_deleted = False
    if not remaining_players:
        # Если игроков не осталось, удаляем лобби
        await db.delete(lobby)
        await db.commit()
        lobby_deleted = True
        print(f"🗑️ Lobby {lobby_id} deleted (no players left)")
    else:
        # Если вышел хост, назначаем нового (не удаляем лобби)
        if lobby.host_id == current_user.id:
            # Выбираем первого оставшегося игрока как нового хоста
            new_host_id = remaining_players[0].user_id
            lobby.host_id = new_host_id
            await db.commit()
            print(f"👑 New host for lobby {lobby_id}: user {new_host_id}")
    
    print(f"👋 User {current_user.id} left lobby {lobby_id}")

    return {
        "status": "success",
        "message": "Left lobby",
        "lobby_id": str(lobby.id) if not lobby_deleted else None,
        "lobby_deleted": lobby_deleted,
        "user_id": current_user.id,
        "username": current_user.username
    }


@router.post("/{lobby_id}/start_countdown")
async def start_countdown(
    lobby_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    try:
        lobby_uuid = UUID(lobby_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid lobby ID format")

    res = await db.execute(select(models.Lobby).where(models.Lobby.id == lobby_uuid))
    lobby = res.scalar_one_or_none()
    if not lobby:
        raise HTTPException(status_code=404, detail="Lobby not found")

    if lobby.host_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only host can start countdown")

    # Start countdown (10 seconds)
    started_at = datetime.utcnow()
    duration = 10
    active_countdowns[str(lobby_uuid)] = {
        "started_at": started_at.isoformat(),
        "duration": duration,
        "is_active": True
    }

    return {"status": "success", "message": "Countdown started"}


@router.get("/{lobby_id}/countdown_status")
async def get_countdown_status(
    lobby_id: str,
    db: AsyncSession = Depends(get_db)
):
    data = active_countdowns.get(lobby_id)
    if not data:
        return {"is_active": False, "remaining_seconds": 0, "total_seconds": 10}

    try:
        started_at = datetime.fromisoformat(data["started_at"])
    except Exception:
        return {"is_active": False, "remaining_seconds": 0, "total_seconds": data.get("duration", 10)}

    elapsed = (datetime.utcnow() - started_at).total_seconds()
    remaining = max(0, int(data.get("duration", 10) - elapsed))
    is_active = remaining > 0

    # If countdown finished, clear it
    if not is_active:
        active_countdowns.pop(lobby_id, None)

    return {"is_active": is_active, "remaining_seconds": remaining, "total_seconds": data.get("duration", 10)}

@router.get("/search/{code}")
async def search_lobby_by_code(code: str, db: AsyncSession = Depends(get_db)):
    """Поиск лобби по 6-значному коду"""
    if len(code) != 6:
        raise HTTPException(status_code=400, detail="Code must be 6 characters")
    
    # Ищем лобби по коду
    res = await db.execute(
        select(models.Lobby)
        .where(models.Lobby.code == code.upper())
        .where(models.Lobby.status == "waiting")
    )
    lobby = res.scalar_one_or_none()
    
    if not lobby:
        raise HTTPException(status_code=404, detail="Lobby not found")
    
    # Получаем игроков с их именами
    players_res = await db.execute(
        select(models.LobbyPlayer, models.User)
        .join(models.User, models.LobbyPlayer.user_id == models.User.id)
        .where(models.LobbyPlayer.lobby_id == lobby.id)
    )
    
    players = []
    for player, user in players_res:
        players.append({
            "user_id": player.user_id,
            "username": user.username,
            "is_ready": player.is_ready
        })
    
    # Получаем информацию о хосте
    host_user_res = await db.execute(
        select(models.User).where(models.User.id == lobby.host_id)
    )
    host_user = host_user_res.scalar_one_or_none()
    
    return {
        "lobby_id": str(lobby.id),
        "host_id": lobby.host_id,
        "host_username": host_user.username if host_user else "Unknown",
        "mode": lobby.mode,
        "status": lobby.status,
        "name": lobby.name,
        "time_limit": lobby.time_limit,
        "code": lobby.code,
        "players": players,
        "players_count": len(players)
    }