import { Product, User, Report, Category, SubCategory, ActivityLog, SavedItem, Follow, Transaction } from '../models/index.js';
import { createNotification } from './notificationController.js';
import { Op } from 'sequelize';
import sequelize from '../config/database.js';
import fs from 'fs';
import FormData from 'form-data';
import axios from 'axios';

const ML_SERVICE_URL = process.env.ML_SERVICE_URL || 'http://localhost:5000';

export const createProduct = async (req, res) => {
    try {
        const { title, description, price, category, sub_category_id, condition, seller_id,
        image_urls, video_url, type, rental_price_per_day, max_rental_duration, rental_deposit, accepted_payment_methods } = req.body;

        // Basic validation
        if (!title || !seller_id || (price === undefined && !rental_price_per_day)) {
            return res.status(400).json({ error: 'Missing required fields' });
        }

        // Look up category UUID
        let categoryId = null;
        if (category) {
            const catObj = await Category.findOne({ where: { name: category } });
            if (catObj) {
                categoryId = catObj.id;
            }
        }

        // Look up subcategory UUID
        let subCategoryId = null;
        if (sub_category_id) {
            const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
            if (uuidRegex.test(sub_category_id)) {
                subCategoryId = sub_category_id;
            } else {
                const subCatObj = await SubCategory.findOne({
                    where: {
                        name: sub_category_id,
                        ...(categoryId ? { category_id: categoryId } : {})
                    }
                });
                if (subCatObj) {
                    subCategoryId = subCatObj.id;
                }
            }
        }

        // Create Product
        const newProduct = await Product.create({
            title,
            description: description || '', // Default to empty string, not null (allowNull: false)
            price: price || 0, // 0 if rental only
            category,
            category_id: categoryId,
            sub_category_id: subCategoryId,
            condition,
            seller_id,
            image_urls: image_urls || [],
            video_url,
            status: 'Available',
            type: type || 'Sale',
            rental_price_per_day,
            max_rental_duration,
            rental_deposit,
            accepted_payment_methods: (accepted_payment_methods && Array.isArray
            (accepted_payment_methods) && accepted_payment_methods.length > 0) ? accepted_payment_methods : ['Cash']
        });

        // Background task for ML Continuous Learning
        if (image_urls && image_urls.length > 0) {
            try {
                // Map frontend URL to backend local file path
                // e.g. "/uploads/image-123.jpg" -> "uploads/image-123.jpg"
                const localImagePath = image_urls[0].replace(/^\//, ''); 
                
                if (fs.existsSync(localImagePath)) {
                    const formData = new FormData();
                    formData.append('file', fs.createReadStream(localImagePath));
                    
                    // Format correctly for ML: Category___SubCategory
                    const mlCategory = sub_category_id ? `${category}___${sub_category_id}` : `${category}___Others`;
                    formData.append('correct_category', mlCategory);

                    axios.post(`${ML_SERVICE_URL}/feedback/image`, formData, {
                        headers: formData.getHeaders(),
                    }).catch(err => console.error("ML Feedback Background Task Failed:", err.message));
                }
            } catch(e) {
                console.error("Failed to prepare ML feedback:", e);
            }
        }

        // Log product listing creation
        try {
            await ActivityLog.create({
                user_id: seller_id,
                action: 'ITEM_LISTED'
            });
        } catch (e) {
            console.error("Failed to log product listing:", e.message);
        }

        // Trigger Dynamic New Listing Notifications to Followers
        try {
            const seller = await User.findByPk(seller_id);
            const sellerName = seller ? (seller.username || seller.full_name) : 'A seller';
            
            const followers = await Follow.findAll({
                where: { following_id: seller_id }
            });

            for (const f of followers) {
                if (f.follower_id !== seller_id) {
                    await createNotification(
                        f.follower_id,
                        "New Listing Alert!",
                        `${sellerName} just listed a new item: ${newProduct.title}`,
                        'NEW_SELLER_ITEM',
                        newProduct.id
                    );
                }
            }
        } catch (notifierErr) {
            console.error("Failed to dispatch new listing notifications to followers:", notifierErr);
        }

        res.status(201).json(newProduct);
    } catch (error) {
        console.error('Create Product Error:', error);
        res.status(500).json({ error: 'Failed to create product' });
    }
};

export const getAllProducts = async (req, res) => {
    try {
        // Extract query params
        const { search, category, sub_category_id, seller_id, min_price, max_price, condition, type } = req.query;

        const whereClause = {
            status: 'Available' // Only show available items by default, unless seller listing
        };

        if (seller_id) {
            whereClause.status = { [Op.or]: ['Available', 'Reserved', 'Sold', 'Removed', 'Suspended'] }; // Fetch all valid DB states including Suspended
            whereClause.seller_id = seller_id;
        }

        if (search) {
            whereClause[Op.or] = [
                { title: { [Op.iLike]: `%${search}%` } },
                { description: { [Op.iLike]: `%${search}%` } },
                { '$categoryModel.name$': { [Op.iLike]: `%${search}%` } },
                { '$subcategoryModel.name$': { [Op.iLike]: `%${search}%` } }
            ];
        }

        if (category && category !== 'All') {
            whereClause.category = category;
        }

        if (sub_category_id) {
            whereClause.sub_category_id = sub_category_id;
        }

        // Price Filtering logic to handle both Sale and Rent types
        if (min_price || max_price) {
            // By default, assume we are filtering on `price` (Sale items)
            let priceField = 'price';
            
            if (type === 'Rent') {
                priceField = 'rental_price_per_day';
            }

            whereClause[priceField] = {};
            if (min_price) {
                whereClause[priceField][Op.gte] = parseFloat(min_price);
            }
            if (max_price) {
                whereClause[priceField][Op.lte] = parseFloat(max_price);
            }
        }
        if (condition) {
            whereClause.condition = condition;
        }

        if (type && type !== 'All') {
            whereClause.type = type; // Support filtering by Sale/Rent from Flutter UI
        }

        // Feature: Hide reported items
        const { exclude_reported_by } = req.query;
        const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
        if (exclude_reported_by && uuidRegex.test(exclude_reported_by)) {
            const reportedItems = await Report.findAll({
                where: {
                    reporter_id: exclude_reported_by,
                    product_id: { [Op.ne]: null }
                },
                attributes: ['product_id']
            });
            const reportedIds = reportedItems.map(r => r.product_id).filter(Boolean);
            if (reportedIds.length > 0) {
                whereClause.id = { [Op.notIn]: reportedIds };
            }
        }



        // Sorting
        let order = [['createdAt', 'DESC']]; // Default
        const { sort } = req.query;

        if (sort === 'price_asc') {
            order = [['price', 'ASC']];
        } else if (sort === 'price_desc') {
            order = [['price', 'DESC']];
        } else if (sort === 'newest') {
            order = [['createdAt', 'DESC']];
        } else if (sort === 'popular') {
            order = [
                [
                    sequelize.literal(`(
                        SELECT COALESCE(SUM(CASE 
                            WHEN ui.interaction_type = 'view' THEN 1
                            WHEN ui.interaction_type = 'message' THEN 3
                            WHEN ui.interaction_type = 'save' THEN 5
                            ELSE 0 END), 0)
                        FROM "UserInteractions" AS ui
                        WHERE ui.product_id = "Product"."id"
                    )`),
                    'DESC'
                ],
                ['createdAt', 'DESC']
            ];
        }


        const products = await Product.findAll({
            where: whereClause,
            include: [
                {
                    model: User,
                    as: 'seller',
                    attributes: ['id', 'username', 'full_name', 'email', 'reputation_score', 'total_reviews', 'profile_image_url', 'is_active', 'is_verified'],
                    required: false // Force LEFT JOIN
                },
                {
                    model: Category,
                    as: 'categoryModel',
                    attributes: ['id', 'name'],
                    required: false
                },
                {
                    model: SubCategory,
                    as: 'subcategoryModel',
                    attributes: ['id', 'name'],
                    required: false
                }
            ],
            order: order
        });

        // Enrich with favorite_count
        const productIds = products.map(p => p.id);
        const favoriteCounts = await SavedItem.findAll({
            where: { product_id: { [Op.in]: productIds } },
            attributes: ['product_id', [sequelize.fn('COUNT', sequelize.col('saved_item_id')), 'count']],
            group: ['product_id'],
            raw: true
        });
        const countMap = {};
        favoriteCounts.forEach(fc => {
            countMap[fc.product_id] = parseInt(fc.count, 10) || 0;
        });

        const enrichedProducts = products.map(p => {
            const json = p.toJSON();
            json.favorite_count = countMap[p.id] || 0;
            json.save_count = countMap[p.id] || 0;
            return json;
        });

        res.set('X-Total-Count', enrichedProducts.length);
        res.json(enrichedProducts);
    } catch (error) {
        console.error('Get Products Error:', error);
        res.status(500).json({
            error: 'Failed to fetch products',
            details: error.message,
            stack: error.stack
        });
    }
};

// Update Product
export const updateProduct = async (req, res) => {
    try {
        const { id } = req.params;
        const updates = req.body;
        const product = await Product.findByPk(id);

        if (!product) {
            return res.status(404).json({ error: 'Product not found' });
        }

        // Security Check
        if (product.seller_id !== req.user.id && req.user.role !== 'admin') {
            return res.status(403).json({ error: 'Access denied' });
        }

        // UC09 Constraint: Prevent updating active orders, removed, or suspended items
        if (['Reserved', 'Sold', 'Removed', 'Suspended'].includes(product.status)) {
            return res.status(400).json({ error: `Cannot update a listing that is currently ${product.status}` });
        }

        // Handle category / subcategory lookup in updates
        if (updates.category) {
            const catObj = await Category.findOne({ where: { name: updates.category } });
            if (catObj) {
                updates.category_id = catObj.id;
            }
        }
        if (updates.sub_category_id) {
            const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
            if (!uuidRegex.test(updates.sub_category_id)) {
                const catId = updates.category_id || product.category_id;
                const subCatObj = await SubCategory.findOne({
                    where: {
                        name: updates.sub_category_id,
                        ...(catId ? { category_id: catId } : {})
                    }
                });
                if (subCatObj) {
                    updates.sub_category_id = subCatObj.id;
                }
            }
        }

        const oldPrice = parseFloat(product.price || 0);
        const newPrice = updates.price !== undefined ? parseFloat(updates.price) : null;
        const oldRentalPrice = parseFloat(product.rental_price_per_day || 0);
        const newRentalPrice = updates.rental_price_per_day !== undefined ? parseFloat(updates.rental_price_per_day) : null;

        await product.update(updates);

        const isPriceDropped = (newPrice !== null && newPrice < oldPrice) || 
                               (newRentalPrice !== null && newRentalPrice < oldRentalPrice);

        if (isPriceDropped) {
            try {
                const savedItems = await SavedItem.findAll({
                    where: { product_id: product.id }
                });
                const displayPrice = newPrice !== null ? newPrice : newRentalPrice;
                for (const item of savedItems) {
                    if (item.user_id !== product.seller_id) {
                        await createNotification(
                            item.user_id,
                            "Price Drop Alert!",
                            `Price Drop Alert! ${product.title} is now RM ${displayPrice}!`,
                            'PRICE_DROP',
                            product.id
                        );
                    }
                }
            } catch (err) {
                console.error('Failed to trigger price drop notifications:', err);
            }
        }

        res.json(product);
    } catch (error) {
        console.error('Update Product Error:', error);
        res.status(500).json({ error: 'Failed to update product' });
    }
};

// Delete Product
export const deleteProduct = async (req, res) => {
    try {
        const { id } = req.params;
        const product = await Product.findByPk(id);

        if (!product) {
            return res.status(404).json({ error: 'Product not found' });
        }

        // Security Check: Ensure requester is the seller or an admin
        // req.user is populated by authenticateToken middleware
        if (product.seller_id !== req.user.id && req.user.role !== 'admin') {
            return res.status(403).json({ error: 'Access denied. You can only delete your own listings.' });
        }

        // UC10 Constraint: Prevent deleting if an active transaction is ongoing (Reserved)
        if (['Reserved', 'Sold'].includes(product.status) && req.user.role !== 'admin') {
            return res.status(400).json({ error: `Cannot remove listing. It is currently locked in ${product.status} state.` });
        }

        await product.destroy();
        res.json({ message: 'Product deleted successfully' });
    } catch (error) {
        console.error('Delete Product Error:', error);
        res.status(500).json({ error: 'Failed to delete product' });
    }
};

// Report Product (UC11)
export const reportProduct = async (req, res) => {
    try {
        const { id } = req.params;
        const { violation_type, description, evidence_urls } = req.body;
        const reporter_id = req.user.id;

        const product = await Product.findByPk(id);
        if (!product) return res.status(404).json({ error: 'Product not found' });

        // Intercept self-report
        if (product.seller_id === reporter_id) {
            return res.status(400).json({ error: 'You cannot report your own listing' });
        }

        // UC11 Constraint: Max 3 reports per 10 mins spam limit
        const tenMinsAgo = new Date(Date.now() - 10 * 60 * 1000);
        const recentReports = await Report.count({
            where: {
                reporter_id,
                createdAt: { [Op.gte]: tenMinsAgo }
            }
        });

        if (recentReports >= 3) {
            return res.status(429).json({ error: 'You are submitting reports too quickly' });
        }

        const newReport = await Report.create({
            reporter_id,
            product_id: product.id,
            violation_type,
            description,
            evidence_urls: evidence_urls || [],
            status: 'Pending'
        });

        res.status(201).json({ message: 'Product reported successfully. It will be hidden from your view.', report: newReport });
    } catch (error) {
        console.error('Report Product Error:', error);
        res.status(500).json({ error: 'Failed to report product' });
    }
};

// ==========================================
// ML MICROSERVICE PRESENTATION MOCKS (FYP)
// ==========================================

export const classifyImage = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No image uploaded' });
        }

        const formData = new FormData();
        formData.append('file', fs.createReadStream(req.file.path), req.file.originalname);

        const response = await axios.post(`${ML_SERVICE_URL}/predict/image`, formData, {
            headers: formData.getHeaders(),
        });

        // Clean up the uploaded file safely
        try {
            if (fs.existsSync(req.file.path)) {
                fs.unlinkSync(req.file.path);
            }
        } catch (unlinkErr) {
            console.warn('Failed to clean up file after classification:', unlinkErr.message);
        }

        res.json(response.data);
    } catch (error) {
        console.error('ML Classification Failed:', error.message);
        try {
            if (req.file && fs.existsSync(req.file.path)) {
                fs.unlinkSync(req.file.path);
            }
        } catch (unlinkErr) {
            console.warn('Failed to clean up file on ML failure (EBUSY expected on Windows):', unlinkErr.message);
        }

        
        // Fallback to Others if ML server is down
        res.json({
            category: 'Others',
            sub_category: 'Others',
            confidence: 0.0
        });
    }
};

export const getProductById = async (req, res) => {
    try {
        const { id } = req.params;
        const product = await Product.findByPk(id, {
            include: [
                {
                    model: User,
                    as: 'seller',
                    attributes: ['id', 'username', 'full_name', 'email', 'reputation_score', 'total_reviews', 'profile_image_url', 'is_active', 'is_verified'],
                    required: false
                },
                {
                    model: Category,
                    as: 'categoryModel',
                    attributes: ['id', 'name'],
                    required: false
                },
                {
                    model: SubCategory,
                    as: 'subcategoryModel',
                    attributes: ['id', 'name'],
                    required: false
                }
            ]
        });
        if (!product) {
            return res.status(404).json({ error: 'Product not found' });
        }
        const prodObj = product.toJSON();
        if (prodObj.seller && prodObj.seller.id) {
            const sellerCompletedCount = await Transaction.count({
                where: {
                    [Op.or]: [{ buyer_id: prodObj.seller.id }, { seller_id: prodObj.seller.id }],
                    status: 'Completed'
                }
            });
            prodObj.seller.completed_transactions_count = sellerCompletedCount;
            const score = parseFloat(prodObj.seller.reputation_score || 5.0);
            if (sellerCompletedCount === 0) {
                prodObj.seller.reputation_level = "🌱 New Member";
            } else if (score >= 4.5) {
                prodObj.seller.reputation_level = "🏆 Exemplary Trader";
            } else if (score >= 3.0) {
                prodObj.seller.reputation_level = "⭐ Average Trader";
            } else {
                prodObj.seller.reputation_level = "⛔ Poor Rating";
            }
        }
        
        const favCount = await SavedItem.count({ where: { product_id: id } });
        prodObj.favorite_count = favCount;
        prodObj.save_count = favCount;

        res.json(prodObj);
    } catch (error) {
        console.error('Get Product By Id Error:', error);
        res.status(500).json({ error: 'Failed to fetch product details' });
    }
};

export const getPriceSuggestion = async (req, res) => {
    try {
        const { original_price, months_used, condition, subcategory_id, sub_category_id, category } = req.body;
        const subcatId = sub_category_id || subcategory_id;
        
        try {
            console.log('Forwarding price suggestion request to ML service...');
            const response = await axios.post(`${ML_SERVICE_URL}/api/ml/suggest-price`, {
                original_price: parseFloat(original_price || 0),
                months_used: parseFloat(months_used || 0),
                condition: condition || 'Good',
                subcategory_id: subcatId
            });
            const data = response.data;
            // Backwards compatibility: add estimated_price
            data.estimated_price = data.suggested_price;
            return res.json(data);
        } catch (mlErr) {
            console.warn('ML Price Suggestion Service down, using local fallback:', mlErr.message);
        }

        // Local JS Fallback Algorithm
        const price = parseFloat(original_price || 100);
        const months = parseFloat(months_used || 0);
        
        let conditionFactor = 0.70;
        const condKey = (condition || 'Good').toLowerCase().trim();
        if (condKey === 'new' || condKey === 'brand new') conditionFactor = 1.0;
        else if (condKey === 'like new') conditionFactor = 0.85;
        else if (condKey === 'good') conditionFactor = 0.70;
        else if (condKey === 'fair') conditionFactor = 0.50;
        else if (condKey === 'poor') conditionFactor = 0.30;

        const ageDecay = Math.min(0.02 * months, 0.60);
        const depreciated = price * conditionFactor * (1.0 - ageDecay);
        const suggested = Math.max(1, depreciated);
        const min_price = suggested * 0.90;
        const max_price = suggested * 1.10;

        const suggested_rental_price = Math.max(1, suggested * 0.015);
        const min_rental_price = Math.max(1, suggested * 0.010);
        const max_rental_price = Math.max(1, suggested * 0.025);
        const suggested_deposit = Math.max(5, suggested * 0.30);

        res.json({
            suggested_price: parseFloat(suggested.toFixed(2)),
            min_price: parseFloat(min_price.toFixed(2)),
            max_price: parseFloat(max_price.toFixed(2)),
            suggested_rental_price: parseFloat(suggested_rental_price.toFixed(2)),
            min_rental_price: parseFloat(min_rental_price.toFixed(2)),
            max_rental_price: parseFloat(max_rental_price.toFixed(2)),
            suggested_deposit: parseFloat(suggested_deposit.toFixed(2)),
            estimated_price: parseFloat(suggested.toFixed(2)),
            note: "Calculated using local depreciation fallback (ML service unavailable)."
        });
    } catch (error) {
        console.error('Price suggestion failed:', error);
        res.status(500).json({ error: 'ML Price Suggestion Failed' });
    }
};

export const generateDescription = async (req, res) => {
    try {
        const { title, category, condition, type, price, location } = req.body;
        
        try {
            console.log('Forwarding description generation request to ML service...');
            const response = await axios.post(`${ML_SERVICE_URL}/generate-description`, { title, category, condition, type, price, location });
            return res.json(response.data);
        } catch (mlErr) {
            console.warn('ML Description Service down, using local fallback:', mlErr.message);
        }

        const action = type === 'Rent' ? 'renting out' : 'selling';
        const conditionDesc = condition ? `It is in ${condition} condition and works perfectly.` : 'It is well maintained.';
        
        const description = `This is a pre-loved ${title || 'item'} that I am ${action}. ${conditionDesc} Perfect for anyone looking for affordable ${category || 'items'} on campus. Feel free to chat with me for more details or to arrange a safe meetup!`;

        res.json({ description });
    } catch (error) {
         res.status(500).json({ error: 'LLM Generation Failed' });
    }
};
