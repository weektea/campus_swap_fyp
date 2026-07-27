import sequelize from '../config/database.js';

async function migrate() {
    try {
        await sequelize.query('ALTER TABLE "Transactions" ADD COLUMN IF NOT EXISTS cancelled_by_id UUID;');
        console.log('MIGRATION_SUCCESS: Transactions table updated with cancelled_by_id column');
        process.exit(0);
    } catch (err) {
        console.error('MIGRATION_ERROR:', err);
        process.exit(1);
    }
}

migrate();
