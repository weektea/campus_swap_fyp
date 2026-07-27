import express from 'express';
import { createTransaction, getUserTransactions, updateTransactionStatus, addRating, getTransactionById, getTransactionReceipt } from '../controllers/transactionController.js';
import { authenticateToken } from '../middleware/authMiddleware.js';

const router = express.Router();

router.post('/', authenticateToken, createTransaction);
router.get('/user/:user_id', authenticateToken, getUserTransactions);
router.get('/:id', authenticateToken, getTransactionById);
router.get('/:id/receipt', authenticateToken, getTransactionReceipt);
router.patch('/:id/status', authenticateToken, updateTransactionStatus);
router.patch('/:id/rate', authenticateToken, addRating);

export default router;
