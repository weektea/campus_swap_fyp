import { DataTypes } from 'sequelize';
import sequelize from '../config/database.js';

const BackupLog = sequelize.define('BackupLog', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    type: {
        type: DataTypes.ENUM('Auto', 'Manual'),
        allowNull: false,
        defaultValue: 'Manual'
    },
    size: {
        type: DataTypes.STRING,
        allowNull: false,
        defaultValue: '0 MB'
    },
    status: {
        type: DataTypes.ENUM('Success', 'Failed', 'In-Progress'),
        allowNull: false,
        defaultValue: 'Success'
    },
    file_path: {
        type: DataTypes.STRING,
        allowNull: true
    }
}, {
    timestamps: true,
});

export default BackupLog;
