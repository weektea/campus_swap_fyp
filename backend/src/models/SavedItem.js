import { DataTypes } from 'sequelize';
import sequelize from '../config/database.js';

const SavedItem = sequelize.define('SavedItem', {
    saved_item_id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
        field: 'saved_item_id'
    },
    user_id: {
        type: DataTypes.UUID,
        allowNull: false,
        field: 'user_id'
    },
    product_id: {
        type: DataTypes.UUID,
        allowNull: false,
        field: 'product_id'
    }
}, {
    timestamps: true,
    createdAt: 'saved_at',
    updatedAt: false
});

export default SavedItem;
