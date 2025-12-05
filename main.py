# main.py - асинхронная версия
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from sqlalchemy import text

# Импортируем асинхронные компоненты
from database import engine, Base, AsyncSessionLocal
from router import auth, lobbies, profile
from router.user_stats import router as user_stats_router

@asynccontextmanager
async def lifespan(app: FastAPI):
    print("🚀 Starting CarpeDiem Backend Server...")
    
    # Асинхронное создание таблиц
    try:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        print("✅ Database tables created")
        
        # Асинхронный тест БД
        async with AsyncSessionLocal() as session:
            result = await session.execute(text("SELECT 1"))
            print(f"✅ Database connection test: {result.fetchone()}")
    except Exception as e:
        print(f"⚠️ Database initialization error: {e}")
    
    yield
    
    print("🛑 Server stopping...")
    await engine.dispose()

app = FastAPI(lifespan=lifespan, title="CarpeDiem API", version="1.0.0")

# CORS настройки - ДОБАВЛЕНО порты для Flutter dev server
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:8000",
        "http://localhost:8080",
        "http://localhost:4200",
        "http://localhost:3000",        # Flutter Web default
        "http://localhost:53238",       # Flutter Web dev server
        "http://localhost",
        "http://127.0.0.1:8000",
        "http://127.0.0.1:8080",
        "http://127.0.0.1:4200",
        "http://127.0.0.1:3000",       # Flutter Web alternative
        "http://127.0.0.1:53238",      # Flutter Web dev server alternative
        "http://127.0.0.1",
        "http://10.0.2.2:8000",        # Android emulator
        "*"  # На всякий случай для отладки
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Подключаем роутеры
app.include_router(auth.router)
app.include_router(lobbies.router)
app.include_router(profile.router)
app.include_router(user_stats_router)

@app.get("/")
async def root():
    return {
        "message": "CarpeDiem Backend API",
        "status": "success",
        "version": "1.0.0",
        "docs": "/docs",
        "endpoints": {
            "auth": "/auth/register, /auth/login, /auth/current_user",
            "lobbies": "/lobbies/, /lobbies/create",
            "profile": "/profile/{id}, /profile/{id}/update",
            "stats": "/stats/{user_id}"
        }
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "carpe_diem_backend"}

@app.get("/test/db")
async def test_database():
    try:
        async with AsyncSessionLocal() as session:
            result = await session.execute(text("SELECT 1 as test"))
            row = result.fetchone()
            return {"database": "connected", "test": row.test if row else None}
    except Exception as e:
        return {"database": "error", "message": str(e)}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)