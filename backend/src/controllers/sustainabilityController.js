import { User, Transaction, Product, Category, SubCategory } from '../models/index.js';
import { Op } from 'sequelize';
import { getCarbonValue } from './transactionController.js';

export const getLeaderboard = async (req, res) => {
    try {
        const users = await User.findAll({
            where: {
                role: 'student'
            },
            attributes: ['id', 'username', 'full_name', 'email', 'total_carbon_saved', 'profile_image_url'],
            order: [['total_carbon_saved', 'DESC']],
            limit: 10
        });

        // Add ranks
        const leaderboard = users.map((u, index) => {
            return {
                id: u.id,
                name: u.username || u.email || 'Unknown User',
                co2: u.total_carbon_saved,
                profile_image_url: u.profile_image_url,
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
                include: [
                    { model: Category, as: 'categoryModel', attributes: ['name', 'carbon_conversion_factor'] },
                    { model: SubCategory, as: 'subcategoryModel', attributes: ['name', 'carbon_conversion_factor'] }
                ]
            }]
        });

        const categoryMap = {};

        transactions.forEach(t => {
            if (t.product) {
                const catName = t.product.categoryModel ? t.product.categoryModel.name : (t.product.category || 'Others');
                const subCatName = t.product.subcategoryModel ? t.product.subcategoryModel.name : null;
                
                const carbonValue = t.awarded_carbon_points !== null && t.awarded_carbon_points !== undefined
                    ? parseFloat(t.awarded_carbon_points)
                    : getCarbonValue(catName, subCatName, t.product);
                
                if (!categoryMap[catName]) {
                    categoryMap[catName] = 0;
                }
                categoryMap[catName] += carbonValue;
            }
        });

        res.json(categoryMap);
    } catch (error) {
        console.error('Error fetching category impact:', error);
        res.status(500).json({ error: 'Failed to fetch category impact' });
    }
};
