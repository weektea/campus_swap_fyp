---
description: Start the Full Stack Application
---

# Start the Campus Swap Platform

This workflow helps you start all components of the system.

## Start Support Services (Backend & ML)

### Backend (Node.js)
Open a terminal and run:
```powershell
cd backend
npm install

docker-compose up -d
npm run dev
```

### ML Service (Python)
Open a separate terminal and run:
```powershell
cd ml_service
..\.venv\Scripts\activate
uvicorn main:app --host 0.0.0.0 --port 5000 --reload
```


# Admin & Moderator - Panel
1. cd admin_panel
2. npm install (if not yet install)
3. npm run dev

# Email:
admin@campus.edu.my
# Password:
Admin@123
