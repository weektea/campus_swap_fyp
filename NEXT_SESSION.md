# Progress Report & Next Steps (2026-01-27)

## ✅ Completed Today
1. **Frontend**:
   - **Buyer "Rate Seller" Logic Fixed**: Added `hasRated` check, implemented `Reviews` UI in `MyTransactionsPage`.
   - **Transaction UI Enhanced**: Added product thumbnails with "SOLD/RESERVED" overlays.
   - **Public Profile**: Created `Assistant` (Seller) profile page showing listings.
   - **Input Validation**: Added phone number field, strong password checks, and consistent form validation across Auth pages.
   - **Settings**: Added Change Password (In-app) and Forgot Password (Pre-login) screens.

2. **Backend**:
   - **Schema Update**: Added `phone_number` to User model.
   - **Auth**: Implemented `change-password` and `forgot-password` endpoints.
   - **Validation**: Strict file upload filters (images only) and input sanitization.
   - **Admin**: Created `scripts/createAdmin.js` for seeding admin accounts.

## 🔜 Next Steps (To-Do List)
1. **Admin Portal (Web)**:
   - **Admin Portal (Web)**: Created a React + Vite admin dashboard in `admin_panel/`.
   - **Features**: Login (Admin only), Dashboard Stats, User Management (List/Delete), Transactions View.
   - **Status**: ✅ Implemented & Built.

2. **Email Verification**:
   - Currently postponed (see `FUTURE_TASKS.md`). Need to implement `nodemailer` eventually.

   - **Notifications**:
   - **Backend**: Verified `createNotification` triggers on transaction status changes.
   - **Frontend**: Implemented `NotificationService` with polling (every 30s) and Local Notifications.
   - **UI**: Added Red Dot Badge on Home Page bell icon using `ValueListenableBuilder`.
   - **Status**: ✅ Implemented.

4. **Testing**:
   - Validating the "Buyer" flow end-to-end with the new validation rules.
   - Test Admin login via App (ensure no crashes).

## 📌 Notes
- Admin accounts are created via CLI script: `node backend/scripts/createAdmin.js`.
- Email verification is ON (`BYPASS_EMAIL_VERIFICATION=false`). OTP emails are dispatched via Mailtrap upon registration.
