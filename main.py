from fastapi import FastAPI
from router import lobby, auth, photo
from database import engine, Base

app = FastAPI()
app.include_router(lobby.router)
app.include_router(auth.router)
app.include_router(photo.router)


@app.on_event("startup")
async def startup():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
