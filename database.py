# database.py - исправленная версия без циклического импорта
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker, declarative_base

DATABASE_URL = "sqlite+aiosqlite:///./carpediem.db"

# Создаем асинхронный движок
engine = create_async_engine(DATABASE_URL, echo=True, future=True)

# Создаем фабрику сессий
AsyncSessionLocal = sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False
)

# Базовый класс для моделей
Base = declarative_base()

# Dependency для получения сессии БД
async def get_db():
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()