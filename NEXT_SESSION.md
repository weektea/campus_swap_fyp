# Progress Report & Next Steps (2026-01-07)

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
   - Need to start the Web Admin Dashboard for Moderators/Admins to manage users and view stats.
   - *Question*: Will this be a separate React app or part of the same repo? (Likely separate or a `/web` folder).

2. **Email Verification**:
   - Currently postponed (see `FUTURE_TASKS.md`). Need to implement `nodemailer` eventually.

3. **Notifications**:
   - Verify if push notifications (local notifications) are fully wired up for "Status Changes".

4. **Testing**:
   - Validating the "Buyer" flow end-to-end with the new validation rules.
   - Test Admin login via App (ensure no crashes).

## 📌 Notes
- Admin accounts are created via CLI script: `node backend/scripts/createAdmin.js`.
- Email verification is OFF by default (`is_verified: true`) for testing convenience.
