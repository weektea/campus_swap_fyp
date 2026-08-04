import { DataTypes } from 'sequelize';
import sequelize from '../config/database.js';

const Notification = sequelize.define('Notification', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    user_id: {
        type: DataTypes.UUID,
        allowNull: false,
    },
    title: {
        type: DataTypes.STRING,
        allowNull: false,
    },
    message: {
        type: DataTypes.TEXT,
        allowNull: false,
    },
    type: {
        type: DataTypes.ENUM('Transaction', 'System', 'Promotion', 'PRICE_DROP', 'NEW_SELLER_ITEM', 'CHAT'),
        defaultValue: 'System',
    },

    is_read: {
        type: DataTypes.BOOLEAN,
        defaultValue: false,
    },
    related_id: { // e.g., Transaction ID or Product ID
        type: DataTypes.UUID,
        allowNull: true,
    }
}, {
    timestamps: true,
});

export default Notification;
