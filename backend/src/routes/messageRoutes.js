import express from 'express';
import { sendMessage, getConversation, getChatList } from '../controllers/messageController.js';

const router = express.Router();

router.post('/', sendMessage);
router.get('/conversation/:userId/:otherId', getConversation);
router.get('/list/:userId', getChatList);

export default router;
