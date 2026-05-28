# Smart Campus Second-Hand Trading Platform

A cross-platform mobile & web application for sustainable campus trading, built with Flutter, Node.js, and Python ML.

## Project Structure

This repository contains the complete source code for the platform, organized into the following directories:

*   **`lib/`**: Flutter Frontend Application.
    *   **`core/`**: Shared resources (Theme, Constants, Utilities).
    *   **`features/`**: Functional modules (Auth, Product, Home, etc.).
*   **`backend/`**: Node.js + PostgreSQL Backend Service.
*   **`ml_service/`**: Python FastAPI Machine Learning Service (PyTorch CNN, True MLOps).
*   **`admin_panel/`**: React Web Dashboard for System Admins & MLOps Management.

## Getting Started

### Prerequisites

*   **Flutter SDK**: [Install Flutter](https://flutter.dev/docs/get-started/install)
*   **Node.js**: [Install Node.js](https://nodejs.org/)
*   **Python**: [Install Python](https://www.python.org/)
*   **PostgreSQL**: Database server.

### Running the App (Frontend)

1.  Connect a device or start an emulator.
2.  Run `flutter run` in the root directory.

### Running the Backend

```bash
cd backend
npm install
npm start
```

### Running the Admin Dashboard (React Web)

The admin portal manages users and handles the MLOps pipeline.
```bash
cd admin_panel
npm install
npm run dev
```
*(Runs on `http://localhost:5173`)*

### Running the ML Service (True MLOps Pipeline)

Our system uses a **True MLOps Continuous Learning Pipeline** for Image Classification. 

#### Setup & Run
1. Enter the ML directory: `cd ml_service`
2. Activate your virtual environment (crucial for dependencies):
   - Windows: `..\.venv\Scripts\activate`
   - Mac/Linux: `source ../.venv/bin/activate`
3. Start the FastAPI deep learning microservice:
   ```bash
   python main.py
   # Or using uvicorn directly:
   # uvicorn main:app --host 0.0.0.0 --port 5000 --reload
   ```
*(Runs on `http://localhost:5000`)*

#### How the ML Training Works (Data Flywheel)
1. **Data Collection**: When users (or fake accounts) post new items and correct the categories, the images are automatically saved to `ml_service/dataset/user_corrections/`.
2. **Triggering**: The Admin logs into the React Admin Dashboard (`http://localhost:5173/ml-models`). The dashboard detects new pending images.
3. **Training**: Clicking "Retrain & Deploy" sends a command to the Python backend to run PyTorch `fine_tune_model()`.
4. **Evaluation**: Python automatically runs a test against the dataset using `scikit-learn` to calculate real Accuracy, Precision, and Recall.
5. **Real-Time Update**: The metrics are saved to `metrics_history.json`, and the React UI dynamically refreshes with the new model version (e.g., v1.0.1) and its real performance stats!

## Tech Stack

*   **Frontend**: Flutter (Mobile), React & Vite (Admin Web)
*   **Backend**: Node.js, Express, PostgreSQL
*   **AI/ML**: Python, PyTorch (MobileNetV2), FastAPI, Scikit-learn
*   **Cloud**: Firebase Auth, Cloud Storage
