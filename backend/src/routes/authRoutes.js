import express from 'express';
import { register, verifyOtp, login, resendOtp, updateProfile, deleteAccount, changePassword, forgotPassword, getResetPasswordForm, resetPassword, getUserProfile, reportUser, checkUsername, reactivateUser, submitSuspensionAppeal, submitPublicAppeal, followUser, unfollowUser, checkFollowStatus, getFollowingList, getFollowersList, submitOnboarding } from '../controllers/authController.js';
import { authenticateToken } from '../middleware/authMiddleware.js';

const router = express.Router();

router.post('/onboarding', authenticateToken, submitOnboarding);

router.get('/check-username', checkUsername);
router.post('/register', register);
router.post('/verify-otp', verifyOtp);
router.post('/resend-otp', resendOtp);
router.post('/login', login);
router.post('/forgot-password', forgotPassword);
router.get('/reset-password', getResetPasswordForm);
router.post('/reset-password', resetPassword);
router.post('/change-password', authenticateToken, changePassword);
router.get('/user/following', authenticateToken, getFollowingList);
router.get('/user/:id', authenticateToken, getUserProfile);
router.patch('/user/:id', authenticateToken, updateProfile);
router.delete('/user/:id', authenticateToken, deleteAccount);
router.post('/user/:id/report', authenticateToken, reportUser);
router.put('/users/reactivate', reactivateUser);
router.post('/appeal', submitSuspensionAppeal);
router.post('/appeal/public', submitPublicAppeal);

// Follow/Unfollow endpoints
router.post('/user/:id/follow', authenticateToken, followUser);
router.post('/user/:id/unfollow', authenticateToken, unfollowUser);
router.get('/user/:id/follow-status', authenticateToken, checkFollowStatus);
router.get('/user/:id/following', authenticateToken, getFollowingList);
router.get('/user/:id/followers', authenticateToken, getFollowersList);

export default router;
