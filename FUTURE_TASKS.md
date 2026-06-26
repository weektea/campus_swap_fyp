# Future Tasks & Improvements

## Postponed for Testing Convenience
- [ ] **Email Verification**: Implement email verification link sending upon registration. Users should click the link to verify `is_verified` status.
  - *Reason*: Postponed to allow easy internal testing with limited real student emails.
  - *Implementation Details*: Use `nodemailer` in backend `authController.register`. Generate a random token, save to User model (or separate Token model), send email. Create verify route `GET /auth/verify?token=...`.

## Upcoming Improvements
- [ ] **Real-time Chat**: Upgrade current HTTP polling chat to `socket.io` for instant messaging.
- [ ] **Admin Analytics**: Add charts/graphs to Admin Portal Dashboard.
- [ ] **Mobile Admin**: Verify Admin Login works on Flutter Mobile App (currently Web only optimized).

## Known Limitations & Future Work (FYP)
- [ ] **ML Dynamic Category Synchronization (Class-Incremental Learning)**: 
  - *Limitation*: Currently, categories can be dynamically created by Admins in the Node.js backend. However, the Machine Learning service (`ml_service`) relies on a hardcoded list of 27 classes (`FLAT_CLASSES`) and a fixed neural network output layer size. If an Admin creates a new category, the ML model will fallback and classify those images as `Others___Miscellaneous` because it cannot dynamically adapt its PyTorch model architecture on the fly.
  - *Future Work*: Decouple ML categories from hardcoded Python arrays. Implement an initialization step where `ml_service` fetches categories from the backend DB/API. Modify the `fine_tune_model` logic to dynamically replace and resize the final classifier layer (`nn.Linear`) to support $N+x$ classes before retraining, enabling true Continuous Learning for newly added admin categories.
