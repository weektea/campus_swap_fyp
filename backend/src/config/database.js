import { Sequelize } from 'sequelize';
import dotenv from 'dotenv';

dotenv.config();

// Default to Postgres locally if no env vars found
const sequelize = new Sequelize(
    process.env.DB_NAME || 'campus_swap',
    process.env.DB_USER || 'postgres',
    process.env.DB_PASS || 'postgres',
    {
        host: process.env.DB_HOST || 'localhost',
        port: process.env.DB_PORT || 5432,
        dialect: 'postgres',
        logging: false,
        pool: {
            max: 5,
            min: 0,
            acquire: 30000,
            idle: 10000
        }
    }
);

export default sequelize;
