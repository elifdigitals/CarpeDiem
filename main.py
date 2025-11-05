from fastapi import FastAPI
from database import engine, Base
from router.auth import router as auth_router
from router.lobby import router as lobby_router
# from router.photo import router as photo_router
from starlette.middleware.cors import CORSMiddleware

import face_recognition


app = FastAPI()
app.include_router(auth_router)
app.include_router(profile_router)
app.include_router(lobby_router)
# app.include_router(photo_router)

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