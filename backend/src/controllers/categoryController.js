import { Category, SubCategory, Product } from '../models/index.js';
import sequelize from '../config/database.js';

export const getCategories = async (req, res) => {
    try {
        const categories = await Category.findAll({
            include: [{
                model: SubCategory,
                as: 'subcategories',
                attributes: [
                    'id',
                    'name',
                    [
                        sequelize.literal(`(
                            SELECT COUNT(*)::integer
                            FROM "Products" AS p
                            WHERE p.sub_category_id = "subcategories".id
                              AND p.status = 'Available'
                        )`),
                        'product_count'
                    ]
                ]
            }],
            order: [
                ['name', 'ASC'],
                [{ model: SubCategory, as: 'subcategories' }, 'name', 'ASC']
            ]
        });
        res.json(categories);
    } catch (error) {
        console.error('Get Categories Error:', error);
        res.status(500).json({ error: 'Failed to fetch categories' });
    }
};
