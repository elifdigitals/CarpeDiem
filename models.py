# models.py

from sqlalchemy import Column, Integer, String, ForeignKey, Date, Boolean, Table
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

    # Связи
    lobbies_hosted = relationship("Lobby", back_populates="host_user", foreign_keys="Lobby.host_id")
    lobby_players = relationship("LobbyPlayer", back_populates="user")
    photos = relationship("Photo", back_populates="user")

    def to_dict(self):
        return {
            "id": self.id,
            "username": self.username,
            "email": self.email,
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
    location_lat = Column(String, nullable=True)
    location_lon = Column(String, nullable=True)

class Lobby(Base):
    __tablename__ = "lobbies"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    host_id = Column(Integer, ForeignKey("users.id"), nullable=False)  # ✅ ИСПРАВЛЕНО
    mode = Column(String, default="default")
    status = Column(String, default="waiting")
    name = Column(String)
    time_limit = Column(Integer)
    code = Column(String(6), unique=True, index=True, nullable=True)  # 6-значный код

    # Связи
    host_user = relationship("User", foreign_keys=[host_id], back_populates="lobbies_hosted")  # ✅ ИСПРАВЛЕНО
    players = relationship("LobbyPlayer", back_populates="lobby", cascade="all, delete-orphan")
    photos = relationship("Photo", back_populates="lobby")

class LobbyPlayer(Base):
    __tablename__ = "lobby_players"
    lobby_id = Column(UUID(as_uuid=True), ForeignKey("lobbies.id", ondelete="CASCADE"), primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    is_ready = Column(Boolean, default=False)

    # Связи
    lobby = relationship("Lobby", back_populates="players")
    user = relationship("User", back_populates="lobby_players")

class Photo(Base):
    __tablename__ = "photos"
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    lobby_id = Column(UUID(as_uuid=True), ForeignKey("lobbies.id", ondelete="CASCADE"), nullable=False)
    file_path = Column(String, nullable=False)
    status = Column(String, default="unknown")
    recognized_person = Column(String, nullable=True)
    uploaded_at = Column(String, default=datetime.utcnow)
    encoding_path = Column(String)

    # Связи
    user = relationship("User", back_populates="photos")
    lobby = relationship("Lobby", back_populates="photos")