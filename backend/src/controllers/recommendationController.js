import { UserInteraction, Product, User, Report, Category, SubCategory } from '../models/index.js';
import { Op } from 'sequelize';
import sequelize from '../config/database.js';
import axios from 'axios';

const ML_SERVICE_URL = process.env.ML_SERVICE_URL || 'http://localhost:5000';

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

// Get Recommendations (Hybrid Content-Based + KNN Collaborative)
export const getRecommendations = async (req, res) => {
    try {
        const user_id = req.user.id;

        // 1. Fetch user's interactions
        const userInteractions = await UserInteraction.findAll({
            where: { user_id }
        });

        const reportedItems = await Report.findAll({
            where: { reporter_id: user_id },
            attributes: ['product_id']
        });
        const reportedIds = reportedItems.map(r => r.product_id).filter(Boolean);

        // Helper function for cold-start / fallback trending list
        const getFallbackRecommendations = async () => {
            const trendingQuery = await sequelize.query(`
                SELECT ui.product_id, 
                       COUNT(CASE WHEN ui.interaction_type = 'view' THEN 1 END) as view_count,
                       COUNT(CASE WHEN ui.interaction_type = 'message' THEN 1 END) as message_count,
                       COUNT(CASE WHEN ui.interaction_type = 'save' THEN 1 END) as save_count,
                       SUM(CASE 
                           WHEN ui.interaction_type = 'view' THEN 1
                           WHEN ui.interaction_type = 'message' THEN 3
                           WHEN ui.interaction_type = 'save' THEN 5
                           ELSE 0 
                       END) as score
                FROM "UserInteractions" ui
                JOIN "Products" p ON ui.product_id = p.id
                WHERE p.status = 'Available'
                  AND ui.interaction_type IN ('view', 'message', 'save')
                  AND p.seller_id != :user_id
                GROUP BY ui.product_id
                ORDER BY score DESC
                LIMIT 10
            `, {
                replacements: { user_id },
                type: sequelize.QueryTypes.SELECT
            });

            if (trendingQuery.length > 0) {
                const productIds = trendingQuery.map(row => row.product_id);
                let whereCond = {
                    id: { [Op.in]: productIds },
                    status: 'Available',
                    seller_id: { [Op.ne]: user_id }
                };
                if (reportedIds.length > 0) {
                    whereCond.id = { [Op.in]: productIds, [Op.notIn]: reportedIds };
                }
                const trendingProducts = await Product.findAll({
                    where: whereCond,
                    include: [{
                        model: User,
                        as: 'seller',
                        attributes: ['username', 'full_name', 'reputation_score', 'profile_image_url']
                    }]
                });
                
                return productIds
                    .map(id => trendingProducts.find(p => p.id === id))
                    .filter(Boolean);
            } else {
                return await Product.findAll({
                    where: {
                        status: 'Available',
                        seller_id: { [Op.ne]: user_id },
                        ...(reportedIds.length > 0 ? { id: { [Op.notIn]: reportedIds } } : {})
                    },
                    include: [{ model: User, as: 'seller', attributes: ['username', 'full_name', 'reputation_score', 'profile_image_url'] }],
                    order: [['createdAt', 'DESC']],
                    limit: 10
                });
            }
        };

        // Cold Start Fallback: If user has no interactions, return global trending items
        if (userInteractions.length === 0) {
            const fallbackList = await getFallbackRecommendations();
            return res.json(fallbackList);
        }

        // Fetch all available products (excluding user's own listings and reported listings)
        const availableProducts = await Product.findAll({
            where: {
                status: 'Available',
                seller_id: { [Op.ne]: user_id },
                ...(reportedIds.length > 0 ? { id: { [Op.notIn]: reportedIds } } : {})
            },
            include: [{
                model: User,
                as: 'seller',
                attributes: ['username', 'full_name', 'reputation_score', 'profile_image_url']
            }, {
                model: Category,
                as: 'categoryModel'
            }, {
                model: SubCategory,
                as: 'subcategoryModel'
            }]
        });

        if (availableProducts.length === 0) {
            return res.json([]);
        }

        // Fetch all interactions for Collaborative Filtering (KNN) matrix building
        const allInteractions = await UserInteraction.findAll({
            attributes: ['user_id', 'product_id', 'weight']
        });

        const productsPayload = availableProducts.map(p => ({
            id: p.id,
            title: p.title,
            description: p.description || '',
            category: p.categoryModel ? p.categoryModel.name : (p.category || ''),
            subcategory: p.subcategoryModel ? p.subcategoryModel.name : ''
        }));

        let recommendedIds = [];
        try {
            const pythonRes = await axios.post(`${ML_SERVICE_URL}/api/recommend/hybrid`, {
                user_id: user_id,
                interactions: allInteractions.map(i => ({
                    user_id: i.user_id,
                    product_id: i.product_id,
                    weight: parseFloat(i.weight) || 1.0
                })),
                products: productsPayload
            }, { timeout: 4000 });

            recommendedIds = pythonRes.data.recommended_product_ids || [];
        } catch (pyError) {
            console.error('Python ML recommendation service call failed, falling back to database list:', pyError.message);
            const fallbackList = await getFallbackRecommendations();
            return res.json(fallbackList);
        }

        if (recommendedIds.length === 0) {
            const fallbackList = await getFallbackRecommendations();
            return res.json(fallbackList);
        }

        // Fetch recommendations from DB and maintain python's exact hybrid scoring sorting order
        const recommendedProducts = await Product.findAll({
            where: {
                id: { [Op.in]: recommendedIds },
                status: 'Available'
            },
            include: [{
                model: User,
                as: 'seller',
                attributes: ['username', 'full_name', 'reputation_score', 'profile_image_url']
            }]
        });

        const sortedRecommendations = recommendedIds
            .map(id => recommendedProducts.find(p => p.id === id))
            .filter(Boolean);

        res.json(sortedRecommendations);
    } catch (error) {
        console.error('Recommendation Error:', error);
        res.status(500).json({ error: 'Failed to get recommendations' });
    }
};

export const getTrendingItems = async (req, res) => {
    try {
        const { limit = 10, category } = req.query;

        // Sum weights of views, messages, and saves in UserInteractions per product (excluding 'buy')
        // Favour active and available listings
        const categoryFilter = category ? 'AND p.category = :category' : '';
        const trendingQuery = await sequelize.query(`
            SELECT ui.product_id, 
                   COUNT(CASE WHEN ui.interaction_type = 'view' THEN 1 END) as view_count,
                   COUNT(CASE WHEN ui.interaction_type = 'message' THEN 1 END) as message_count,
                   COUNT(CASE WHEN ui.interaction_type = 'save' THEN 1 END) as save_count,
                   SUM(CASE 
                       WHEN ui.interaction_type = 'view' THEN 1
                       WHEN ui.interaction_type = 'message' THEN 3
                       WHEN ui.interaction_type = 'save' THEN 5
                       ELSE 0 
                   END) as score
            FROM "UserInteractions" ui
            JOIN "Products" p ON ui.product_id = p.id
            WHERE p.status = 'Available'
              AND ui.interaction_type IN ('view', 'message', 'save')
              ${categoryFilter}
            GROUP BY ui.product_id
            ORDER BY score DESC
            LIMIT :limit
        `, {
            replacements: { 
                limit: parseInt(limit),
                category: category || null
            },
            type: sequelize.QueryTypes.SELECT
        });

        if (trendingQuery.length === 0) {
            // Cold start fallback: return latest available items (optionally filtered by category)
            const fallbackWhere = { status: 'Available' };
            if (category) {
                fallbackWhere.category = category;
            }
            const fallback = await Product.findAll({
                where: fallbackWhere,
                include: [{ model: User, as: 'seller', attributes: ['username', 'full_name', 'reputation_score', 'profile_image_url'] }],
                order: [['createdAt', 'DESC']],
                limit: parseInt(limit)
            });
            return res.json(fallback);
        }

        const productIds = trendingQuery.map(row => row.product_id);

        const products = await Product.findAll({
            where: {
                id: { [Op.in]: productIds },
                status: 'Available'
            },
            include: [{
                model: User,
                as: 'seller',
                attributes: ['username', 'full_name', 'reputation_score', 'profile_image_url']
            }]
        });

        // Sort products according to the score ranking
        const sortedProducts = productIds
            .map(id => products.find(p => p.id === id))
            .filter(Boolean);

        res.json(sortedProducts);
    } catch (error) {
        console.error('Get Trending Items Error:', error);
        res.status(500).json({ error: 'Failed to fetch trending items' });
    }
};

export const getTrendingProducts = getTrendingItems; // Backward compatibility

export const getTrendingCategories = async (req, res) => {
    try {
        const { limit = 10 } = req.query;

        // Aggregate total popularity of all items grouped by their category
        // Regardless of availability status (include Sold, Reserved, etc.)
        // Formula: SUM(views * 1) + SUM(messages * 3) + SUM(saves * 5) + SUM(buys * 10)
        const trendingQuery = await sequelize.query(`
            SELECT p.category, 
                   COUNT(CASE WHEN ui.interaction_type = 'view' THEN 1 END) as view_count,
                   COUNT(CASE WHEN ui.interaction_type = 'message' THEN 1 END) as message_count,
                   COUNT(CASE WHEN ui.interaction_type = 'save' THEN 1 END) as save_count,
                   COUNT(CASE WHEN ui.interaction_type = 'buy' THEN 1 END) as buy_count,
                   SUM(CASE 
                       WHEN ui.interaction_type = 'view' THEN 1
                       WHEN ui.interaction_type = 'message' THEN 3
                       WHEN ui.interaction_type = 'save' THEN 5
                       WHEN ui.interaction_type = 'buy' THEN 10
                       ELSE 0 
                   END) as score
            FROM "UserInteractions" ui
            JOIN "Products" p ON ui.product_id = p.id
            WHERE ui.interaction_type IN ('view', 'message', 'save', 'buy')
              AND p.category IS NOT NULL
            GROUP BY p.category
            ORDER BY score DESC
            LIMIT :limit
        `, {
            replacements: { limit: parseInt(limit) },
            type: sequelize.QueryTypes.SELECT
        });

        if (trendingQuery.length === 0) {
            // Cold start fallback: return categories ranked by product count
            const fallback = await sequelize.query(`
                SELECT p.category, COUNT(p.id) as product_count, 0 as score
                FROM "Products" p
                WHERE p.category IS NOT NULL
                GROUP BY p.category
                ORDER BY product_count DESC
                LIMIT :limit
            `, {
                replacements: { limit: parseInt(limit) },
                type: sequelize.QueryTypes.SELECT
            });
            return res.json(fallback);
        }

        res.json(trendingQuery);
    } catch (error) {
        console.error('Get Trending Categories Error:', error);
        res.status(500).json({ error: 'Failed to fetch trending categories' });
    }
};
