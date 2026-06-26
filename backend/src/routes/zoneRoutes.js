import express from 'express';
import { authenticateToken } from '../middleware/authMiddleware.js';
import { SafeMeetupZone } from '../models/index.js';

const router = express.Router();

// Retrieve all active safe zones for mobile clients
router.get('/', authenticateToken, async (req, res) => {
    try {
        const zones = await SafeMeetupZone.findAll({
            where: { is_active: true }
        });
        res.json(zones);
    } catch (error) {
        console.error('Error fetching safe zones:', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

export default router;
