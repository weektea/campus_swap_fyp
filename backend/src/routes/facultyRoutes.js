import express from 'express';
import { getPublicFaculties } from '../controllers/facultyController.js';

const router = express.Router();

router.get('/', getPublicFaculties);

export default router;
