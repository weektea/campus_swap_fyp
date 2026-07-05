import express from 'express';
import { authenticateToken as verifyToken } from '../middleware/authMiddleware.js';
import { getProfileAnalytics } from '../controllers/analyticsController.js';

const router = express.Router();

router.get('/', verifyToken, getProfileAnalytics);

export default router;
