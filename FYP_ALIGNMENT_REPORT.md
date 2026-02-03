# FYP Title Alignment & Progress Report

**Date:** 2026-02-03
**Project:** Smart Campus Second-Hand Trading Platform (Campus Swap)

## Executive Summary
**Status:** ✅ **Fully Aligned**
The current development work for "Campus Swap" is strictly aligned with the "Smart Campus Second-Hand Trading Platform" FYP title. The technology stack, modules, and core features implemented in the codebase match the requirements specified in the FYP confirmation document.

---

## 1. Technology Stack Compliance

| Requirement | Implementation Status | Notes |
| :--- | :--- | :--- |
| **Frontend** | ✅ **Flutter** | `lib/` contains a comprehensive Flutter app structure. |
| **Backend** | ✅ **Node.js + PostgreSQL** | `backend/` uses Node.js/Express. `models/` uses Sequelize for PostgreSQL. |
| **AI/ML** | ✅ **Python (TensorFlow/FastAPI)** | `ml/main.py` implements MobileNetV2 for image classification and price prediction APIs. |
| **Cloud** | ⏳ **In Progress** | Project is containerized (`docker-compose.yml`) ready for cloud deployment. |

---

## 2. Module Implementation Status

### Module 1: User Management System
*   **Requirement:** Authentication, .edu.my verification, Reputation score.
*   **Current State:**
    *   `User.js` model enforces `.edu.my` email domain validation.
    *   User roles (`student`, `admin`, `moderator`) are defined.
    *   Reputation score (0-5) field exists in the database.
    *   Profile management (Avatar upload, password change) is implemented in `features/profile`.

### Module 2: Product Management System
*   **Requirement:** Smart Posting (AI), Multimedia (9 images), Rent/Sale status.
*   **Current State:**
    *   `ml/main.py` provides `/classify-image`, `/predict-price`, and `/generate-description` endpoints.
    *   `Product.js` supports `type` ('Sale' OR 'Rent') and `image_urls` (JSON array).
    *   Fields for `rental_price_per_day` and `max_rental_duration` are present.

### Module 3: Search & Browsing
*   **Requirement:** Keyword search, Filtering, Sorting.
*   **Current State:**
    *   Flutter frontend (`features/home`, `features/product`) includes search bars and category filters.
    *   Backend supports searching and filtering by category/price.

### Module 4: ML-Based Recommendation
*   **Requirement:** Hybrid Recommendation (Content-based + Collaborative).
*   **Current State:**
    *   `ml/main.py` has a `/recommend` endpoint.
    *   *Note:* Currently uses a mock/heuristic logic (Stage 1). Full Deep Learning model (`Wide & Deep` / `NCF`) integration is the next logical step.

### Module 5: Transaction Management
*   **Requirement:** Full cycle (Inquiry -> Order -> Pay -> Rate).
*   **Current State:**
    *   `Transaction.js` model tracks status (`Pending`, `Scheduled`, `Completed`).
    *   `Review.js` links transactions to ratings.
    *   Chat features (`features/chat`) mediate the inquiry phase.

### Module 6: Rental System
*   **Requirement:** Short/Long-term rental, deposits.
*   **Current State:**
    *   Database schema fully supports identifying Rental items vs. Sale items.
    *   "Rent Now" flow is planned/partially implemented in the UI.

### Module 7 & 8: Interaction & Analytics
*   **Requirement:** Social features, Dashboards, Sustainability Metrics.
*   **Current State:**
    *   `UserInteraction.js` tracks likes/views.
    *   `APP_FEATURES_DESC.md` explicitly documents "Sustainability Features" (CO2 Saved) which aligns with SDG 12 & 13 goals.

---

## 3. Conclusion & Next Steps
The codebase is **not off-topic**. Every major file and directory corresponds to a specific requirement in your FYP title. There is no bloat from unrelated projects (e.g., no "Repair Module" or "Meal Plan" code found in the active `lib/features` directory).

**Recommendation:**
1.  **Refine ML Models:** Move `ml/main.py` from mock/heuristics to actual trained models for the Recommendation Engine.
2.  **Transaction Flow:** Finalize the "Meetup/Schedule" UI in Flutter to complete the Module 5 cycle.
3.  **Admin Panel:** Continue the work on `admin_panel` to satisfy the "Administrator" role requirements (User bans, Content moderation).

This project is on a healthy trajectory for FYP completion.
