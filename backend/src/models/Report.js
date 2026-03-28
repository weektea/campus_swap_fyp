import { DataTypes } from 'sequelize';
import sequelize from '../config/database.js';

const Report = sequelize.define('Report', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    reporter_id: {
        type: DataTypes.UUID,
        allowNull: false,
    },
    product_id: {
        type: DataTypes.UUID,
        allowNull: false,
    },
    violation_type: {
        type: DataTypes.ENUM('Spam', 'Scam', 'Fake', 'Prohibited'),
        allowNull: false,
    },
    description: {
        type: DataTypes.TEXT,
        allowNull: false, // Mandatory explanation from student
    },
    status: {
        type: DataTypes.ENUM('Pending', 'In-Progress', 'Uphold', 'Dismissed'),
        defaultValue: 'Pending',
    },
    admin_notes: {
        type: DataTypes.TEXT,
        allowNull: true,
    }
}, {
    timestamps: true,
});

export default Report;
