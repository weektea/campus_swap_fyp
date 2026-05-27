---
description: Start the Full Stack Application
---

# Start the Campus Swap Platform

This workflow helps you start all components of the system.

## 1. Start Support Services (Backend & ML)

### Backend (Node.js)
Open a terminal and run:
```powershell
cd backend
npm install
npm run dev
```

### ML Service (Python)
Open a separate terminal and run:
```powershell
cd ml_service
..\.venv\Scripts\activate
uvicorn main:app --host 0.0.0.0 --port 5000 --reload
```

## 2. Start the Frontend (Flutter)

Open a terminal in the root directory and run:
```powershell
flutter run
```
