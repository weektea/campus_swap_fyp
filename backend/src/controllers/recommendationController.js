import { UserInteraction, Product, User, Report, Category, SubCategory, Follow, SavedItem } from '../models/index.js';
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

// Get Recommendations (Hybrid Content-Based + KNN Collaborative with A/B Testing)
export const getRecommendations = async (req, res) => {
    try {
        const user_id = req.user ? req.user.id : null;

        // Session interactions (Task 1)
        let sessionProductIds = [];
        if (req.query.session_interactions) {
            sessionProductIds = req.query.session_interactions.split(',').filter(Boolean);
        }
        const headerInteractions = req.headers['x-session-interactions'];
        if (headerInteractions) {
            sessionProductIds = headerInteractions.split(',').filter(Boolean);
        }

        // Fetch reported items to exclude
        let reportedIds = [];
        if (user_id) {
            const reportedItems = await Report.findAll({
                where: { reporter_id: user_id },
                attributes: ['product_id']
            });
            reportedIds = reportedItems.map(r => r.product_id).filter(Boolean);
        }

        // Dynamic Feed Routing Strategy:
        // Model A (ML): Selected IF user has onboarding preference_tags > 0 OR interaction history > 0 OR active session interactions.
        // Model B (Baseline): Selected ONLY IF user is completely new (0 interactions) AND skipped onboarding (no preference tags).
        let userPrefTags = [];
        let userPrimaryIntent = 'browse';
        let userInteractionCount = 0;

        if (user_id) {
            try {
                const uObj = await User.findByPk(user_id, {
                    attributes: ['preference_tags', 'primary_intent']
                });
                if (uObj) {
                    userPrefTags = Array.isArray(uObj.preference_tags) ? uObj.preference_tags : [];
                    userPrimaryIntent = uObj.primary_intent || 'browse';
                }
                userInteractionCount = await UserInteraction.count({ where: { user_id } });
            } catch (uErr) {
                console.error("Failed to query user preferences for dynamic routing:", uErr);
            }
        }

        let chooseModelA = (userPrefTags.length > 0 || userInteractionCount > 0 || sessionProductIds.length > 0);

        if (req.query.ab_variant === 'A') {
            chooseModelA = true;
        } else if (req.query.ab_variant === 'B') {
            chooseModelA = false;
        }

        const ab_variant = chooseModelA ? 'Model_A_Hybrid_ML' : 'Model_B_Baseline';

        // Helper to attach favorite_count / save_count metadata to product JSON objects
        const enrichWithFavoriteCounts = async (productList) => {
            if (!productList || productList.length === 0) return [];
            const pids = productList.map(p => p.id);
            const favoriteCounts = await SavedItem.findAll({
                where: { product_id: { [Op.in]: pids } },
                attributes: ['product_id', [sequelize.fn('COUNT', sequelize.col('saved_item_id')), 'count']],
                group: ['product_id'],
                raw: true
            });
            const countMap = {};
            favoriteCounts.forEach(fc => {
                countMap[fc.product_id] = parseInt(fc.count, 10) || 0;
            });

            return productList.map(p => {
                const json = p.toJSON ? p.toJSON() : { ...p };
                json.favorite_count = countMap[p.id] || 0;
                json.save_count = countMap[p.id] || 0;
                return json;
            });
        };

        // Helper function for 50% Trending / 50% Recency Fallback Mix with Deduplication & Bounds Safeguards
        const getFallbackRecommendations = async () => {
            const trendingQuery = await sequelize.query(`
                SELECT ui.product_id, 
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
                  ${user_id ? 'AND p.seller_id != :user_id' : ''}
                GROUP BY ui.product_id
                ORDER BY score DESC
                LIMIT 5
            `, {
                replacements: user_id ? { user_id } : {},
                type: sequelize.QueryTypes.SELECT
            });

            const trendingProductIds = trendingQuery.map(row => row.product_id).filter(Boolean);

            let trendingProducts = [];
            if (trendingProductIds.length > 0) {
                let whereCond = {
                    id: { [Op.in]: trendingProductIds },
                    status: 'Available',
                    ...(user_id ? { seller_id: { [Op.ne]: user_id } } : {})
                };
                if (reportedIds.length > 0) {
                    whereCond.id = { [Op.in]: trendingProductIds, [Op.notIn]: reportedIds };
                }
                const fetched = await Product.findAll({
                    where: whereCond,
                    include: [{
                        model: User,
                        as: 'seller',
                        attributes: ['username', 'full_name', 'reputation_score', 'profile_image_url']
                    }]
                });
                trendingProducts = trendingProductIds
                    .map(id => fetched.find(p => p.id === id))
                    .filter(Boolean);
            }

            const newestProducts = await Product.findAll({
                where: {
                    status: 'Available',
                    ...(user_id ? { seller_id: { [Op.ne]: user_id } } : {}),
                    ...(reportedIds.length > 0 ? { id: { [Op.notIn]: reportedIds } } : {})
                },
                include: [{ model: User, as: 'seller', attributes: ['username', 'full_name', 'reputation_score', 'profile_image_url'] }],
                order: [['createdAt', 'DESC']],
                limit: 10
            });

            // Interleave 50% Trending + 50% Recency with Deduplication & Bounds Safeguards
            const resultList = [];
            const seenIds = new Set();

            const maxLen = Math.max(trendingProducts.length, newestProducts.length);
            for (let i = 0; i < maxLen; i++) {
                if (resultList.length >= 10) break;

                if (i < trendingProducts.length && trendingProducts[i]) {
                    const item = trendingProducts[i];
                    if (!seenIds.has(item.id)) {
                        seenIds.add(item.id);
                        resultList.push(item);
                    }
                }

                if (resultList.length >= 10) break;

                if (i < newestProducts.length && newestProducts[i]) {
                    const item = newestProducts[i];
                    if (!seenIds.has(item.id)) {
                        seenIds.add(item.id);
                        resultList.push(item);
                    }
                }
            }

            return enrichWithFavoriteCounts(resultList);
        };

        // If Model B (Baseline), return traditional popular/trending list immediately
        if (!chooseModelA) {
            const data = await getFallbackRecommendations();
            return res.json({ ab_variant, data });
        }

        // --- Model A (Active ML) Flow ---
        
        // Fetch base interactions
        let userInteractions = [];
        if (user_id) {
            const userInteractionsDb = await UserInteraction.findAll({
                where: { user_id }
            });
            userInteractions = userInteractionsDb.map(i => ({
                user_id: i.user_id,
                product_id: i.product_id,
                weight: parseFloat(i.weight) || 1.0
            }));
        }

        // Dynamically merge session interactions (weight 1.0)
        sessionProductIds.forEach(pid => {
            const exists = userInteractions.some(i => i.product_id === pid);
            if (!exists) {
                userInteractions.push({
                    user_id: user_id || 'guest',
                    product_id: pid,
                    weight: 1.0
                });
            }
        });

        // Re-use user preference tags & primary intent if already queried
        if (user_id && userPrefTags.length === 0) {
            try {
                const uObj = await User.findByPk(user_id, {
                    attributes: ['preference_tags', 'primary_intent']
                });
                if (uObj) {
                    userPrefTags = Array.isArray(uObj.preference_tags) ? uObj.preference_tags : [];
                    userPrimaryIntent = uObj.primary_intent || 'browse';
                }
            } catch (uErr) {
                console.error("Failed to query user preferences for ML:", uErr);
            }
        }

        // Cold Start Fallback: If user has absolutely no interactions (db + session) AND no preference tags, return fallback
        if (userInteractions.length === 0 && userPrefTags.length === 0) {
            const fallbackList = await getFallbackRecommendations();
            return res.json({ ab_variant, data: fallbackList });
        }

        // Fetch all available products (excluding own and reported)
        const availableProducts = await Product.findAll({
            where: {
                status: 'Available',
                ...(user_id ? { seller_id: { [Op.ne]: user_id } } : {}),
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
            return res.json({ ab_variant, data: [] });
        }

        // Fetch all interactions for KNN CF matrix building
        const allInteractionsFromDb = await UserInteraction.findAll({
            attributes: ['user_id', 'product_id', 'weight']
        });
        
        let allInteractions = allInteractionsFromDb.map(i => ({
            user_id: i.user_id,
            product_id: i.product_id,
            weight: parseFloat(i.weight) || 1.0
        }));

        // Inject current guest or temporary session interactions into matrix
        if (!user_id || sessionProductIds.length > 0) {
            userInteractions.forEach(ui => {
                const exists = allInteractions.some(i => i.user_id === ui.user_id && i.product_id === ui.product_id);
                if (!exists) {
                    allInteractions.push(ui);
                }
            });
        }

        // Fetch user followed seller list & social graph network interactions for ML personalization boosting
        let followedSellerIds = [];
        let followedInteractedProductIds = [];
        if (user_id) {
            try {
                const follows = await Follow.findAll({
                    where: { follower_id: user_id },
                    attributes: ['following_id']
                });
                followedSellerIds = follows.map(f => f.following_id);

                // Performance Safeguards for Social Graph Querying:
                // 1. Time-Bound: strictly within the last 30 days
                // 2. High-Intent Only: 'save', 'message', 'buy' (exclude generic 'view')
                // 3. Hard Cap: Top 100 most recent unique product IDs
                if (followedSellerIds.length > 0) {
                    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
                    const networkInteractions = await UserInteraction.findAll({
                        where: {
                            user_id: { [Op.in]: followedSellerIds },
                            interaction_type: ['save', 'message', 'buy'],
                            createdAt: { [Op.gte]: thirtyDaysAgo }
                        },
                        attributes: ['product_id', 'createdAt'],
                        order: [['createdAt', 'DESC']],
                        limit: 200
                    });

                    const uniquePids = [];
                    for (const row of networkInteractions) {
                        if (row.product_id && !uniquePids.includes(row.product_id)) {
                            uniquePids.push(row.product_id);
                        }
                        if (uniquePids.length >= 100) break; // Hard Cap at 100
                    }
                    followedInteractedProductIds = uniquePids;
                }
            } catch (err) {
                console.error("Failed to query user follows/social graph for ML boosting:", err);
            }
        }

        const productsPayload = availableProducts.map(p => ({
            id: p.id,
            title: p.title,
            description: p.description || '',
            category: p.categoryModel ? p.categoryModel.name : (p.category || ''),
            subcategory: p.subcategoryModel ? p.subcategoryModel.name : '',
            seller_id: p.seller_id
        }));

        let recommendedIds = [];
        try {
            const pythonRes = await axios.post(`${ML_SERVICE_URL}/api/recommend/hybrid`, {
                user_id: user_id || 'guest',
                interactions: userInteractions, // send user profile interactions
                products: productsPayload,
                followed_seller_ids: followedSellerIds,
                followed_interacted_product_ids: followedInteractedProductIds,
                preference_tags: userPrefTags,
                primary_intent: userPrimaryIntent
            }, { timeout: 4000 });

            recommendedIds = pythonRes.data.recommended_product_ids || [];
        } catch (pyError) {
            console.error('Python ML recommendation service call failed, falling back to database list:', pyError.message);
            const fallbackList = await getFallbackRecommendations();
            return res.json({ ab_variant, data: fallbackList });
        }

        if (recommendedIds.length === 0) {
            const fallbackList = await getFallbackRecommendations();
            return res.json({ ab_variant, data: fallbackList });
        }

        // Fetch recommendations from DB and maintain exact sorting order
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

        const enrichedData = await enrichWithFavoriteCounts(sortedRecommendations);

        res.json({ ab_variant, data: enrichedData });
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
