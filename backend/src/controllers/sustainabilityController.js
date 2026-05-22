import { User, Transaction, Product } from '../models/index.js';
import { Op } from 'sequelize';
import { getCarbonValue } from './transactionController.js';

export const getLeaderboard = async (req, res) => {
    try {
        const users = await User.findAll({
            attributes: ['id', 'full_name', 'email', 'total_carbon_saved'],
            order: [['total_carbon_saved', 'DESC']],
            limit: 10
        });

        // Add ranks
        const leaderboard = users.map((u, index) => {
            return {
                id: u.id,
                name: u.full_name || u.email || 'Unknown User',
                co2: u.total_carbon_saved,
                rank: index + 1
            };
        });

        res.json(leaderboard);
    } catch (error) {
        console.error('Error fetching leaderboard:', error);
        res.status(500).json({ error: 'Failed to fetch leaderboard' });
    }
};

export const getImpactByCategory = async (req, res) => {
    try {
        const userId = req.user.id;

        const transactions = await Transaction.findAll({
            where: {
                status: 'Completed',
                [Op.or]: [
                    { buyer_id: userId },
                    { seller_id: userId }
                ]
            },
            include: [{
                model: Product,
                as: 'product',
                attributes: ['category']
            }]
        });

        const categoryMap = {};

        transactions.forEach(t => {
            const cat = t.product?.category || 'Others';
            const subCat = t.product?.sub_category_id;
            
            const carbonValue = getCarbonValue(cat, subCat);
            
            if (!categoryMap[cat]) {
                categoryMap[cat] = 0;
            }
            categoryMap[cat] += carbonValue;
        });

        res.json(categoryMap);
    } catch (error) {
        console.error('Error fetching category impact:', error);
        res.status(500).json({ error: 'Failed to fetch category impact' });
    }
};
