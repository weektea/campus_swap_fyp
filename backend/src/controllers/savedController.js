import { SavedItem, Product, User, Report } from '../models/index.js';

// Toggle Save (Like/Unlike)
export const toggleSave = async (req, res) => {
    try {
        const user_id = req.user.id;
        const { product_id } = req.body;

        if (!product_id) {
            return res.status(400).json({ error: 'Missing product_id' });
        }

        const existing = await SavedItem.findOne({ where: { user_id, product_id } });

        if (existing) {
            await existing.destroy();
            return res.json({ message: 'Removed from saved items', isSaved: false });
        } else {
            await SavedItem.create({ user_id, product_id });
            return res.json({ message: 'Added to saved items', isSaved: true });
        }
    } catch (error) {
        console.error('Toggle Save Error:', error);
        res.status(500).json({ error: 'Failed to toggle save' });
    }
};

// Get User's Saved Items
export const getSavedItems = async (req, res) => {
    try {
        const user_id = req.user.id; // Secure from token

        // Get reported items to exclude
        const reportedItems = await Report.findAll({
            where: { reporter_id: user_id },
            attributes: ['product_id']
        });
        const reportedIds = reportedItems.map(r => r.product_id);

        const savedItems = await SavedItem.findAll({
            where: { user_id },
            include: [{
                model: Product,
                as: 'product',
                include: [{ model: User, as: 'seller', attributes: ['username', 'full_name'] }]
            }]
        });

        const products = savedItems
            .map(item => item.product)
            .filter(product => product && !reportedIds.includes(product.id));

        res.json(products);
    } catch (error) {
        console.error('Get Saved Error:', error);
        res.status(500).json({ error: 'Failed to fetch saved items' });
    }
};
