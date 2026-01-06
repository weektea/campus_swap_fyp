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
    }
});

export default Review;
