from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

# Импортируем синхронную версию для SQLite
from database import engine, Base, SessionLocal
from router import auth, lobbies, profile
from router.user_stats import router as user_stats_router

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Для SQLite используем синхронное создание таблиц
    print("🚀 Starting server...")
    try:
        # Создаем таблицы синхронно
        Base.metadata.create_all(bind=engine)
        print("✅ Database tables created")
        
        # Простой тест подключения к БД
        with SessionLocal() as session:
            result = session.execute("SELECT 1")
            print(f"✅ Database connection test: {result.fetchone()}")
    except Exception as e:
        print(f"⚠️ Database initialization error: {e}")
    
    yield
    
    print("🛑 Server stopping...")

app = FastAPI(lifespan=lifespan, title="CarpeDiem API", version="1.0.0")

# CORS настройки
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:8000",
        "http://localhost:8080", 
        "http://localhost:4200",
        "http://localhost",
        "http://127.0.0.1:8000",
        "http://127.0.0.1:8080",
        "http://127.0.0.1:4200",
        "http://127.0.0.1",
        "*"  # Для разработки
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Подключаем роутеры
app.include_router(auth.router, tags=["authentication"])
app.include_router(lobbies.router, tags=["lobbies"])
app.include_router(profile.router, tags=["profile"])
app.include_router(user_stats_router, prefix="/stats", tags=["stats"])

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
        with SessionLocal() as session:
            result = session.execute("SELECT 1 as test")
            return {"database": "connected", "test": result.fetchone()["test"]}
    except Exception as e:
        return {"database": "error", "message": str(e)}