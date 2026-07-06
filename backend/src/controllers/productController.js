import { Product, User, Report, Category, SubCategory, ActivityLog } from '../models/index.js';
import { Op } from 'sequelize';
import fs from 'fs';
import FormData from 'form-data';
import axios from 'axios';

const ML_SERVICE_URL = process.env.ML_SERVICE_URL || 'http://localhost:5000';

export const createProduct = async (req, res) => {
    try {
        const { title, description, price, category, sub_category_id, condition, seller_id, image_urls, video_url, type, rental_price_per_day, max_rental_duration, rental_deposit } = req.body;

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
            rental_deposit
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
            whereClause.status = { [Op.or]: ['Available', 'Reserved', 'Sold', 'Removed'] }; // Fetch all valid DB states
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
                where: { reporter_id: exclude_reported_by },
                attributes: ['product_id']
            });
            const reportedIds = reportedItems.map(r => r.product_id);
            if (reportedIds.length > 0) {
                whereClause.id = { [Op.notIn]: reportedIds };
            }
        }

        console.log('----- DEBUG PRODUCTS -----');
        console.log('Query Params:', req.query);
        console.log('Where Clause:', JSON.stringify(whereClause, null, 2));
        console.log('--------------------------');

        // Sorting
        let order = [['createdAt', 'DESC']]; // Default
        const { sort } = req.query;

        if (sort === 'price_asc') {
            order = [['price', 'ASC']];
        } else if (sort === 'price_desc') {
            order = [['price', 'DESC']];
        } else if (sort === 'newest') {
            order = [['createdAt', 'DESC']];
        }

        const products = await Product.findAll({
            where: whereClause,
            include: [
                {
                    model: User,
                    as: 'seller',
                    attributes: ['username', 'full_name', 'email', 'reputation_score', 'total_reviews', 'profile_image_url'],
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

        res.json(products);
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

        await product.update(updates);
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

export const getPriceSuggestion = async (req, res) => {
    try {
        const { category, condition } = req.body;
        
        try {
            console.log('Forwarding price suggestion request to ML service...');
            const response = await axios.post(`${ML_SERVICE_URL}/predict-price`, { category, condition });
            return res.json(response.data);
        } catch (mlErr) {
            console.warn('ML Price Suggestion Service down, using local fallback:', mlErr.message);
        }

        // Fallback Mock algorithmic pricing based on condition standard deviations
        let base = 50.0;
        if (category === 'Electronics') base = 300.0;
        if (category === 'Books') base = 35.0;
        if (category === 'Furniture') base = 80.0;
        if (category === 'Fashion') base = 40.0;

        let multiplier = 1.0;
        if (condition === 'New') multiplier = 1.2;
        if (condition === 'Good' || condition === 'Like New') multiplier = 0.9;
        if (condition === 'Fair') multiplier = 0.6;
        if (condition === 'Poor') multiplier = 0.3;

        const suggested_price = (base * multiplier) + (Math.random() * 10 - 5); // Add slight random variance

        res.json({ estimated_price: Math.max(1, suggested_price).toFixed(2) });
    } catch (error) {
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
