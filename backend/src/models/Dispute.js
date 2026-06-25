import { DataTypes } from 'sequelize';
import sequelize from '../config/database.js';

const Dispute = sequelize.define('Dispute', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    transaction_id: {
        type: DataTypes.UUID,
        allowNull: false,
    },
    complainant_id: {
        type: DataTypes.UUID,
        allowNull: false,
    },
    reason: {
        type: DataTypes.ENUM('Not Received', 'Damaged', 'Fraud', 'Other'),
        allowNull: false,
    },
    description: {
        type: DataTypes.TEXT,
        allowNull: false,
    },
    evidence_urls: {
        type: DataTypes.JSON,
        defaultValue: [],
    },
    status: {
        type: DataTypes.STRING,
        defaultValue: 'New',
    },
    handled_by: {
        type: DataTypes.UUID,
        allowNull: true, // Moderator/Admin ID resolving it
    }
}, {
    timestamps: true,
});

export default Dispute;
