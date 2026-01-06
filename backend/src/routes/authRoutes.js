import express from 'express';
import { register, login, updateProfile } from '../controllers/authController.js';

const router = express.Router();

router.post('/register', register);
router.post('/login', login);
router.patch('/user/:id', updateProfile);

export default router;
