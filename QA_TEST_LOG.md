# QA Test Log
**Date:** 2026-02-03
**Feature:** User Registration

## 1. Test Summary
*   **Status:** ✅ Passed (Connectivity Issue Resolved)
*   **Frontend:** Flutter Android App
*   **Backend:** Node.js (Localhost:3000)
*   **Database:** PostgreSQL (Docker)

## 2. Issues Encountered (Resolved)
### Issue A: "Connection Timed Out" (SocketException: errno 110)
*   **Description:** The Android Emulator cannot reach the backend server.
*   **Fixes Applied:**
    *   Changed App to listen on `0.0.0.0`.
    *   Added `usesCleartextTraffic` to AndroidManifest.
    *   Fixed `express` import crash in backend.
    *   **UPDATED `api_client.dart` to use `10.0.2.2` for Android Emulators.** (Resolved)

## 3. Data Integrity Updates
*   **Uniqueness Constraint Implemented:**
    *   **Email**: Must be unique.
    *   **Phone Number**: Set to `unique: true`.
    *   **University ID**: Set to `unique: true`.
*   **Validation Rules:** (See `VALIDATION_RULES.md`)

## 4. Pending Actions
*   [x] Resolve Emulator Connectivity issue. (Done - `api_client.dart` updated)
*   [x] Verify unique constraint error handling in UI. (Done - `api_client.dart` now throws clean `ApiException` parsed from backend JSON error response)
