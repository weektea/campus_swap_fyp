import express from 'express';
import { authenticateToken } from '../middleware/authMiddleware.js';
import * as moderatorController from '../controllers/moderatorController.js';

const router = express.Router();

// Custom middleware to check if user is moderator (or admin fallback)
const isModerator = (req, res, next) => {
    if (req.user && (req.user.role === 'moderator' || req.user.role === 'admin')) {
        next();
    } else {
        res.status(403).json({ error: 'Moderator access required.' });
    }
};

// Apply auth and role check to all routes in this file
router.use(authenticateToken);
router.use(isModerator);

// Dashboard Data
router.get('/dashboard', moderatorController.getDashboardData);
router.get('/metrics', moderatorController.getSystemMetrics);

// Content Moderation (Reports)
router.put('/reports/:id/status', moderatorController.updateReportStatus);

// Dispute Triage
router.put('/disputes/:id/triage', moderatorController.triageDispute);

// Support Tickets
router.put('/tickets/:id/claim', moderatorController.claimTicket);
router.put('/tickets/:id/resolve', moderatorController.resolveTicket);

export default router;
