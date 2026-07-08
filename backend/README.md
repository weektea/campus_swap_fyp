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

### Option A: Docker (Recommended)
Run the following command in the `backend` folder to start the database:
```bash
docker-compose up -d
```

### Option B: Manual Setup
1. Install PostgreSQL.
2. Create a database named `campus_swap`.
3. Create a user `postgres` with password `postgres` (or update `.env`).

# DB connect
1. open docker
2. cd backend
   docker-compose up -d
3. cd backend
   npm run dev

# ML - another terminal local(2)
1. cd ml xxx
python main.py xxx

1. 进入新的 ML 文件夹
cd ml_service
2. 激活 Python 虚拟环境 (这是最重要的一步，确保环境正确)
..\.venv\Scripts\activate
3. 启动 FastAPI 深度学习微服务 (我们换到了 5000 端口)
uvicorn main:app --host 0.0.0.0 --port 5000 --reload

if in used:
Stop-Process -Id (Get-NetTCPConnection -LocalPort 5000).OwningProcess -Force -ErrorAction SilentlyContinue

# Admin & Moderator - Panel
1. cd admin_panel
2. npm install (if not yet install)
3. npm run dev

# Email: 
admin@campus-swap.edu.my
ADMIN-001
# Password: 
password123
Admin@123

# Test Register
24PMR12345
TestPassword@123

Test Student6     
24PMR01666         
016-1122666       
stu6@tarc.edu.my
Test1234@

# Test environment setup
flutter run --dart-define=API_HOST=192.168.100.23

flutter build apk --dart-define=API_HOST=192.168.100.23


# fake data
node seed_ml_data.js
