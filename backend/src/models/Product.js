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
    category_id: {
        type: DataTypes.UUID,
        allowNull: true, // Made true so old items/flutter code don't crash
    },
    sub_category_id: {
        type: DataTypes.UUID,
        allowNull: true,
    },
    category: {
        type: DataTypes.STRING,
        allowNull: true, // Legacy string category to keep app working while transitioning
    },
    condition: {
        type: DataTypes.ENUM('New', 'Like New', 'Good', 'Fair', 'Poor'),
        defaultValue: 'Good',
    },
    image_urls: {
        type: DataTypes.JSON,
        defaultValue: [],
    },
    accepted_payment_methods: {
        type: DataTypes.JSON,
        defaultValue: ['Cash', 'TNG', 'Bank Transfer'],
    },
    video_url: {
        type: DataTypes.STRING,
        allowNull: true,
    },
    status: {
        type: DataTypes.ENUM('Available', 'Reserved', 'Sold', 'Removed', 'Suspended'),
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
    rental_unit: {
        type: DataTypes.ENUM('Hour', 'Day', 'Month', 'Semester'),
        defaultValue: 'Day',
    },
    rental_price_per_hour: {
        type: DataTypes.DECIMAL(10, 2),
        allowNull: true,
    },
    rental_price_per_day: {
        type: DataTypes.DECIMAL(10, 2),
        allowNull: true,
    },
    rental_price_per_month: {
        type: DataTypes.DECIMAL(10, 2),
        allowNull: true,
    },
    rental_price_per_semester: {
        type: DataTypes.DECIMAL(10, 2),
        allowNull: true,
    },
    max_rental_duration: {
        type: DataTypes.INTEGER, // in days or hours based on rental_unit
        allowNull: true,
    },
    rental_deposit: {
        type: DataTypes.DECIMAL(10, 2),
        allowNull: true,
    },
}, {
    timestamps: true,
});

export default Product;
