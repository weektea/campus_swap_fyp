import { UserInteraction, Product, User, Report, Category, SubCategory } from '../models/index.js';
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

        // 1. Fetch user's interactions
        const userInteractions = await UserInteraction.findAll({
            where: { user_id }
        });

        const reportedItems = await Report.findAll({
            where: { reporter_id: user_id },
            attributes: ['product_id']
        });
        const reportedIds = reportedItems.map(r => r.product_id);

        // 2. Cold Start Fallback: If user has no interactions, return global trending items
        if (userInteractions.length === 0) {
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
                
                // Sort products by score order
                const sortedTrending = productIds
                    .map(id => trendingProducts.find(p => p.id === id))
                    .filter(Boolean);
                return res.json(sortedTrending);
            } else {
                // Absolute fallback (newest items)
                const fallback = await Product.findAll({
                    where: {
                        status: 'Available',
                        seller_id: { [Op.ne]: user_id },
                        ...(reportedIds.length > 0 ? { id: { [Op.notIn]: reportedIds } } : {})
                    },
                    include: [{ model: User, as: 'seller', attributes: ['username', 'full_name', 'reputation_score', 'profile_image_url'] }],
                    order: [['createdAt', 'DESC']],
                    limit: 10
                });
                return res.json(fallback);
            }
        }

        // 3. User has history: Implement TF-IDF + Cosine Similarity recommendation
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

        // Preprocess text documents

        const documents = availableProducts.map(p => {
            const catName = p.categoryModel ? p.categoryModel.name : (p.category || '');
            const subcatName = p.subcategoryModel ? p.subcategoryModel.name : '';
            const text = `${p.title} ${p.description} ${catName} ${subcatName}`.toLowerCase();
            const tokens = text.replace(/[^\w\s]/g, ' ').split(/\s+/).filter(t => t.length > 0);
            return {
                id: p.id,
                tokens,
                termFreqs: tokens.reduce((acc, t) => {
                    acc[t] = (acc[t] || 0) + 1;
                    return acc;
                }, {})
            };
        });

        // Compute Document Frequency (DF)
        const df = {};
        documents.forEach(doc => {
            Object.keys(doc.termFreqs).forEach(term => {
                df[term] = (df[term] || 0) + 1;
            });
        });

        const N = documents.length;
        // Compute Inverse Document Frequency (IDF)
        const idf = {};
        Object.keys(df).forEach(term => {
            idf[term] = Math.log(N / (1 + df[term])) + 1;
        });

        // Compute TF-IDF vectors for all products
        const tfIdfVectors = {};
        documents.forEach(doc => {
            const vector = {};
            const totalTokens = doc.tokens.length || 1;
            Object.keys(doc.termFreqs).forEach(term => {
                const tf = doc.termFreqs[term] / totalTokens;
                vector[term] = tf * idf[term];
            });
            tfIdfVectors[doc.id] = vector;
        });

        // Build User Profile Vector
        const userProfile = {};
        userInteractions.forEach(interaction => {
            const vector = tfIdfVectors[interaction.product_id];
            if (vector) {
                const weight = interaction.weight || 1;
                Object.keys(vector).forEach(term => {
                    userProfile[term] = (userProfile[term] || 0) + (vector[term] * weight);
                });
            }
        });

        // Compute magnitude of User Profile
        let userMagnitude = 0;
        Object.keys(userProfile).forEach(term => {
            userMagnitude += userProfile[term] * userProfile[term];
        });
        userMagnitude = Math.sqrt(userMagnitude);

        // Compute Cosine Similarity for each available product
        const similarities = [];
        availableProducts.forEach(p => {
            const vector = tfIdfVectors[p.id];
            if (!vector) return;

            let dotProduct = 0;
            let productMagnitude = 0;

            Object.keys(vector).forEach(term => {
                productMagnitude += vector[term] * vector[term];
                if (userProfile[term]) {
                    dotProduct += userProfile[term] * vector[term];
                }
            });

            productMagnitude = Math.sqrt(productMagnitude);

            let score = 0;
            if (userMagnitude > 0 && productMagnitude > 0) {
                score = dotProduct / (userMagnitude * productMagnitude);
            }

            similarities.push({
                product: p,
                score
            });
        });

        // Sort by similarity score descending
        similarities.sort((a, b) => b.score - a.score);

        // Map to products array
        const recommendedProducts = similarities.slice(0, 10).map(s => s.product);

        res.json(recommendedProducts);
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
