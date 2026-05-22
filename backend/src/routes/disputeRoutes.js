import express from 'express';
import { createDispute, triageDispute, arbitrateDispute } from '../controllers/disputeController.js';
import { authenticateToken } from '../middleware/authMiddleware.js';
import { isAdmin, isAdminOrModerator } from '../middleware/adminMiddleware.js';

const router = express.Router();

router.post('/', authenticateToken, createDispute);

// Mod triage
router.put('/:id/triage', authenticateToken, isAdminOrModerator, triageDispute);

// Admin final arbitration
router.put('/:id/arbitrate', authenticateToken, isAdmin, arbitrateDispute);

export default router;
