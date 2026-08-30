import { DataTypes } from 'sequelize';
import sequelize from '../config/database.js';

const FlaggedContent = sequelize.define('FlaggedContent', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    source_type: {
        type: DataTypes.ENUM('message', 'listing', 'review', 'comment', 'profile'),
        allowNull: false,
        defaultValue: 'message'
    },
    source_id: {
        type: DataTypes.STRING(64),
        allowNull: true,
    },
    user_id: {
        type: DataTypes.UUID,
        allowNull: false,
    },
    category: {
        type: DataTypes.STRING(50),
        allowNull: false,
        defaultValue: 'custom'
    },
    severity: {
        type: DataTypes.ENUM('low', 'medium', 'high', 'critical'),
        defaultValue: 'medium',
        allowNull: false,
    },
    action_taken: {
        type: DataTypes.STRING(30),
        allowNull: false,
        defaultValue: 'flagged'
    },
    matched_rule_id: {
        type: DataTypes.UUID,
        allowNull: true,
    },
    matched_rule_name: {
        type: DataTypes.STRING(120),
        allowNull: true,
    },
    matched_snippet: {
        type: DataTypes.STRING(255),
        allowNull: true,
        comment: 'Truncated, masked snippet preserving user privacy'
    },
    review_status: {
        type: DataTypes.ENUM('pending', 'approved', 'dismissed', 'penalized'),
        defaultValue: 'pending',
        allowNull: false,
    },
    reviewed_by: {
        type: DataTypes.UUID,
        allowNull: true,
    },
    review_notes: {
        type: DataTypes.TEXT,
        allowNull: true,
    }
}, {
    timestamps: true,
    tableName: 'FlaggedContents'
});

export default FlaggedContent;
