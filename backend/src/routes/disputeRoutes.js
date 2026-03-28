import express from 'express';
import { createDispute } from '../controllers/disputeController.js';
import { authenticateToken } from '../middleware/authMiddleware.js';

const router = express.Router();

router.post('/', authenticateToken, createDispute);

export default router;
