# Future Tasks & Improvements

## Postponed for Testing Convenience
- [ ] **Email Verification**: Implement email verification link sending upon registration. Users should click the link to verify `is_verified` status.
  - *Reason*: Postponed to allow easy internal testing with limited real student emails.
  - *Implementation Details*: Use `nodemailer` in backend `authController.register`. Generate a random token, save to User model (or separate Token model), send email. Create verify route `GET /auth/verify?token=...`.
