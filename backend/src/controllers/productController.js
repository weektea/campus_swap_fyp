import { Product, User } from '../models/index.js';
import { Op } from 'sequelize';

export const createProduct = async (req, res) => {
    try {
        const { title, description, price, category, condition, seller_id, image_urls, type, rental_price_per_day, max_rental_duration } = req.body;

        // Basic validation
        if (!title || !seller_id || (!price && !rental_price_per_day)) {
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
        const { search, category, seller_id, min_price, max_price } = req.query;

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
            whereClause.title = { [Op.like]: `%${search}%` }; // SQLite uses 'like' usually, Postgres 'iLike'
        }

        if (category && category !== 'All') {
            whereClause.category = category;
        }

        if (min_price) {
            whereClause.price = { ...whereClause.price, [Op.gte]: min_price };
        }
        if (max_price) {
            whereClause.price = { ...whereClause.price, [Op.lte]: max_price };
        }

        const products = await Product.findAll({
            where: whereClause,
            include: [{
                model: User,
                as: 'seller',
                attributes: ['full_name', 'email', 'reputation']
            }],
            order: [['createdAt', 'DESC']]
        });

        res.json(products);
    } catch (error) {
        console.error('Get Products Error:', error);
        res.status(500).json({ error: 'Failed to fetch products' });
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

        await product.destroy();
        res.json({ message: 'Product deleted successfully' });
    } catch (error) {
        console.error('Delete Product Error:', error);
        res.status(500).json({ error: 'Failed to delete product' });
    }
};
