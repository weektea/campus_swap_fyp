# QA Test Log
**Date:** 2026-02-03
**Feature:** User Registration

## 1. Test Summary
*   **Status:** ⚠️ Failed (Connectivity Issue)
*   **Frontend:** Flutter Android App
*   **Backend:** Node.js (Localhost:3000)
*   **Database:** PostgreSQL (Docker)

## 2. Issues Encountered
### Issue A: "Connection Timed Out" (SocketException: errno 110)
*   **Description:** The Android Emulator cannot reach the backend server at `http://10.0.2.2:3000`.
*   **Diagnosis:**
    *   Backend logic is verified working (via `test_register_sim.js`).
    *   The issue is purely network/infrastructure related between Emulator and Host PC.
    *   Possible causes: Firewall, ADB bridge issue, or Binding IP.
*   **Fixes Attempted:**
    *   Changed App to listen on `0.0.0.0` (Done).
    *   Added `usesCleartextTraffic` to AndroidManifest (Done).
    *   Fixed `express` import crash in backend (Done).
*   **Next Steps:**
    *   Try `adb reverse tcp:3000 tcp:3000`.
    *   Check Windows Firewall rules for Node.js.

## 3. Data Integrity Updates
*   **Uniqueness Constraint Implemented:**
    *   **Email**: Must be unique.
    *   **Phone Number**: NOW set to `unique: true`.
    *   **University ID**: NOW set to `unique: true`.
*   **Validation Rules:** (See `VALIDATION_RULES.md`)

## 4. Pending Actions
*   [ ] Resolve Emulator Connectivity issue.
*   [ ] Verify unique constraint error handling in UI (e.g., "Phone number already exists").
