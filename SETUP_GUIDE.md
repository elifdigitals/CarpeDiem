# CarpeDiem - Setup & Running Guide

## Project Overview
CarpeDiem is a full-stack Flutter + FastAPI application for face recognition gaming. It consists of:
- **Frontend**: Flutter mobile/web app (D:\Desktop\flutter\frontend\Carpediem)
- **Backend**: FastAPI Python server (D:\Desktop\flutter\backend\CarpeDiem)

---

## Prerequisites

### Backend Requirements
- Python 3.11+
- pip (Python package manager)
- Required packages (see requirements.txt)

### Frontend Requirements
- Flutter SDK 3.9.0+
- Dart SDK (comes with Flutter)
- Android SDK / Xcode (for mobile development)
- Chrome (for web development)

---

## Backend Setup & Running

### 1. Navigate to Backend Directory
```powershell
Push-Location "D:\Desktop\flutter\backend\CarpeDiem"
```

### 2. Install Python Dependencies (First Time Only)
```powershell
pip install -r requirements.txt
```

### 3. Start Backend Server
```powershell
python -m uvicorn main:app --host 0.0.0.0 --port 8000
```

The server will start at `http://0.0.0.0:8000`

### Backend API Endpoints

**Health Check**
```
GET /health
```

**Authentication**
```
POST /auth/register
POST /auth/login
GET /auth/current_user
```

**Lobbies**
```
GET /lobbies/
POST /lobbies/create
GET /lobbies/{lobby_id}
POST /lobbies/{lobby_id}/join
```

**Profile**
```
POST /profile/create
GET /profile/{user_id}
PUT /profile/update/{user_id}
```

**User Stats**
```
GET /user/{user_id}/stats
GET /user/{user_id}/games
```

**API Documentation**: http://localhost:8000/docs

---

## Frontend Setup & Running

### 1. Install Flutter (if not already installed)
- Download from: https://flutter.dev/docs/get-started/install
- Add Flutter to PATH
- Run `flutter doctor` to verify installation

### 2. Navigate to Frontend Directory
```powershell
cd D:\Desktop\flutter\frontend\Carpediem
```

### 3. Get Dependencies (First Time Only)
```bash
flutter pub get
```

### 4. Run Flutter App

**For Web (Recommended for Testing)**
```bash
flutter run -d chrome
```

**For Android Emulator**
```bash
flutter run -d emulator-5554
```

**For iOS Simulator (macOS only)**
```bash
flutter run -d simulator
```

---

## Testing the Full Flow

### 1. Start Backend Server
```powershell
Push-Location "D:\Desktop\flutter\backend\CarpeDiem"
python -m uvicorn main:app --host 0.0.0.0 --port 8000
```

### 2. Start Flutter App
```bash
cd D:\Desktop\flutter\frontend\Carpediem
flutter run -d chrome
```

### 3. Test User Flow
1. **Register**: Create new account with email, username, password
2. **Login**: Log in with created credentials
3. **Create Profile**: Add personal profile information
4. **Create Lobby**: Start a new game lobby
5. **View Stats**: Check user statistics and game history

---

## Troubleshooting

### Backend Issues

**"Error loading ASGI app. Could not import module 'main'"**
- Solution: Make sure you're in the correct directory (D:\Desktop\flutter\backend\CarpeDiem)
- Use: `Push-Location "D:\Desktop\flutter\backend\CarpeDiem"` before running uvicorn

**Database connection errors**
- Check if carpediem.db exists in the backend directory
- The database is created automatically on first run
- Delete carpediem.db and restart if you need a fresh database

**Port 8000 already in use**
- Find the process: `netstat -ano | findstr :8000`
- Kill the process: `taskkill /PID <PID> /F`
- Or use a different port: `python -m uvicorn main:app --port 8001`

### Frontend Issues

**Flutter not found**
- Run `flutter doctor -v` to check installation
- Add Flutter SDK to PATH environment variable
- Download Flutter from https://flutter.dev

**Dependencies not found**
- Run: `flutter pub get`
- Delete pubspec.lock and run again if issues persist

**App won't connect to backend**
- Check if backend is running: Visit http://localhost:8000/health
- Update API endpoint in lib/services/api_service.dart if needed
- Default: `baseUrl = 'http://localhost:8000'`
- For physical device: Use your computer's IP address instead of localhost

---

## Database Schema

The application uses SQLite with the following tables:

- **users**: User account information
- **profiles**: Extended user profile data
- **lobbies**: Game lobby data
- **lobby_players**: Players in each lobby
- **photos**: Uploaded face images

---

## API Response Format

All API responses follow this format:

**Success**
```json
{
  "status": "success",
  "data": { ... }
}
```

**Error**
```json
{
  "status": "error",
  "message": "Error description"
}
```

**Authentication**
```json
{
  "user_id": 1,
  "username": "username",
  "email": "email@test.com",
  "access_token": "jwt_token_here"
}
```

---

## Environment Variables (Optional)

Create a `.env` file in the backend directory:

```
DATABASE_URL=sqlite+aiosqlite:///./carpediem.db
SECRET_KEY=your_secret_key_here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
```

---

## Development Notes

### Backend Architecture
- **Framework**: FastAPI (async Python web framework)
- **Database**: SQLAlchemy ORM with SQLite
- **Authentication**: JWT tokens with bcrypt password hashing
- **CORS**: Enabled for all origins for development

### Frontend Architecture
- **Framework**: Flutter
- **State Management**: StatefulWidget
- **HTTP Client**: http package
- **Storage**: flutter_secure_storage (for token persistence)

---

## Next Steps

1. ✅ Backend running on http://0.0.0.0:8000
2. ⏳ Install Flutter SDK
3. ⏳ Run Flutter app with `flutter run -d chrome`
4. ⏳ Test registration and login flow
5. ⏳ Integrate face recognition features

---

## Support & Resources

- Flutter Documentation: https://flutter.dev/docs
- FastAPI Documentation: https://fastapi.tiangolo.com
- SQLAlchemy Documentation: https://docs.sqlalchemy.org
- JWT Authentication: https://pyjwt.readthedocs.io
