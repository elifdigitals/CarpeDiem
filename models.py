from sqlalchemy import Column, Integer, String, ForeignKey, Date, DateTime, Float
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
    photos = relationship("Photo", back_populates="user")


class UserProfile(Base):
    __tablename__ = "profiles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True)
    full_name = Column(String, nullable=False)
    birth_date = Column(Date, nullable=False)
    location = Column(String, nullable=False)
    phone = Column(String, nullable=False)
    photo_path = Column(String, nullable=False)
    user = relationship("User", backref="profile")

class Lobby(Base):
    __tablename__ = "lobbies"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    lobby_name = Column(String, nullable=False)
    host_id = Column(Integer, nullable=False)
    mode = Column(String, default="default")
    time_limit = Column(Integer)
    status = Column(String, default="waiting")

    # photos = relationship("Photo", back_populates="lobby")

class LobbyPlayer(Base):
    __tablename__ = "lobby_players"

    lat = Column(Float)
    lon = Column(Float)
    lobby_id = Column(UUID(as_uuid=True), ForeignKey("lobbies.id"), primary_key=True)
    user_id = Column(Integer, primary_key=True)


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
    user = relationship("User", back_populates="photos")


class Message(Base):
    __tablename__ = "messages"

    id = Column(Integer, primary_key=True)
    lobby_id = Column(Integer)
    user_id = Column(Integer)
    content = Column(String)
    timestamp = Column(DateTime, default=datetime.utcnow)

