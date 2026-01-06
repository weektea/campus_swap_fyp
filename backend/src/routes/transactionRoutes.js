import express from 'express';
import { createTransaction, getUserTransactions, updateTransactionStatus } from '../controllers/transactionController.js';

const router = express.Router();

router.post('/', createTransaction);
router.get('/user/:user_id', getUserTransactions);
router.patch('/:id/status', updateTransactionStatus);


export default router;
