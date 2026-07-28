import express from 'express';
import { 
    createTransaction, 
    getUserTransactions, 
    updateTransactionStatus, 
    addRating, 
    getTransactionById, 
    getTransactionReceipt,
    getBookedDates,
    returnRentalAndRefundDeposit,
    claimRentalDeposit
} from '../controllers/transactionController.js';
import { authenticateToken } from '../middleware/authMiddleware.js';

const router = express.Router();

router.post('/', authenticateToken, createTransaction);
router.get('/user/:user_id', authenticateToken, getUserTransactions);
router.get('/product/:product_id/booked-dates', authenticateToken, getBookedDates);
router.get('/:id', authenticateToken, getTransactionById);
router.get('/:id/receipt', authenticateToken, getTransactionReceipt);
router.patch('/:id/status', authenticateToken, updateTransactionStatus);
router.patch('/:id/rate', authenticateToken, addRating);
router.post('/:id/return-rental', authenticateToken, returnRentalAndRefundDeposit);
router.post('/:id/claim-deposit', authenticateToken, claimRentalDeposit);

export default router;
