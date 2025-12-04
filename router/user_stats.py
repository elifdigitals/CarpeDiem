from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func

from database import get_db
import models

router = APIRouter(prefix="/user", tags=["stats"])

@router.get("/{user_id}/stats")
async def get_user_stats(user_id: int, db: AsyncSession = Depends(get_db)):
    # Проверяем существование пользователя
    result = await db.execute(select(models.User).where(models.User.id == user_id))
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Считаем статистику (заглушки - потом заменим реальными запросами)
    # 1. Количество созданных лобби
    result = await db.execute(
        select(func.count()).where(models.Lobby.host_id == user_id)
    )
    lobbies_created = result.scalar() or 0
    
    # 2. Количество игр, в которых участвовал пользователь
    result = await db.execute(
        select(func.count(models.LobbyPlayer.user_id))
        .where(models.LobbyPlayer.user_id == user_id)
    )
    games_played = result.scalar() or 0
    
    # 3. Количество побед (заглушка - нужна таблица games)
    games_won = min(3, games_played)  # Временная заглушка
    
    # 4. Количество сделанных фото
    result = await db.execute(
        select(func.count()).where(models.Photo.user_id == user_id)
    )
    photos_taken = result.scalar() or 0
    
    # Формируем ответ
    stats = {
        "total_score": 1250,  # Заглушка
        "games_played": games_played,
        "games_won": games_won,
        "win_rate": int((games_won / games_played * 100)) if games_played > 0 else 0,
        "photos_taken": photos_taken,
        "lobbies_created": lobbies_created,
        "current_streak": 2,
        "max_streak": 5
    }
    
    return {
        "status": "success",
        "data": {
            "user_id": user_id,
            "stats": stats
        }
    }

@router.get("/{user_id}/games")
async def get_user_games(user_id: int, db: AsyncSession = Depends(get_db)):
    # Проверяем существование пользователя
    result = await db.execute(select(models.User).where(models.User.id == user_id))
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Заглушка - список игр
    # В реальности нужно будет делать запрос к таблице игр
    games = [
        {
            "id": 1,
            "location": "Москва, Красная площадь",
            "date": "2023-10-15",
            "players": 4,
            "mode": "quick",
            "score": 450,
            "position": 1,
            "duration": "25 мин"
        },
        {
            "id": 2,
            "location": "Москва, Парк Горького",
            "date": "2023-10-10",
            "players": 6,
            "mode": "family",
            "score": 320,
            "position": 3,
            "duration": "40 мин"
        }
    ]
    
    return {
        "status": "success",
        "data": {
            "user_id": user_id,
            "games": games
        }
    }