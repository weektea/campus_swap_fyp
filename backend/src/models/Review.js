import { DataTypes } from 'sequelize';
import sequelize from '../config/database.js';

const Review = sequelize.define('Review', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    rating: {
        type: DataTypes.INTEGER,
        allowNull: false,
        validate: {
            min: 1,
            max: 5
        }
    },
    comment: {
        type: DataTypes.TEXT,
        allowNull: true,
    },
    transaction_id: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
            model: 'Transactions', // Match table name
            key: 'id',
        }
    },
    reviewer_id: {
        type: DataTypes.UUID,
        allowNull: false,
    },
    reviewee_id: {
        type: DataTypes.UUID,
        allowNull: false,
    },
    is_toxic: {
        type: DataTypes.BOOLEAN,
        defaultValue: false,
    },
    sentiment_score: {
        type: DataTypes.FLOAT,
        defaultValue: 0.0,
    },
    flag_reason: {
        type: DataTypes.STRING,
        allowNull: true,
    },
    status: {
        type: DataTypes.ENUM('PENDING', 'PUBLISHED', 'FLAGGED_FOR_REVIEW'),
        defaultValue: 'PUBLISHED',
    }
});

export default Review;
