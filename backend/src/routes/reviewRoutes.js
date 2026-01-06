import express from 'express';
import { createReview, getUserReviews } from '../controllers/reviewController.js';

const router = express.Router();

router.post('/', createReview);
router.get('/user/:user_id', getUserReviews);

export default router;
