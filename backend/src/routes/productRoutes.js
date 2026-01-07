import express from 'express';
import { createProduct, getAllProducts, deleteProduct } from '../controllers/productController.js';
import { authenticateToken } from '../middleware/authMiddleware.js';

const router = express.Router();

router.post('/', authenticateToken, createProduct);
router.get('/', getAllProducts);
router.delete('/:id', authenticateToken, deleteProduct);

export default router;
