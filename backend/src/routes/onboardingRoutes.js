import express from 'express';
import { getOnboardingOptions, submitOnboardingPreferences } from '../controllers/onboardingController.js';
import { authenticateToken } from '../middleware/authMiddleware.js';

const router = express.Router();

router.get('/options', getOnboardingOptions);
router.post('/preferences', authenticateToken, submitOnboardingPreferences);

export default router;
