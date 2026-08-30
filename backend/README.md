# Backend Service

This directory acts as the root for the Node.js + PostgreSQL backend application.

## Setup

1.  Initialize Node project: `npm init -y`
2.  Install dependencies: `npm install express pg sequelize ...`
3.  Structure:
    *   `src/`: Source code
    *   `src/controllers`: Request handlers
    *   `src/models`: Database models
    *   `src/routes`: API endpoints

## Database Setup

This project uses PostgreSQL.

### Option A: Docker 
Run the following command in the `backend` folder to start the database:
```bash
docker-compose up -d
```

# DB connect
1. open docker
2. cd backend
   docker-compose up -d
3. cd backend
   npm run dev

# ML - another terminal local(2)
1. cd ml xxx
python main.py xxx

1. Enter the ML service directory:
cd ml_service
2. Activate Python virtual environment:
..\.venv\Scripts\activate
3. Start the FastAPI Deep Learning microservice (runs on port 5000):
uvicorn main:app --host 0.0.0.0 --port 5000 --reload

if in used:
Stop-Process -Id (Get-NetTCPConnection -LocalPort 5000).OwningProcess -Force -ErrorAction SilentlyContinue



