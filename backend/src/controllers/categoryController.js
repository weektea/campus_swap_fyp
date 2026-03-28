import { Category, SubCategory } from '../models/index.js';

export const getCategories = async (req, res) => {
    try {
        const categories = await Category.findAll({
            include: [{
                model: SubCategory,
                as: 'subcategories',
                attributes: ['id', 'name']
            }],
            order: [['name', 'ASC']]
        });
        res.json(categories);
    } catch (error) {
        console.error('Get Categories Error:', error);
        res.status(500).json({ error: 'Failed to fetch categories' });
    }
};
