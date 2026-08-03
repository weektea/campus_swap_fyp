import { Product, User, Category, SubCategory, Report } from '../models/index.js';
import { Op } from 'sequelize';

/**
 * GET /api/items/newest
 * Retrieves a list of newest available items with pagination.
 */
export const getNewestItems = async (req, res) => {
    try {
        const limit = parseInt(req.query.limit) || 10;
        const page = parseInt(req.query.page) || 1;
        const offset = req.query.offset ? parseInt(req.query.offset) : (page - 1) * limit;
        const { exclude_reported_by } = req.query;

        const whereClause = {
            status: 'Available'
        };

        // Exclude reported items if requested
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

        const products = await Product.findAll({
            where: whereClause,
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
            ],
            order: [['createdAt', 'DESC']],
            limit: limit,
            offset: offset
        });

        // Format items to ensure both createdAt and created_at are returned
        const formattedItems = products.map(product => {
            const data = product.toJSON();
            // Provide explicit created_at supporting frontend parsers
            data.created_at = product.createdAt;
            return data;
        });

        res.json(formattedItems);
    } catch (error) {
        console.error('Get Newest Items Error:', error);
        res.status(500).json({
            error: 'Failed to fetch newest items',
            details: error.message
        });
    }
};
