import { DataTypes } from 'sequelize';
import sequelize from '../config/database.js';

const SupportTicket = sequelize.define('SupportTicket', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    user_id: {
        type: DataTypes.UUID,
        allowNull: false,
    },
    category: {
        type: DataTypes.ENUM('Account', 'Bug', 'Harassment', 'General'),
        allowNull: false,
    },
    subject: {
        type: DataTypes.STRING,
        allowNull: false,
    },
    description: {
        type: DataTypes.TEXT,
        allowNull: false,
    },
    status: {
        type: DataTypes.STRING,
        defaultValue: 'Open',
    },
    type: {
        type: DataTypes.STRING,
        allowNull: true,
        defaultValue: 'SUPPORT'
    },
    reply_content: {
        type: DataTypes.TEXT,
        allowNull: true, // For storing moderator's final answer
    },
    lockedByModeratorId: {
        type: DataTypes.UUID,
        allowNull: true,
    },
    lockedAt: {
        type: DataTypes.DATE,
        allowNull: true,
    },
    handled_by: {
        type: DataTypes.UUID,
        allowNull: true,
    }
}, {
    timestamps: true, // Auto includes createdAt for ticket lifecycle tracking
});

export default SupportTicket;
