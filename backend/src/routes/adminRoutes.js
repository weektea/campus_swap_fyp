import express from 'express';
import { authenticateToken } from '../middleware/authMiddleware.js';
import { isAdmin, isAdminOrModerator } from '../middleware/adminMiddleware.js';
import * as adminController from '../controllers/adminController.js';

const router = express.Router();

// ======================= MODERATOR & ADMIN SHARED ROUTES =======================
// Audit Listings
router.get('/listings', authenticateToken, isAdminOrModerator, adminController.getListings);
router.post('/listings/:id/suspend', authenticateToken, isAdminOrModerator, adminController.suspendListing);

// Manage Reports
router.get('/reports', authenticateToken, isAdminOrModerator, adminController.getReports);
router.put('/reports/:id', authenticateToken, isAdminOrModerator, adminController.resolveReport); // Handle or Escalate

// Manage Support Tickets
router.get('/tickets', authenticateToken, isAdminOrModerator, adminController.getTickets);
router.post('/tickets/:id/lock', authenticateToken, isAdminOrModerator, adminController.lockTicket);
router.put('/tickets/:id', authenticateToken, isAdminOrModerator, adminController.replyTicket);


// ======================= ADMINISTRATOR EXCLUSIVE ROUTES =======================
// Platform Monitoring & Reporting
router.get('/metrics', authenticateToken, isAdmin, adminController.getSystemMetrics);

// Full User Administration (Promoting, Banning)
router.get('/users', authenticateToken, isAdmin, adminController.getAllUsers);
router.put('/users/:id', authenticateToken, isAdmin, adminController.manageUserRoleOrBan);

// DB Management
router.post('/backup', authenticateToken, isAdmin, adminController.backupDatabase);
router.post('/restore', authenticateToken, isAdmin, adminController.restoreDatabase);

export default router;
