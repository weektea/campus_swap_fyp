import express from 'express';
import { getLeaderboard, getImpactByCategory } from '../controllers/sustainabilityController.js';
import { authenticateToken } from '../middleware/authMiddleware.js';

const router = express.Router();

router.get('/leaderboard', getLeaderboard);
router.get('/category-impact', authenticateToken, getImpactByCategory);

export default router;
