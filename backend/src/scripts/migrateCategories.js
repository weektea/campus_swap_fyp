import sequelize from '../config/database.js';
import { Product } from '../models/index.js';

const categoryMap = {
    'Electronics': 'Electronics & Gadgets',
    'Fashion': 'Fashion & Accessories',
    'Furniture': 'Furniture & Appliances',
    'Books': 'Books & Study Materials'
};

async function migrate() {
    try {
        await sequelize.authenticate();
        console.log('Database connected. Starting migration...');

        let updatedCount = 0;

        for (const [oldCat, newCat] of Object.entries(categoryMap)) {
            const [affectedRows] = await Product.update(
                { category: newCat },
                { where: { category: oldCat } }
            );
            console.log(`Migrated ${affectedRows} products from '${oldCat}' to '${newCat}'`);
            updatedCount += affectedRows;
        }

        console.log(`Migration complete. Total updated: ${updatedCount}`);
        process.exit(0);
    } catch (error) {
        console.error('Migration failed:', error);
        process.exit(1);
    }
}

migrate();
