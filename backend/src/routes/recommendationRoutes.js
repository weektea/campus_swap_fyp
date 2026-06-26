import express from 'express';
import { authenticateToken } from '../middleware/authMiddleware.js';
import { trackInteraction, getRecommendations, getTrendingProducts } from '../controllers/recommendationController.js';

const router = express.Router();

router.post('/track', authenticateToken, trackInteraction);
router.get('/', authenticateToken, getRecommendations);
router.get('/trending', authenticateToken, getTrendingProducts);

export default router;
