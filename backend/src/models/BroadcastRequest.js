import { DataTypes } from 'sequelize';
import sequelize from '../config/database.js';

const BroadcastRequest = sequelize.define('BroadcastRequest', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    title: {
        type: DataTypes.STRING,
        allowNull: false,
    },
    message: {
        type: DataTypes.TEXT,
        allowNull: false,
    },
    category: {
        type: DataTypes.STRING,
        defaultValue: 'ANNOUNCEMENT',
    },
    requested_by: {
        type: DataTypes.UUID,
        allowNull: false,
    },
    status: {
        type: DataTypes.ENUM('Pending', 'Approved', 'Rejected'),
        defaultValue: 'Pending',
    },
    reviewed_by: {
        type: DataTypes.UUID,
        allowNull: true,
    },
    rejection_reason: {
        type: DataTypes.STRING,
        allowNull: true,
    }
}, {
    timestamps: true,
});

export default BroadcastRequest;
