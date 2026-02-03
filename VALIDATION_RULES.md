# Account Registration & Validation Rules
**Updated:** 2026-02-03
**Status:** Implemented

To ensure security and verifying student identity, the following validation rules are strictly enforced on both the Mobile App (Frontend) and the Server (Backend).

## 1. University ID (Matric No.)
**Format:** `YYAAAXXXXX`
*   `YY`: 2 digits (Year, e.g., 24)
*   `AAA`: 3 letters (Course Code/Faculty, e.g., PMR)
*   `XXXXX`: 5 unique digits
*   **Example:** `24PMR01234`
*   **Implementation:** Regex `^\d{2}[a-zA-Z]{3}\d{5}$`

## 2. Password Security
**Complexity Requirement:**
*   Min length: **8 characters**
*   Must contain at least **1 Uppercase Letter** (A-Z)
*   Must contain at least **1 Lowercase Letter** (a-z)
*   Must contain at least **1 Number** (0-9)
*   Must contain at least **1 Special Symbol** (!@#$ etc.)
*   **Reason:** To prevent weak passwords and unauthorized access.
*   **Implementation:** Regex `r'(?=.*[A-Z])'`, `r'(?=.*[a-z])'`, `r'(?=.*[0-9])'`, `r'(?=.*[\W_])'`

## 3. Phone Number
**Format:** Malaysian Mobile format
*   Must start with `+60`
*   Format: `+601X-XXXXXXX`
*   **Examples:**
    *   `+6016-1234567` (Valid)
    *   `+6011-23456789` (Valid)
    *   `0161234567` (Invalid - must have country code)
*   **Implementation:** Regex `^\+60\d{2}-\d{7,8}$`

## 4. Email Address
**Domain Requirement:**
*   Must end with `.edu.my`
*   **Reason:** Strict restriction to verifiable campus students only.
*   **Implementation:** String check `.endsWith('.edu.my')`

## 5. Implementation Locations
*   **Frontend API Call:** `lib/features/auth/presentation/pages/register_page.dart` (User Feedback)
*   **Backend Controller:** `backend/src/controllers/authController.js` (Security Enforcement)
*   **Database:** `backend/src/models/User.js` (Data Integrity)
