import { DataTypes } from 'sequelize';
import sequelize from '../config/database.js';

const StudentWhitelist = sequelize.define('StudentWhitelist', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    student_id: {
        type: DataTypes.STRING,
        allowNull: false,
        unique: true,
    },
    email: {
        type: DataTypes.STRING,
        allowNull: false,
        unique: true,
        validate: {
            isEmail: true,
        },
    },
    faculty: {
        type: DataTypes.STRING,
        allowNull: true,
    },
    enrollment_year: {
        type: DataTypes.INTEGER,
        allowNull: false,
    },
    status: {
        type: DataTypes.ENUM('Active', 'Expired'),
        defaultValue: 'Active',
        allowNull: false,
    },
}, {
    tableName: 'StudentWhitelists',
    timestamps: true,
});

export default StudentWhitelist;
