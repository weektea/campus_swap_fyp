import express from 'express';
import { toggleSave, getSavedItems } from '../controllers/savedController.js';

const router = express.Router();

router.post('/toggle', toggleSave);
router.get('/:user_id', getSavedItems);

export default router;
