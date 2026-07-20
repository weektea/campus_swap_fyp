import { DataTypes } from 'sequelize';
import sequelize from '../config/database.js';

const PlatformPolicy = sequelize.define('PlatformPolicy', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    policy_type: {
        type: DataTypes.ENUM('TERMS', 'PRIVACY', 'COMMUNITY_RULES'),
        allowNull: false,
        unique: true,
    },
    content: {
        type: DataTypes.TEXT,
        allowNull: false,
    },
    version: {
        type: DataTypes.STRING,
        allowNull: false,
        defaultValue: '1.0.0',
    }
}, {
    timestamps: true,
});

export default PlatformPolicy;
