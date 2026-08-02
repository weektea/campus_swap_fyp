import express from 'express';
import { getSubcategories } from '../controllers/categoryController.js';

const router = express.Router();

router.get('/', getSubcategories);

export default router;
