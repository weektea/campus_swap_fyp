import { DataTypes } from 'sequelize';
import sequelize from '../config/database.js';

const SavedItem = sequelize.define('SavedItem', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true
    },
    user_id: {
        type: DataTypes.UUID,
        allowNull: false
    },
    product_id: {
        type: DataTypes.UUID,
        allowNull: false
    }
});

export default SavedItem;
