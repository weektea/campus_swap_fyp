import express from 'express';
import { sendMessage, getConversation, getChatList } from '../controllers/messageController.js';
import { authenticateToken } from '../middleware/authMiddleware.js';

const router = express.Router();

router.post('/', authenticateToken, sendMessage);
router.get('/conversation/:otherId', authenticateToken, getConversation);
router.get('/list', authenticateToken, getChatList);

export default router;
