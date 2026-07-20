import express from 'express';
import { createProduct, getAllProducts, updateProduct, deleteProduct, reportProduct, classifyImage, getPriceSuggestion, generateDescription, getProductById } from '../controllers/productController.js';
import { authenticateToken } from '../middleware/authMiddleware.js';
import multer from 'multer';

const router = express.Router();
const upload = multer({ dest: 'uploads/' });

router.post('/', authenticateToken, createProduct);
router.get('/', getAllProducts);
router.get('/:id', getProductById);
router.put('/:id', authenticateToken, updateProduct);
router.delete('/:id', authenticateToken, deleteProduct);
router.post('/:id/report', authenticateToken, reportProduct);

// ML Endpoint Mocks
router.post('/classify', upload.single('file'), classifyImage);
router.post('/price-suggestion', authenticateToken, getPriceSuggestion);
router.post('/generate-description', authenticateToken, generateDescription);

export default router;
