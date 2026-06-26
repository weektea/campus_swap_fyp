import express from 'express';
import { getUserNotifications, markAsRead, deleteNotification, clearReadNotifications } from '../controllers/notificationController.js';
import { authenticateToken } from '../middleware/authMiddleware.js';

const router = express.Router();

router.get('/', authenticateToken, getUserNotifications);
router.patch('/:id/read', authenticateToken, markAsRead);
router.delete('/clear-read', authenticateToken, clearReadNotifications);
router.delete('/:id', authenticateToken, deleteNotification);

export default router;
