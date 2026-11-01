# DACN Clinic

A clinic appointment, examination, insurance billing, and payment app. The repository contains a NestJS API, a Flutter client, and a separate FastAPI image and symptom service.

## Requirements

- Node.js 24 and npm
- PostgreSQL 16 or later
- Flutter 3.47 or later
- Python 3.10 or later
- The original Swin V2 checkpoint for image inference and a Gemini API key for symptom analysis

## Start locally

1. Create a PostgreSQL database for local development.
2. In `backend/`, copy `.env.example` to `.env`, set the database connection, `JWT_SECRET`, and bootstrap admin credentials. Bootstrap credentials must be at least 12 characters. The first API startup creates the admin only when both bootstrap values are configured.
3. Install and start the API from `backend/` with `npm ci` and `npm run start:dev`. TypeORM runs checked-in migrations at startup. Database synchronization is disabled.
4. In `ai_service/`, create a virtual environment, install `requirements.txt`, and copy `.env.example` to `.env`. Set `MODEL_PTH` to the supplied Swin V2 checkpoint and configure `GEMINI_API_KEY` for symptom chat. Start the service with `uvicorn ai_service.app:app --host 0.0.0.0 --port 8000` from the repository root.
5. In the repository root, run `flutter pub get` and `flutter run`. Use `--dart-define=API_BASE=http://<host>:3000` when the API is not on the default client address.

The API serves Swagger UI at `http://localhost:3000/api`, health at `/`, and image uploads under `/uploads/`. Configure SePay and VietQR receiving details using the backend environment variables before using real payments. The webhook can be exercised with a simulated request during development.

## Checks

```powershell
cd backend
npm ci
npm run build
npm test
cd ..
flutter analyze
flutter test
python -m pytest ai_service/test_service.py -q
```

The AI route tests run without model weights or a Gemini key. Those files are local runtime assets and must not be committed. Keep all credentials in ignored `.env` files.
