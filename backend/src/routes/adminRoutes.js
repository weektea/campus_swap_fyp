import express from 'express';
import { User, Transaction, Product } from '../models/index.js';
import { authenticateToken } from '../middleware/authMiddleware.js';
import { isAdmin } from '../middleware/adminMiddleware.js';

const router = express.Router();

router.get('/users', authenticateToken, isAdmin, async (req, res) => {
    try {
        const users = await User.findAll();
        res.json(users);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

router.delete('/users/:id', authenticateToken, isAdmin, async (req, res) => {
    try {
        await User.destroy({ where: { id: req.params.id } });
        res.json({ message: 'User deleted' });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

router.get('/transactions', authenticateToken, isAdmin, async (req, res) => {
    try {
        // Include product to show title in admin panel
        const transactions = await Transaction.findAll({
            include: [{ model: Product, as: 'product' }]
        });
        res.json(transactions);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Admin Stats Endpoint
router.get('/stats', authenticateToken, isAdmin, async (req, res) => {
    try {
        const usersCount = await User.count();
        const productsCount = await Product.count();
        const transactionsCount = await Transaction.count();

        res.json({
            users: usersCount,
            products: productsCount,
            transactions: transactionsCount,
            revenue: 0 // TODO: Sum implementation later
        });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

export default router;
