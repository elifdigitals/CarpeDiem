from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends
from typing import Dict, List

router = APIRouter(prefix="/ws")

class LobbyConnectionManager:
    def __init__(self):
        self.lobbies: Dict[int, List[WebSocket]] = {}

    async def connect(self, lobby_id: int, ws: WebSocket):
        await ws.accept()
        if lobby_id not in self.lobbies:
            self.lobbies[lobby_id] = []
        self.lobbies[lobby_id].append(ws)

    def disconnect(self, lobby_id: int, ws: WebSocket):
        self.lobbies[lobby_id].remove(ws)
        if not self.lobbies[lobby_id]:
            del self.lobbies[lobby_id]

    async def broadcast(self, lobby_id: int, message: dict):
        for ws in self.lobbies.get(lobby_id, []):
            await ws.send_json(message)


manager = LobbyConnectionManager()


@router.websocket("/lobby/{lobby_id}")
async def lobby_ws(websocket: WebSocket, lobby_id: int):
    await manager.connect(lobby_id, websocket)

    try:
        while True:
            data = await websocket.receive_json()

            await manager.broadcast(lobby_id, data)

    except WebSocketDisconnect:
        manager.disconnect(lobby_id, websocket)
        await manager.broadcast(lobby_id, {"type": "player_left"})