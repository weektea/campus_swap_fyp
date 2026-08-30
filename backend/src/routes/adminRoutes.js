import express from 'express';
import { authenticateToken } from '../middleware/authMiddleware.js';
import { isAdmin, isAdminOrModerator } from '../middleware/adminMiddleware.js';
import * as adminController from '../controllers/adminController.js';
import { getAdminAnalytics, exportEnvironmentalReport } from '../controllers/analyticsController.js';
import * as systemController from '../controllers/systemController.js';

const router = express.Router();

// ======================= MODERATOR & ADMIN SHARED ROUTES =======================

// Manage Alerts / Notifications
router.get('/alerts', authenticateToken, isAdminOrModerator, adminController.getAlerts);

// Manage Listings (All Products)
router.get('/listings', authenticateToken, isAdminOrModerator, adminController.getAllListings);
router.get('/popular-listings', authenticateToken, isAdminOrModerator, adminController.getPopularListings);
router.put('/listings/:id/status', authenticateToken, isAdminOrModerator, adminController.updateListingStatus);

router.delete('/listings/:id', authenticateToken, isAdmin, adminController.deleteListing);

// Manage Transactions
router.get('/transactions', authenticateToken, isAdminOrModerator, adminController.getAllTransactions);

// Manage Reviews & NLP Auto-Moderation
router.get('/reviews', authenticateToken, isAdminOrModerator, adminController.getAllReviews);
router.get('/flagged-reviews', authenticateToken, isAdminOrModerator, adminController.getFlaggedReviews);
router.post('/reviews/:id/approve', authenticateToken, isAdminOrModerator, adminController.approveReview);
router.post('/reviews/:id/delete', authenticateToken, isAdmin, adminController.deleteReview);
router.delete('/reviews/:id', authenticateToken, isAdmin, adminController.deleteReview);

import * as facultyController from '../controllers/facultyController.js';

// Manage Categories & Zones & Faculties
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

router.get('/faculties', authenticateToken, isAdminOrModerator, facultyController.getAllFaculties);
router.post('/faculties', authenticateToken, isAdmin, facultyController.createFaculty);
router.put('/faculties/:id', authenticateToken, isAdmin, facultyController.updateFaculty);
router.delete('/faculties/:id', authenticateToken, isAdmin, facultyController.deleteFaculty);

// Manage Reports and Disputes
router.get('/reports', authenticateToken, isAdminOrModerator, adminController.getReports);
router.put('/reports/:id', authenticateToken, isAdminOrModerator, adminController.resolveReport); // Handle or Escalate
router.get('/chats/transcript/:senderId/:receiverId', authenticateToken, isAdminOrModerator, adminController.getChatTranscript);
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
router.get('/analytics', authenticateToken, isAdminOrModerator, getAdminAnalytics);
router.get('/analytics/onboarding', authenticateToken, isAdminOrModerator, adminController.getOnboardingAnalytics);
router.get('/export-report', authenticateToken, isAdminOrModerator, exportEnvironmentalReport);
router.get('/ml-dashboard', authenticateToken, isAdmin, adminController.getMLDashboardMetrics);
router.get('/logs', authenticateToken, isAdminOrModerator, adminController.getActivityLogs);
router.post('/notifications/broadcast', authenticateToken, isAdminOrModerator, adminController.broadcastNotification);
router.get('/notifications/broadcast/requests', authenticateToken, isAdminOrModerator, adminController.getBroadcastRequests);
router.post('/notifications/broadcast/requests/:id/approve', authenticateToken, isAdmin, adminController.approveBroadcastRequest);
router.post('/notifications/broadcast/requests/:id/reject', authenticateToken, isAdmin, adminController.rejectBroadcastRequest);

// Full User Administration (Promoting, Banning)
router.get('/users/archived', authenticateToken, isAdminOrModerator, adminController.getArchivedUsers);
router.get('/users', authenticateToken, isAdminOrModerator, adminController.getAllUsers);
router.patch('/users/:id/verify', authenticateToken, isAdminOrModerator, adminController.verifyUser);
router.patch('/users/:id/flag', authenticateToken, isAdminOrModerator, adminController.flagUser);
router.post('/users/:id/warn', authenticateToken, isAdminOrModerator, adminController.warnUser);
router.post('/users/:id/suspend', authenticateToken, isAdminOrModerator, adminController.suspendUser);
router.get('/users/:id', authenticateToken, isAdminOrModerator, adminController.getUserDetails);
router.post('/users', authenticateToken, isAdmin, adminController.createUser);
router.put('/users/:id', authenticateToken, isAdmin, adminController.manageUserRoleOrBan);
router.delete('/users/:id', authenticateToken, isAdmin, adminController.deleteUser);
router.delete('/users/:id/permanent', authenticateToken, isAdmin, adminController.deleteUserPermanent);

// DB Management
router.get('/backups', authenticateToken, isAdmin, adminController.getBackups);
router.post('/backup', authenticateToken, isAdmin, adminController.backupDatabase);
router.post('/restore/:id', authenticateToken, isAdmin, adminController.restoreDatabase);

import multer from 'multer';

const csvUpload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 10 * 1024 * 1024 },
    fileFilter: (req, file, cb) => {
        if (
            file.mimetype.includes('csv') || 
            file.mimetype === 'text/plain' || 
            file.mimetype === 'application/vnd.ms-excel' || 
            file.originalname.toLowerCase().endsWith('.csv')
        ) {
            cb(null, true);
        } else {
            cb(new Error('Only CSV files (.csv) are allowed for whitelist upload.'));
        }
    }
});

// Student Whitelist (Directory) Management
router.get('/whitelist', authenticateToken, isAdminOrModerator, adminController.getStudentWhitelist);
router.post('/whitelist/upload', authenticateToken, isAdmin, csvUpload.single('file'), adminController.uploadStudentWhitelist);
router.post('/whitelist', authenticateToken, isAdmin, adminController.createStudentWhitelistEntry);
router.put('/whitelist/:id/status', authenticateToken, isAdminOrModerator, adminController.updateStudentWhitelistStatus);
router.delete('/whitelist/:id', authenticateToken, isAdmin, adminController.deleteStudentWhitelistEntry);
router.get('/whitelist/export', authenticateToken, isAdminOrModerator, adminController.exportStudentWhitelistCSV);

// Moderation Rules & Flagged Contents Management
router.get('/moderation/rules', authenticateToken, isAdminOrModerator, adminController.getModerationRules);
router.post('/moderation/rules', authenticateToken, isAdmin, adminController.createModerationRule);
router.put('/moderation/rules/:id', authenticateToken, isAdmin, adminController.updateModerationRule);
router.delete('/moderation/rules/:id', authenticateToken, isAdmin, adminController.deleteModerationRule);
router.post('/moderation/test', authenticateToken, isAdminOrModerator, adminController.testModerationEngine);
router.get('/moderation/flagged', authenticateToken, isAdminOrModerator, adminController.getFlaggedContents);
router.put('/moderation/flagged/:id/resolve', authenticateToken, isAdminOrModerator, adminController.resolveFlaggedContent);

// System Management (Admin Only)
router.get('/system/health', authenticateToken, isAdmin, systemController.getSystemHealth);
router.get('/system/settings', authenticateToken, isAdmin, systemController.getSystemSettings);
router.put('/system/settings', authenticateToken, isAdmin, systemController.updateSystemSettings);
router.put('/system/policies/:type', authenticateToken, isAdmin, systemController.updatePolicy);

export default router;

