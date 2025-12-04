# app.py - простой рабочий вариант
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def home():
    return {"message": "CarpeDiem API работает!", "status": "success"}

@app.get("/health")
def health():
    return {"status": "healthy"}

@app.get("/test")
def test():
    return {"test": "ok", "database": "sqlite"}