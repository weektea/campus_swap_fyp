import express from 'express';
import { toggleSave, getSavedItems } from '../controllers/savedController.js';
import { authenticateToken } from '../middleware/authMiddleware.js';

const router = express.Router();

router.post('/toggle', authenticateToken, toggleSave);
router.get('/', authenticateToken, getSavedItems);

export default router;
