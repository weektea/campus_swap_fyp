import sequelize from './config/database.js';

async function fixEnums() {
    try {
        console.log('Connecting to database...');
        await sequelize.authenticate();
        
        console.log('Adding "Suspended" to enum_Products_status...');
        try {
            await sequelize.query(`ALTER TYPE "enum_Products_status" ADD VALUE 'Suspended';`);
            console.log('Successfully added "Suspended" to Products status.');
        } catch (e) {
            console.log('Notice: "Suspended" might already exist in enum_Products_status. ' + e.message);
        }

        console.log('Adding "Escalated" to enum_Reports_status...');
        try {
            await sequelize.query(`ALTER TYPE "enum_Reports_status" ADD VALUE 'Escalated';`);
            console.log('Successfully added "Escalated" to Reports status.');
        } catch (e) {
            console.log('Notice: "Escalated" might already exist in enum_Reports_status. ' + e.message);
        }

        console.log('Database ENUM fix complete.');
        process.exit(0);
    } catch (error) {
        console.error('Failed to fix ENUMs:', error);
        process.exit(1);
    }
}

fixEnums();
