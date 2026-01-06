import { DataTypes } from 'sequelize';
import sequelize from '../config/database.js';

const User = sequelize.define('User', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    email: {
        type: DataTypes.STRING,
        allowNull: false,
        unique: true,
        validate: {
            isEmail: true,
            is: /.*\.edu\.my$/i, // Enforce .edu.my domain for campus verification
        },
    },
    password_hash: {
        type: DataTypes.STRING,
        allowNull: false,
    },
    full_name: {
        type: DataTypes.STRING,
        allowNull: false,
    },
    university_id: {
        type: DataTypes.STRING,
        allowNull: true,
    },
    profile_image_url: {
        type: DataTypes.STRING,
        allowNull: true,
    },
    reputation_score: {
        type: DataTypes.FLOAT,
        defaultValue: 5.0,
    },
    is_verified: {
        type: DataTypes.BOOLEAN,
        defaultValue: false,
    },
    role: {
        type: DataTypes.ENUM('student', 'admin', 'moderator'),
        defaultValue: 'student',
    },
}, {
    timestamps: true,
});

export default User;
