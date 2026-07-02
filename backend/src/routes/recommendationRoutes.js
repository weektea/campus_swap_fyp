import express from 'express';
import { authenticateToken } from '../middleware/authMiddleware.js';
import { trackInteraction, getRecommendations, getTrendingItems, getTrendingCategories } from '../controllers/recommendationController.js';

const router = express.Router();

router.post('/track', authenticateToken, trackInteraction);
router.get('/', authenticateToken, getRecommendations);
router.get('/trending', authenticateToken, getTrendingItems); // Legacy /trending -> /trending/items
router.get('/trending/items', authenticateToken, getTrendingItems);
router.get('/trending/categories', authenticateToken, getTrendingCategories);

export default router;
