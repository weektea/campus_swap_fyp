import express from 'express';
import { register, login, updateProfile, deleteAccount, changePassword, forgotPassword, getUserProfile, reportUser, checkUsername } from '../controllers/authController.js';
import { authenticateToken } from '../middleware/authMiddleware.js';

const router = express.Router();

router.get('/check-username', checkUsername);
router.post('/register', register);
router.post('/login', login);
router.post('/forgot-password', forgotPassword);
router.post('/change-password', authenticateToken, changePassword);
router.get('/user/:id', authenticateToken, getUserProfile);
router.patch('/user/:id', authenticateToken, updateProfile);
router.delete('/user/:id', authenticateToken, deleteAccount);
router.post('/user/:id/report', authenticateToken, reportUser);

export default router;
