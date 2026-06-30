import { DataTypes } from 'sequelize';
import sequelize from '../config/database.js';

const ActivityLog = sequelize.define('ActivityLog', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    user_id: {
        type: DataTypes.UUID,
        allowNull: false,
    },
    action: {
        type: DataTypes.STRING,
        allowNull: false,
        defaultValue: 'ACCOUNT_REACTIVATED'
    }
}, {
    tableName: 'logs', // Map exactly to 'logs' table
    timestamps: true,  // Includes createdAt (timestamp)
    updatedAt: false
});

export default ActivityLog;
