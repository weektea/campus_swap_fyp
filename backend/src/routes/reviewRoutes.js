import express from 'express';
import { createReview, getUserReviews } from '../controllers/reviewController.js';
import { authenticateToken } from '../middleware/authMiddleware.js';

const router = express.Router();

router.post('/', authenticateToken, createReview);
router.get('/user/:user_id', getUserReviews);

export default router;
