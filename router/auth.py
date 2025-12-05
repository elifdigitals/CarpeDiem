# auth.py
from fastapi import APIRouter, Depends, HTTPException, Response, status, Header
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from passlib.context import CryptContext
from jose import jwt, JWTError
from datetime import datetime, timedelta
from pydantic import BaseModel
from typing import Optional

from database import get_db
from models import User

router = APIRouter(prefix="/auth", tags=["auth"])

SECRET_KEY = "secret_key"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 600

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class UserCreate(BaseModel):
    username: str
    email: str
    password: str


class UserLogin(BaseModel):
    email: str
    password: str


def create_access_token(data: dict, expires_delta: timedelta | None = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def verify_password(plain, hashed):
    return pwd_context.verify(plain, hashed)


def get_password_hash(password):
    return pwd_context.hash(password)


@router.get("/current_user")
async def get_current_user(
        authorization: Optional[str] = Header(default=None),
        db: AsyncSession = Depends(get_db)
):
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
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
    except (ValueError, JWTError):
        raise HTTPException(status_code=401, detail="Invalid token")

    result = await db.execute(select(User).where(User.username == username))
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(status_code=401, detail="User not found")

    return {
        "id": user.id,
        "username": user.username,
        "email": user.email
    }


@router.post("/register")
async def register(user: UserCreate, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == user.email))
    existing_user = result.scalar_one_or_none()
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")

    result = await db.execute(select(User).where(User.username == user.username))
    existing_username = result.scalar_one_or_none()
    if existing_username:
        raise HTTPException(status_code=400, detail="Username already taken")

    hashed_pw = get_password_hash(user.password)
    db_user = User(username=user.username, email=user.email, hashed_pw=hashed_pw)
    db.add(db_user)
    await db.commit()
    await db.refresh(db_user)

    access_token = create_access_token(
        data={"sub": user.username},
        expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    )

    return {
        "msg": "User registered",
        "user_id": db_user.id,
        "username": db_user.username,
        "email": db_user.email,
        "access_token": access_token,
        "token_type": "bearer"
    }


@router.post("/login")
async def login(data: UserLogin, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == data.email))
    user = result.scalar_one_or_none()
    if not user or not verify_password(data.password, user.hashed_pw):
        raise HTTPException(status_code=400, detail="Incorrect email or password")

    access_token = create_access_token(
        data={"sub": user.username},
        expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    )

    return {
        "msg": "Logged in",
        "access_token": access_token,
        "token_type": "bearer",
        "user_id": user.id,
        "username": user.username,
        "email": user.email
    }

@router.post("/logout")
async def logout(response: Response):
    response.delete_cookie("access_token")
    return {"msg": "Logged out"}