import { Product, User } from '../models/index.js';
import { Op } from 'sequelize';

export const createProduct = async (req, res) => {
    try {
        const { title, description, price, category, condition, seller_id, image_urls, type, rental_price_per_day, max_rental_duration } = req.body;

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
            status: 'Available',
            type: type || 'Sale',
            rental_price_per_day,
            max_rental_duration
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
        const { search, category, seller_id, min_price, max_price, condition } = req.query;

        const whereClause = {
            status: 'Available' // Only show available items by default, unless seller listing
        };

        // If listing specifically for a seller, maybe show Sold items too? 
        // For 'My Listings' page, usually we want to see everything.
        if (seller_id) {
            whereClause.status = { [Op.or]: ['Available', 'Sold', 'Rented'] };
            whereClause.seller_id = seller_id;
        }

        if (search) {
            whereClause.title = { [Op.iLike]: `%${search}%` }; // Postgres uses iLike for case-insensitive
        }

        if (category && category !== 'All') {
            whereClause.category = category;
        }

        if (min_price) {
            whereClause.price = { ...whereClause.price, [Op.gte]: parseFloat(min_price) };
        }
        if (max_price) {
            whereClause.price = { ...whereClause.price, [Op.lte]: parseFloat(max_price) };
        }
        if (condition) {
            whereClause.condition = condition;
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
                attributes: ['full_name', 'email', 'reputation_score'],
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

        await product.destroy();
        res.json({ message: 'Product deleted successfully' });
    } catch (error) {
        console.error('Delete Product Error:', error);
        res.status(500).json({ error: 'Failed to delete product' });
    }
};
