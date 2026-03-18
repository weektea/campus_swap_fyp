# System Modules Audit Report

**Date:** 2026-02-10
**Audit Standard:** "Perfect" / Production-Ready
**Overall Status:** Prototype / MVP Level (Significant Gaps for "Perfect" Standard)

---

## 1. User Management Module
*Handles student identity verification, profile, trust scoring.*

*   **Status:** ✅ **Functional MVP**
*   **Current Implementation:**
    *   **Verification:** Robust regex enforces `.edu.my` emails. `university_id` format validation exists.
    *   **Trust Scoring:** `reputation_score` exists in DB. `reviewController.js` updates it based on a simple average of ratings.
*   **Missing for "Perfect":**
    *   **Email Verification:** No actual email is sent to verify ownership. A user could technically register with a fake `.edu.my` email if they guess the format.
    *   **Advanced Trust Logic:** Score is a simple average. A "perfect" system should weight recent ratings higher or factor in transaction volume to prevent manipulation.
    *   **Field Validation:** `forgotPassword` is explicitly mocked (`[MOCK EMAIL SERVICE]`).

## 2. Product Management Module
*Listing process, automated recognition.*

*   **Status:** ⚠️ **Partial / Disconnected**
*   **Current Implementation:**
    *   **Listing:** basic CRUD operations work perfectly.
    *   **ML Integration:** `ml/main.py` has a `/classify-image` endpoint using MobileNetV2.
*   **Missing for "Perfect":**
    *   **Disconnection:** The frontend (`AddProductPage` logic) **DOES NOT** call the ML service. The "Automated category recognition" feature is implemented in Python but **unused** by the App.
    *   **Multimedia:** No backend enforcement of the "9 images" limit or image compression/optimization.

## 3. Search & Browsing Module
*Advanced filtering.*

*   **Status:** ✅ **Good**
*   **Current Implementation:**
    *   Backend supports `search`, `category`, `price_min/max`, `condition`, and `sort` (newest/price).
    *   Frontend integrates these filters.
*   **Missing for "Perfect":**
    *   **Elasticsearch/MeiliSearch:** Currently uses SQL `LIKE` queries (`Op.iLike`), which is slow for large datasets. A "perfect" system needs a dedicated search engine.

## 4. ML Recommendation Module
*Intelligence core, personalized feeds.*

*   **Status:** ❌ **Mock / Placeholder**
*   **Current Implementation:**
    *   `ml/main.py` has a `/recommend` endpoint.
    *   **IT RETURNS FAKE DATA:** `product_ids: ["prod_1", "prod_2", "prod_5"]`.
*   **Missing for "Perfect":**
    *   **Everything:** The "intelligence core" is non-existent. It needs to be replaced with a real Collaborative Filtering or Content-Based model (e.g., using TensorFlow Recommenders) trained on the `UserInteraction` data.

## 5. Transaction Management Module
*Order lifecycle, receipts.*

*   **Status:** ⚠️ **Basic MVP**
*   **Current Implementation:**
    *   Tracks `Pending` -> `Scheduled` -> `Completed` status.
    *   Notifications are sent at key steps.
*   **Missing for "Perfect":**
    *   **Digital Receipts:** No PDF generation or formal receipt view.
    *   **Dispute Handling:** `Disputed` status exists in Enums but no logic handles it (e.g., freezing funds, admin intervention flow).

## 6. Rental System Module
*Resource sharing, booking calendars, duration tracking.*

*   **Status:** ❌ **Severely Lacking**
*   **Current Implementation:**
    *   DB has `type='Rent'` and `rental_price_per_day`.
*   **Missing for "Perfect":**
    *   **Booking Calendars:** NO logic to check availability dates.
    *   **Duration Tracking:** `Transaction` model has `scheduled_at` (single point in time) but **NO** `end_date` or `rental_period`. You cannot rent an item for "3 days".
    *   **Logic:** The system treats Rentals exactly like Sales, just with a different label.

## 7. Interaction Module
*Messaging, negotiation.*

*   **Status:** ⚠️ **Basic**
*   **Current Implementation:**
    *   Simple REST API for sending/retrieving messages.
*   **Missing for "Perfect":**
    *   **Real-time:** No WebSocket (Socket.io) implementation. Messages only appear on refresh.
    *   **Security:** Messages are stored in **plain text** in the database. End-to-end encryption or at least DB encryption is required for a secure environment.

## 8. Sustainability Analytics Module
*Carbon footprint reduced visualization.*

*   **Status:** ❌ **Missing**
*   **Current Implementation:**
    *   None found.
*   **Missing for "Perfect":**
    *   **Calculation Logic:** Need a formula (e.g., *Category X Average Carbon Footprint = Saved Amount*).
    *   **Visualization:** Dashboard widgets to show "CO2 Saved" to the user.

---

## Action Plan to Reach "Perfect"

1.  **Connect ML:** Wire up Flutter to call `/classify-image` before submitting a product.
2.  **Build Rental Logic:** Add `start_date` and `end_date` to Transactions. Implement overlap checking.
3.  **Implement Sustainability:** Create a `SustainabilityService` to calculate CO2 stats on each transaction completion.
4.  **Real Recommendation:** Replace the mock in `ml/main.py` with a simple Matrix Factorization model.
