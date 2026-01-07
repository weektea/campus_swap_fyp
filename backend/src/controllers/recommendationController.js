import { UserInteraction, Product, User } from '../models/index.js';
import { Op } from 'sequelize';
import sequelize from '../config/database.js';

// Track a user action
export const trackInteraction = async (req, res) => {
    try {
        const { product_id, type } = req.body;
        const user_id = req.user.id; // From auth middleware

        let weight = 1;
        switch (type) {
            case 'view': weight = 1; break;
            case 'message': weight = 3; break;
            case 'save': weight = 5; break;
            case 'buy': weight = 10; break;
        }

        await UserInteraction.create({
            user_id,
            product_id,
            interaction_type: type,
            weight
        });

        res.status(200).json({ message: 'Interaction tracked' });
    } catch (error) {
        console.error('Tracking Error:', error);
        res.status(500).json({ error: 'Failed to track' });
    }
};

// Get Recommendations (Content-Based + Simple Collaborative)
export const getRecommendations = async (req, res) => {
    try {
        const user_id = req.user.id;

        // 1. Get user's top categories based on history
        // SQL: SELECT p.category, SUM(ui.weight) as score 
        // FROM UserInteractions ui JOIN Products p ON ui.product_id = p.id 
        // WHERE ui.user_id = :id GROUP BY p.category ORDER BY score DESC LIMIT 3

        const topCategoriesQuery = await sequelize.query(`
            SELECT p.category, SUM(ui.weight) as score
            FROM "UserInteractions" ui
            JOIN "Products" p ON ui.product_id = p.id
            WHERE ui.user_id = :id
            GROUP BY p.category
            ORDER BY score DESC
            LIMIT 3
        `, {
            replacements: { id: user_id },
            type: sequelize.QueryTypes.SELECT
        });

        const preferredCategories = topCategoriesQuery.map(row => row.category);

        let whereClause = {
            status: 'Available',
            seller_id: { [Op.ne]: user_id } // Don't recommend own products
        };

        if (preferredCategories.length > 0) {
            whereClause.category = { [Op.in]: preferredCategories };
        }
        // If no history, it will return generic latest items (cold start)

        const recommendations = await Product.findAll({
            where: whereClause,
            include: [{
                model: User,
                as: 'seller',
                attributes: ['full_name', 'reputation_score']
            }],
            order: preferredCategories.length > 0
                ? sequelize.random() // Shuffle recommended items
                : [['createdAt', 'DESC']], // Fallback to newest
            limit: 10
        });

        res.json(recommendations);
    } catch (error) {
        console.error('Recommendation Error:', error);
        res.status(500).json({ error: 'Failed to get recommendations' });
    }
};
