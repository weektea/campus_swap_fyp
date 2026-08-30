import { DataTypes } from 'sequelize';
import sequelize from '../config/database.js';

const ModerationRule = sequelize.define('ModerationRule', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    name: {
        type: DataTypes.STRING(120),
        allowNull: false,
    },
    category: {
        type: DataTypes.ENUM(
            'profanity',
            'harassment',
            'religious_sensitive',
            'privacy',
            'off_platform_contact',
            'scam',
            'custom'
        ),
        defaultValue: 'custom',
        allowNull: false,
    },
    match_type: {
        type: DataTypes.ENUM('keyword', 'phrase', 'regex', 'pattern'),
        defaultValue: 'keyword',
        allowNull: false,
    },
    pattern: {
        type: DataTypes.TEXT,
        allowNull: false,
    },
    severity: {
        type: DataTypes.ENUM('low', 'medium', 'high', 'critical'),
        defaultValue: 'medium',
        allowNull: false,
    },
    action: {
        type: DataTypes.ENUM('allow', 'warn', 'flag', 'mask', 'block'),
        defaultValue: 'flag',
        allowNull: false,
    },
    is_enabled: {
        type: DataTypes.BOOLEAN,
        defaultValue: true,
        allowNull: false,
    },
    description: {
        type: DataTypes.TEXT,
        allowNull: true,
    },
    created_by: {
        type: DataTypes.UUID,
        allowNull: true,
    }
}, {
    timestamps: true,
    tableName: 'ModerationRules'
});

export default ModerationRule;
