import express from 'express';
import { getNewestItems } from '../controllers/itemController.js';

const router = express.Router();

router.get('/newest', getNewestItems);

export default router;
