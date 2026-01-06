import { Product, User } from './src/models/index.js';
import { Op } from 'sequelize';

async function testFetch() {
    try {
        console.log('Testing Fetch...');

        // Mimic the query params
        const min_price = '0';
        const max_price = '1000';
        const search = undefined;
        const seller_id = undefined;

        const whereClause = {
            status: 'Available'
        };

        if (min_price) {
            whereClause.price = { ...whereClause.price, [Op.gte]: parseFloat(min_price) };
        }
        if (max_price) {
            whereClause.price = { ...whereClause.price, [Op.lte]: parseFloat(max_price) };
        }

        console.log('Where:', whereClause);

        const products = await Product.findAll({
            where: whereClause,
            include: [{
                model: User,
                as: 'seller',
                attributes: ['full_name', 'email', 'reputation'],
                required: false
            }],
            order: [['createdAt', 'DESC']]
        });

        console.log('Success! Found:', products.length);
        products.forEach(p => console.log(p.toJSON()));

    } catch (error) {
        console.error('CRASHED!');
        console.error(error);
    }
}

testFetch();
