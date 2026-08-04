import express from 'express';
import { authenticateToken, authenticateTokenOptional } from '../middleware/authMiddleware.js';
import { trackInteraction, getRecommendations, getTrendingItems, getTrendingCategories } from '../controllers/recommendationController.js';

const router = express.Router();

router.post('/', authenticateTokenOptional, trackInteraction);
router.post('/track', authenticateTokenOptional, trackInteraction);

router.get('/', authenticateTokenOptional, getRecommendations);
router.get('/trending', authenticateTokenOptional, getTrendingItems); // Legacy /trending -> /trending/items
router.get('/trending/items', authenticateTokenOptional, getTrendingItems);
router.get('/trending/categories', authenticateTokenOptional, getTrendingCategories);

export default router;
