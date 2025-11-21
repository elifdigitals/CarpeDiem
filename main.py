from fastapi import FastAPI
from database import engine, Base
from router import live, game
from router.auth import router as auth_router
from router.lobby import router as lobby_router
from router.photo import router as photo_router
from router.profile import  router as profile_router
from starlette.middleware.cors import CORSMiddleware
from exceptions import (
    http_exception_handler,
    validation_exception_handler,
    generic_exception_handler
)
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
import face_recognition


app = FastAPI()
app.include_router(auth_router)
app.include_router(profile_router)
app.include_router(lobby_router)
app.include_router(photo_router)
app.include_router(live)
app.include_router(game)

app.add_exception_handler(StarletteHTTPException, http_exception_handler)
app.add_exception_handler(RequestValidationError, validation_exception_handler)
app.add_exception_handler(Exception, generic_exception_handler)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def startup():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)