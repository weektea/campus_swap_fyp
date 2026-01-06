# Smart Campus Second-Hand Trading Platform

A cross-platform mobile & web application for sustainable campus trading, built with Flutter, Node.js, and Python ML.

## Project Structure

This repository contains the complete source code for the platform, organized into the following directories:

*   **`lib/`**: Flutter Frontend Application.
    *   **`core/`**: Shared resources (Theme, Constants, Utilities).
    *   **`features/`**: Functional modules (Auth, Product, Home, etc.).
*   **`backend/`**: Node.js + PostgreSQL Backend Service.
*   **`ml/`**: Python Machine Learning Service (Recommendations, Image Analysis).

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

(See `backend/README.md` for details)

### Running the ML Service

(See `ml/README.md` for details)

## Tech Stack

*   **Frontend**: Flutter
*   **Backend**: Node.js, Express, PostgreSQL
*   **AI/ML**: Python, TensorFlow, Scikit-learn
*   **Cloud**: Firebase Auth, Cloud Storage
