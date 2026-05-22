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
        type: DataTypes.ENUM('Open', 'In-Progress', 'Escalated', 'Resolved'),
        defaultValue: 'Open',
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
    }
}, {
    timestamps: true, // Auto includes createdAt for ticket lifecycle tracking
});

export default SupportTicket;
