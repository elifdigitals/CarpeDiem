from sqlalchemy import Column, String, ForeignKey, Integer
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid
from database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_pw = Column(String)

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
