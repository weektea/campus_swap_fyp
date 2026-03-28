import { DataTypes } from 'sequelize';
import sequelize from '../config/database.js';

const Category = sequelize.define('Category', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    name: {
        type: DataTypes.STRING,
        allowNull: false,
        unique: true,
    },
    icon_url: {
        type: DataTypes.STRING,
        allowNull: true,
    },
    carbon_conversion_factor: {
        type: DataTypes.FLOAT,
        defaultValue: 0.0,
    }
}, {
    timestamps: false,
});

export default Category;
