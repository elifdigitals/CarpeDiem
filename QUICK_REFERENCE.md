# 🚀 CarpeDiem - Quick Reference Guide

## Start Backend (Copy & Paste)

```powershell
Push-Location "D:\Desktop\flutter\backend\CarpeDiem"; python -m uvicorn main:app --host 0.0.0.0 --port 8000
```

**Status**: Server will show `Uvicorn running on http://0.0.0.0:8000`

---

## Test Backend

### Option 1: Interactive API Docs
- URL: http://localhost:8000/docs
- Try any endpoint directly in the browser

### Option 2: Health Check
```powershell
Invoke-WebRequest -Uri "http://localhost:8000/health"
```

### Option 3: Test Registration
```powershell
$body = @{
    username = "testuser"
    email = "test@test.com"
    password = "password123"
} | ConvertTo-Json

Invoke-WebRequest -Uri "http://localhost:8000/auth/register" `
    -Method POST `
    -Headers @{"Content-Type"="application/json"} `
    -Body $body
```

---

## API Endpoints Summary

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /health | Server health check |
| POST | /auth/register | Create new account |
| POST | /auth/login | User login |
| GET | /auth/current_user | Get current user info |
| GET | /lobbies/ | List all lobbies |
| POST | /lobbies/create | Create new lobby |
| GET | /lobbies/{id} | Get lobby details |
| POST | /lobbies/{id}/join | Join a lobby |
| POST | /profile/create | Create user profile |
| GET | /profile/{user_id} | Get profile info |
| PUT | /profile/update/{user_id} | Update profile |
| GET | /user/{user_id}/stats | Get user statistics |
| GET | /user/{user_id}/games | Get user games |

---

## Start Flutter App (After Installation)

```bash
cd D:\Desktop\flutter\frontend\Carpediem
flutter pub get
flutter run -d chrome
```

---

## Database Reset

```bash
cd D:\Desktop\flutter\backend\CarpeDiem
rm carpediem.db
# Restart backend server
```

---

## Logs & Debugging

### View Backend Logs
The logs are displayed in the terminal where the server is running. Look for:
- `INFO:     Application startup complete` - Server is ready
- `200 OK` - Successful requests
- `400 Bad Request` - Client error
- `500 Internal Server Error` - Server error

### Common Issues

**Port 8000 already in use**
```powershell
Get-NetTCPConnection -LocalPort 8000 | Stop-Process -Force
```

**Module not found error**
```powershell
# Make sure you're in the correct directory
Push-Location "D:\Desktop\flutter\backend\CarpeDiem"
Get-Location  # Verify you're in the right place
```

**Database lock**
```bash
# Check if db file is locked
lsof carpediem.db
# Or restart the server
```

---

## Flutter Development

### Check Flutter Installation
```bash
flutter doctor -v
flutter --version
```

### Get Dependencies
```bash
flutter pub get
flutter pub upgrade
```

### Run on Different Devices
```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d chrome
flutter run -d emulator-5554
flutter run -d simulator
```

### Build for Production
```bash
flutter build web
flutter build apk
flutter build ios
```

---

## Project Files

### Backend
- Main app: `D:\Desktop\flutter\backend\CarpeDiem\main.py`
- Database: `D:\Desktop\flutter\backend\CarpeDiem\carpediem.db`
- Dependencies: `D:\Desktop\flutter\backend\CarpeDiem\requirements.txt`
- API config: `D:\Desktop\flutter\backend\CarpeDiem\router\auth.py`

### Frontend
- Main app: `D:\Desktop\flutter\frontend\Carpediem\lib\main.dart`
- API client: `D:\Desktop\flutter\frontend\Carpediem\lib\services\api_service.dart`
- Dependencies: `D:\Desktop\flutter\frontend\Carpediem\pubspec.yaml`

---

## Environment Variables

Create `.env` in backend directory:
```
DATABASE_URL=sqlite+aiosqlite:///./carpediem.db
SECRET_KEY=your_secret_key
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
```

Load in `main.py`:
```python
from dotenv import load_dotenv
import os
load_dotenv()
```

---

## Default Test Credentials

After running registration:
```
Email: test@test.com
Username: testuser
Password: password123
```

---

## Performance Tuning

### Backend
- Increase workers: `--workers 4`
- Enable reload: `--reload`
- Change host: `--host 0.0.0.0` (all interfaces)
- Change port: `--port 8001` (different port)

### Frontend
- Use release mode: `flutter run --release`
- Profile performance: `flutter run --profile`

---

## Useful Commands

```bash
# Python
python --version
pip list
pip install -r requirements.txt

# Flutter
flutter pub get
flutter pub outdated
flutter clean

# SQLite
sqlite3 carpediem.db
.tables
.schema users
SELECT * FROM users;
.quit

# PowerShell
Get-Process python
Stop-Process -Name python -Force
netstat -ano | findstr :8000
```

---

## Links

- API Documentation: http://localhost:8000/docs
- Swagger UI: http://localhost:8000/swagger
- ReDoc: http://localhost:8000/redoc
- Backend: http://0.0.0.0:8000
- Frontend: http://localhost:55107 (Flutter web default)

---

## Troubleshooting Flowchart

```
Issue: Backend won't start?
├─ Check directory: pwd
├─ Check Python: python --version
├─ Check port: netstat -ano | findstr :8000
└─ Try: Push-Location first

Issue: API returns 404?
├─ Check endpoint name
├─ Check method (GET/POST/PUT)
├─ Check docs: /docs
└─ Check logs in terminal

Issue: Flutter won't run?
├─ Check Flutter: flutter doctor -v
├─ Check dependencies: flutter pub get
├─ Check device: flutter devices
└─ Try: flutter clean

Issue: Database error?
├─ Check file: ls carpediem.db
├─ Check tables: sqlite3 carpediem.db ".tables"
├─ Reset: rm carpediem.db
└─ Restart server
```

---

## Success Indicators

✅ Backend
- Server shows: `Uvicorn running on http://0.0.0.0:8000`
- Health check returns: `{"status": "healthy"}`
- Docs page loads: http://localhost:8000/docs

✅ Frontend
- App launches in browser
- Can navigate screens
- Can register new account
- Can login successfully

✅ Integration
- Frontend can register user on backend
- Frontend can login successfully
- Frontend displays user data
- All screens render correctly

---

## Support Resources

- FastAPI: https://fastapi.tiangolo.com
- Flutter: https://flutter.dev/docs
- SQLAlchemy: https://docs.sqlalchemy.org
- Python: https://python.org/docs

---

**Last Updated**: 2025-12-04
**Status**: ✅ Ready to Deploy
