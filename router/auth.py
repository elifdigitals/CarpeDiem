from fastapi import APIRouter, Depends, HTTPException, Cookie, Header, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from jose import jwt, JWTError
from datetime import datetime, timedelta
from pydantic import BaseModel
import bcrypt
from database import get_db
import models

router = APIRouter(prefix="/auth", tags=["authentication"])

SECRET_KEY = "secret"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60

# Модели для запросов
class UserCreate(BaseModel):
    username: str
    email: str
    password: str

class UserLogin(BaseModel):
    email: str
    password: str

# Вспомогательные функции
def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))

def get_password_hash(password: str) -> str:
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

# Улучшенная функция get_current_user
async def get_current_user(
    request: Request,
    db: AsyncSession = Depends(get_db)
):
    # Логируем входящие заголовки и куки для отладки
    try:
        print('>>> Incoming request headers:', dict(request.headers))
    except Exception:
        print('>>> Incoming request headers: <could not convert>')
    try:
        print('>>> Incoming cookies:', request.cookies)
    except Exception:
        print('>>> Incoming cookies: <could not convert>')
    # Пробуем получить токен из заголовка Authorization
    auth_header = request.headers.get("Authorization")
    token = None
    
    if auth_header and auth_header.startswith("Bearer "):
        token = auth_header.split(" ", 1)[1].strip()
    
    # Если нет в заголовке, пробуем из кук
    if not token:
        token = request.cookies.get("access_token")

    print('>>> token extracted:', token)
    
    if not token:
        raise HTTPException(status_code=401, detail="Not authenticated")

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = payload.get("user_id")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid token")
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid or expired token")

    user = await db.get(models.User, user_id)
    if not user:
        raise HTTPException(status_code=401, detail="User not found")

    return user

# Эндпоинты
@router.post("/register")
async def register(user: UserCreate, db: AsyncSession = Depends(get_db)):
    # Проверяем, существует ли пользователь с таким email
    result = await db.execute(select(models.User).where(models.User.email == user.email))
    existing_user = result.scalar_one_or_none()
    
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    # Создаем нового пользователя
    hashed_pw = get_password_hash(user.password)
    db_user = models.User(
        username=user.username,
        email=user.email,
        hashed_pw=hashed_pw
    )
    
    db.add(db_user)
    await db.commit()
    await db.refresh(db_user)
    
    # Создаем токен
    token = create_access_token({"user_id": db_user.id})
    
    return {
        "user_id": db_user.id,
        "username": db_user.username,
        "email": db_user.email,
        "access_token": token
    }

@router.post("/login")
async def login(user: UserLogin, db: AsyncSession = Depends(get_db)):
    # Ищем пользователя
    result = await db.execute(select(models.User).where(models.User.email == user.email))
    db_user = result.scalar_one_or_none()
    
    if not db_user or not verify_password(user.password, db_user.hashed_pw):
        raise HTTPException(status_code=400, detail="Invalid credentials")
    
    # Создаем токен
    token = create_access_token({"user_id": db_user.id})
    
    return {
        "user_id": db_user.id,
        "username": db_user.username,
        "email": db_user.email,
        "access_token": token
    }

@router.get("/current_user")
async def read_current_user(current_user: models.User = Depends(get_current_user)):
    return {
        "status": "success",
        "data": {
            "id": current_user.id,
            "username": current_user.username,
            "email": current_user.email
        }
    }