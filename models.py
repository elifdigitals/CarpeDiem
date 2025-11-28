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
    host_id = Column(String, nullable=False)
    mode = Column(String, default="default")
    status = Column(String, default="waiting")

class LobbyPlayer(Base):
    __tablename__ = "lobby_players"
    lobby_id = Column(UUID(as_uuid=True), ForeignKey("lobbies.id"), primary_key=True)
    user_id = Column(String, primary_key=True)

class Photo(Base):
    __tablename__ = "photos"
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(String, nullable=False)
    lobby_id = Column(UUID(as_uuid=True), ForeignKey("lobbies.id"), nullable=False)
    file_path = Column(String, nullable=False)
    status = Column(String, default="unknown")
    recognized_person = Column(String, nullable=True)
    uploaded_at = Column(String, default=datetime.utcnow)
    encoding_path = Column(String)

    # user = relationship("User", back_populates="photos")
    # lobby = relationship("Lobby", back_populates="photos")
