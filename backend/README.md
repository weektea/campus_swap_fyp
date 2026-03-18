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

# Test Register
Test Student2
24PMR12346
016-1234567
student1@student.tarc.edu.my
Test1234@
