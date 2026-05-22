import { DataTypes } from 'sequelize';
import sequelize from '../config/database.js';

const Transaction = sequelize.define('Transaction', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    buyer_id: {
        type: DataTypes.UUID,
        allowNull: false,
    },
    seller_id: {
        type: DataTypes.UUID,
        allowNull: false,
    },
    product_id: {
        type: DataTypes.UUID,
        allowNull: false,
    },
    amount: {
        type: DataTypes.DECIMAL(10, 2),
        allowNull: false,
    },
    status: {
        type: DataTypes.ENUM('Pending', 'Scheduled', 'To Confirm', 'Completed', 'Cancelled', 'Disputed'),
        defaultValue: 'Pending',
    },
    meetup_location: {
        type: DataTypes.STRING,
        allowNull: true,
    },
    payment_proof_url: {
        type: DataTypes.STRING,
        allowNull: true, // Used for UC19
    },
    scheduled_at: {
        type: DataTypes.DATE,
        allowNull: true,
    },
    rental_start_date: {
        type: DataTypes.DATE,
        allowNull: true, // Used for UC17
    },
    rental_end_date: {
        type: DataTypes.DATE,
        allowNull: true,
    },
    rating_from_buyer: {
        type: DataTypes.INTEGER,
        validate: { min: 1, max: 5 },
        allowNull: true,
    },
    rating_from_seller: {
        type: DataTypes.INTEGER,
        validate: { min: 1, max: 5 },
        allowNull: true,
    },
    buyer_comment: {
        type: DataTypes.TEXT,
        allowNull: true,
    },
    seller_comment: {
        type: DataTypes.TEXT,
        allowNull: true,
    },
    review_status: {
        type: DataTypes.ENUM('PENDING_REVIEWS', 'BUYER_REVIEWED', 'SELLER_REVIEWED', 'PUBLISHED'),
        defaultValue: 'PENDING_REVIEWS',
    },
    completed_at: {
        type: DataTypes.DATE,
        allowNull: true,
    },
}, {
    timestamps: true,
});

export default Transaction;
