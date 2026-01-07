import { DataTypes } from 'sequelize';
import sequelize from '../config/database.js';

const UserInteraction = sequelize.define('UserInteraction', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    user_id: {
        type: DataTypes.UUID,
        allowNull: false,
    },
    product_id: {
        type: DataTypes.UUID,
        allowNull: false,
    },
    // Interaction Type & Weight
    // view: 1, save: 5, message: 3, buy: 10
    interaction_type: {
        type: DataTypes.ENUM('view', 'save', 'message', 'buy'),
        allowNull: false,
    },
    weight: {
        type: DataTypes.INTEGER,
        defaultValue: 1,
    }
}, {
    timestamps: true,
    updatedAt: false // Only care when it happened
});

export default UserInteraction;
