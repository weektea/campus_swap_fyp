import express from 'express';
import { User } from '../models/index.js';

const router = express.Router();

router.get('/users', async (req, res) => {
    try {
        const users = await User.findAll();
        res.json(users);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

router.delete('/users/:id', async (req, res) => {
    try {
        await User.destroy({ where: { id: req.params.id } });
        res.json({ message: 'User deleted' });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Admin Stats Endpoint (Optional) - Can expand later

export default router;
