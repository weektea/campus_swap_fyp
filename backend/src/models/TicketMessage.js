import { DataTypes } from 'sequelize';
import sequelize from '../config/database.js';

const TicketMessage = sequelize.define('TicketMessage', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    reference_id: {
        type: DataTypes.UUID,
        allowNull: false, // ID of Dispute or SupportTicket
    },
    reference_type: {
        type: DataTypes.ENUM('Dispute', 'SupportTicket'),
        allowNull: false,
    },
    sender_id: {
        type: DataTypes.UUID,
        allowNull: false, // Can be user or moderator
    },
    content: {
        type: DataTypes.TEXT,
        allowNull: false,
    },
    attachment_url: {
        type: DataTypes.STRING,
        allowNull: true,
    }
}, {
    timestamps: true,
});

export default TicketMessage;
