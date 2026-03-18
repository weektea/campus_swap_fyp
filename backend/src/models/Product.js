import { DataTypes } from 'sequelize';
import sequelize from '../config/database.js';

const Product = sequelize.define('Product', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    title: {
        type: DataTypes.STRING,
        allowNull: false,
    },
    description: {
        type: DataTypes.TEXT,
        allowNull: false,
    },
    price: {
        type: DataTypes.DECIMAL(10, 2),
        allowNull: false,
    },
    category: {
        type: DataTypes.STRING, // e.g., 'Electronics', 'Books'
        allowNull: false,
    },
    condition: {
        type: DataTypes.ENUM('New', 'Like New', 'Good', 'Fair', 'Poor'),
        defaultValue: 'Good',
    },
    image_urls: {
        type: DataTypes.JSON,
        defaultValue: [],
    },
    video_url: {
        type: DataTypes.STRING,
        allowNull: true,
    },
    status: {
        type: DataTypes.ENUM('Available', 'Reserved', 'Sold', 'Removed'),
        defaultValue: 'Available',
    },
    price_negotiable: {
        type: DataTypes.BOOLEAN,
        defaultValue: true,
    },
    seller_id: {
        type: DataTypes.UUID,
        allowNull: false,
    },
    // Rental System Fields
    type: {
        type: DataTypes.ENUM('Sale', 'Rent'),
        defaultValue: 'Sale',
    },
    rental_price_per_day: {
        type: DataTypes.DECIMAL(10, 2),
        allowNull: true,
    },
    max_rental_duration: {
        type: DataTypes.INTEGER, // in days
        allowNull: true,
    },
}, {
    timestamps: true,
});

export default Product;
