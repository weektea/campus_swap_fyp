import { DataTypes } from 'sequelize';
import sequelize from '../config/database.js';

const SubCategory = sequelize.define('SubCategory', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    category_id: {
        type: DataTypes.UUID,
        allowNull: false,
    },
    name: {
        type: DataTypes.STRING,
        allowNull: false,
    }
}, {
    timestamps: false,
});

export default SubCategory;
