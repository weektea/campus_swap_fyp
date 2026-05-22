import { Product, User, Report } from '../models/index.js';
import { Op } from 'sequelize';

export const createProduct = async (req, res) => {
    try {
        const { title, description, price, category, condition, seller_id, image_urls, video_url, type, rental_price_per_day, max_rental_duration, rental_deposit } = req.body;

        // Basic validation
        if (!title || !seller_id || (price === undefined && !rental_price_per_day)) {
            return res.status(400).json({ error: 'Missing required fields' });
        }

        // Create Product
        const newProduct = await Product.create({
            title,
            description,
            price: price || 0, // 0 if rental only
            category,
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

        res.status(201).json(newProduct);
    } catch (error) {
        console.error('Create Product Error:', error);
        res.status(500).json({ error: 'Failed to create product' });
    }
};

export const getAllProducts = async (req, res) => {
    try {
        // Extract query params
        const { search, category, seller_id, min_price, max_price, condition, type } = req.query;

        const whereClause = {
            status: 'Available' // Only show available items by default, unless seller listing
        };

        if (seller_id) {
            whereClause.status = { [Op.or]: ['Available', 'Reserved', 'Sold', 'Removed'] }; // Fetch all valid DB states
            whereClause.seller_id = seller_id;
        }

        if (search) {
            whereClause.title = { [Op.iLike]: `%${search}%` }; // Postgres uses iLike for case-insensitive
        }

        if (category && category !== 'All') {
            whereClause.category = category;
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
        if (exclude_reported_by) {
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
            include: [{
                model: User,
                as: 'seller',
                attributes: ['full_name', 'email', 'reputation_score', 'total_reviews'],
                required: false // Force LEFT JOIN
            }],
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
        const { violation_type, description } = req.body;
        const reporter_id = req.user.id;

        const product = await Product.findByPk(id);
        if (!product) return res.status(404).json({ error: 'Product not found' });

        // UC11 Constraint: Max 3 reports per 10 mins spam limit
        const tenMinsAgo = new Date(Date.now() - 10 * 60 * 1000);
        const recentReports = await Report.count({
            where: {
                reporter_id,
                createdAt: { [Op.gte]: tenMinsAgo }
            }
        });

        if (recentReports >= 3) {
            return res.status(429).json({ error: 'Spam limit reached. Max 3 reports per 10 minutes allowed.' });
        }

        const newReport = await Report.create({
            reporter_id,
            product_id: product.id,
            violation_type,
            description,
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
        // In a real system, this would forward req.file to the Python Flask ML API.
        // For the presentation demo, we return a high-confidence prediction.
        
        // Simulating latency
        await new Promise(resolve => setTimeout(resolve, 1500)); 

        const categories = {
            'Electronics': ['Smartphones', 'Laptops', 'Audio'],
            'Books': ['Textbooks', 'Novels', 'Reference'],
            'Fashion': ['Clothing', 'Shoes'],
            'Furniture': ['Chairs', 'Tables'],
        };
        
        const catKeys = Object.keys(categories);
        const randCat = catKeys[Math.floor(Math.random() * catKeys.length)];
        const randSubCat = categories[randCat][Math.floor(Math.random() * categories[randCat].length)];
        const confidence = 0.85 + (Math.random() * 0.14); // 85% to 99%

        res.json({
            category: randCat,
            sub_category: randSubCat,
            confidence: confidence
        });
    } catch (error) {
        res.status(500).json({ error: 'ML Classification Failed' });
    }
};

export const getPriceSuggestion = async (req, res) => {
    try {
        const { category, condition } = req.body;
        // Mock algorithmic pricing based on condition standard deviations
        await new Promise(resolve => setTimeout(resolve, 800));

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
        const { title, category, condition, type } = req.body;
        await new Promise(resolve => setTimeout(resolve, 1500));

        const action = type === 'Rent' ? 'renting out' : 'selling';
        const conditionDesc = condition ? `It is in ${condition} condition and works perfectly.` : 'It is well maintained.';
        
        const description = `This is a pre-loved ${title || 'item'} that I am ${action}. ${conditionDesc} Perfect for anyone looking for affordable ${category || 'items'} on campus. Feel free to chat with me for more details or to arrange a safe meetup!`;

        res.json({ description });
    } catch (error) {
         res.status(500).json({ error: 'LLM Generation Failed' });
    }
};
