from sqlalchemy import Column, Integer, String, ForeignKey, Date
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid
from database import Base
from datetime import datetime

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_pw = Column(String)
    
    # Найдите класс User в файле models.py и добавьте этот метод:
    def to_dict(self):
        return {
            "id": self.id,
            "username": self.username,
            "email": self.email,
            # Добавьте другие поля по необходимости
        }

class UserProfile(Base):
    __tablename__ = "profiles"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True)
    full_name = Column(String, nullable=False)
    birth_date = Column(Date, nullable=False)
    location = Column(String, nullable=False)
    phone = Column(String, nullable=False)
    photo_path = Column(String, nullable=False)

class Lobby(Base):
    __tablename__ = "lobbies"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    host_id = Column(Integer, nullable=False)  # ДОЛЖЕН БЫТЬ Integer
    mode = Column(String, default="default")
    status = Column(String, default="waiting")
    name = Column(String)
    time_limit = Column(Integer)

class LobbyPlayer(Base):
    __tablename__ = "lobby_players"
    lobby_id = Column(UUID(as_uuid=True), ForeignKey("lobbies.id"), primary_key=True)
    user_id = Column(Integer, primary_key=True)  # ДОЛЖЕН БЫТЬ Integer

class Photo(Base):
    __tablename__ = "photos"
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    lobby_id = Column(UUID(as_uuid=True), ForeignKey("lobbies.id"), nullable=False)
    file_path = Column(String, nullable=False)
    status = Column(String, default="unknown")
    recognized_person = Column(String, nullable=True)
    uploaded_at = Column(String, default=datetime.utcnow)
    encoding_path = Column(String)