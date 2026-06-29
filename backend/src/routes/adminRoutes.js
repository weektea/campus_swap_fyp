import express from 'express';
import { authenticateToken } from '../middleware/authMiddleware.js';
import { isAdmin, isAdminOrModerator } from '../middleware/adminMiddleware.js';
import * as adminController from '../controllers/adminController.js';

const router = express.Router();

// ======================= MODERATOR & ADMIN SHARED ROUTES =======================

// Manage Alerts / Notifications
router.get('/alerts', authenticateToken, isAdminOrModerator, adminController.getAlerts);

// Manage Listings (All Products)
router.get('/listings', authenticateToken, isAdminOrModerator, adminController.getAllListings);
router.put('/listings/:id/status', authenticateToken, isAdminOrModerator, adminController.updateListingStatus);
router.delete('/listings/:id', authenticateToken, isAdmin, adminController.deleteListing);

// Manage Transactions
router.get('/transactions', authenticateToken, isAdminOrModerator, adminController.getAllTransactions);

// Manage Reviews
router.get('/reviews', authenticateToken, isAdminOrModerator, adminController.getAllReviews);
router.delete('/reviews/:id', authenticateToken, isAdmin, adminController.deleteReview);

// Manage Categories & Zones
router.get('/categories', authenticateToken, isAdminOrModerator, adminController.getAllCategories);
router.post('/categories', authenticateToken, isAdmin, adminController.createCategory);
router.put('/categories/:id', authenticateToken, isAdmin, adminController.updateCategory);
router.delete('/categories/:id', authenticateToken, isAdmin, adminController.deleteCategory);

router.post('/subcategories', authenticateToken, isAdmin, adminController.createSubCategory);
router.put('/subcategories/:id', authenticateToken, isAdmin, adminController.updateSubCategory);
router.delete('/subcategories/:id', authenticateToken, isAdmin, adminController.deleteSubCategory);

router.get('/zones', authenticateToken, isAdminOrModerator, adminController.getAllZones);
router.post('/zones', authenticateToken, isAdmin, adminController.createZone);
router.put('/zones/:id', authenticateToken, isAdmin, adminController.updateZone);
router.delete('/zones/:id', authenticateToken, isAdmin, adminController.deleteZone);

// Manage Reports and Disputes
router.get('/reports', authenticateToken, isAdminOrModerator, adminController.getReports);
router.put('/reports/:id', authenticateToken, isAdminOrModerator, adminController.resolveReport); // Handle or Escalate
router.get('/disputes', authenticateToken, isAdminOrModerator, adminController.getDisputes);
router.post('/disputes/:id/triage', authenticateToken, isAdminOrModerator, adminController.triageDispute);
router.post('/disputes/:id/arbitrate', authenticateToken, isAdmin, adminController.arbitrateDispute);

// Manage Support Tickets
router.get('/tickets', authenticateToken, isAdminOrModerator, adminController.getTickets);
router.post('/tickets/:id/lock', authenticateToken, isAdminOrModerator, adminController.lockTicket);
router.put('/tickets/:id', authenticateToken, isAdminOrModerator, adminController.replyTicket);


// ======================= ADMINISTRATOR EXCLUSIVE ROUTES =======================
// Platform Monitoring & Reporting
router.get('/metrics', authenticateToken, isAdminOrModerator, adminController.getSystemMetrics);
router.get('/ml-dashboard', authenticateToken, isAdmin, adminController.getMLDashboardMetrics);

// Full User Administration (Promoting, Banning)
router.get('/users', authenticateToken, isAdmin, adminController.getAllUsers);
router.get('/users/:id', authenticateToken, isAdmin, adminController.getUserDetails);
router.post('/users', authenticateToken, isAdmin, adminController.createUser);
router.put('/users/:id', authenticateToken, isAdmin, adminController.manageUserRoleOrBan);
router.delete('/users/:id', authenticateToken, isAdmin, adminController.deleteUser);

// DB Management
router.get('/backups', authenticateToken, isAdmin, adminController.getBackups);
router.post('/backup', authenticateToken, isAdmin, adminController.backupDatabase);
router.post('/restore/:id', authenticateToken, isAdmin, adminController.restoreDatabase);

export default router;
