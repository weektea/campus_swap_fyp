import { Category, SubCategory, Product } from '../models/index.js';
import sequelize from '../config/database.js';

/**
 * Retrieves all categories and their associated subcategories, along with the counts of active products.
 *
 * @param {import('express').Request} req - The Express request object.
 * @param {import('express').Response} res - The Express response object.
 * @returns {Promise<void>} - Responds with a JSON array of categories.
 * @throws {Error} - Responds with HTTP 500 if the database query fails.
 */
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

/**
 * Retrieves a flat array of all active subcategories in the database.
 */
export const getSubcategories = async (req, res) => {
    try {
        const subcategories = await SubCategory.findAll({
            attributes: ['id', 'name', 'category_id', 'carbon_conversion_factor'],
            include: [{
                model: Category,
                as: 'categoryModel',
                attributes: ['name']
            }],
            order: [['name', 'ASC']]
        });
        const formatted = subcategories.map(sub => ({
            id: sub.id,
            name: sub.name,
            category_id: sub.category_id,
            category_name: sub.categoryModel ? sub.categoryModel.name : '',
            carbon_conversion_factor: sub.carbon_conversion_factor
        }));
        res.json(formatted);
    } catch (error) {
        console.error('Get Subcategories Error:', error);
        res.status(500).json({ error: 'Failed to fetch subcategories' });
    }
};
