import express from 'express';
import { 
    createCheckoutSession, 
    confirmPayment, 
    stripeWebhook,
    handlePaymentSuccess,
    handlePaymentCancel
} from '../controllers/paymentController.js';
import { authenticateToken } from '../middleware/authMiddleware.js';

const router = express.Router();

router.get('/success', handlePaymentSuccess);
router.get('/cancel', handlePaymentCancel);
router.post('/create-checkout-session', authenticateToken, createCheckoutSession);
router.post('/confirm', authenticateToken, confirmPayment);
router.post('/webhook', express.raw({ type: 'application/json' }), stripeWebhook);

export default router;
