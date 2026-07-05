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
    username: {
        type: DataTypes.STRING,
        allowNull: false,
        unique: true,
    },
    full_name: {
        type: DataTypes.STRING,
        allowNull: false,
    },
    phone_number: {
        type: DataTypes.STRING,
        allowNull: true,
        unique: true, // Enforce uniqueness
        validate: {
            is: /^[0-9+-\s]+$/i
        }
    },
    // ...

    password_hash: {
        type: DataTypes.STRING,
        allowNull: false,
    },
    university_id: {
        type: DataTypes.STRING,
        allowNull: true,
        unique: true, // Enforce uniqueness
    },
    profile_image_url: {
        type: DataTypes.STRING,
        allowNull: true,
    },
    reputation_score: {
        type: DataTypes.FLOAT,
        defaultValue: 5.0,
    },
    total_reviews: {
        type: DataTypes.INTEGER,
        defaultValue: 0,
    },
    is_verified: {
        type: DataTypes.BOOLEAN,
        defaultValue: false,
    },
    role: {
        type: DataTypes.ENUM('student', 'admin', 'moderator'),
        defaultValue: 'student',
    },
    bio: {
        type: DataTypes.STRING(150), // Limited chars as per UC04
        allowNull: true,
    },

    year_of_study: {
        type: DataTypes.INTEGER,
        allowNull: true,
    },
    privacy_setting: {
        type: DataTypes.ENUM('Public', 'Private', 'Friends Only'),
        defaultValue: 'Public', // From UC04
    },
    status: {
        type: DataTypes.ENUM('active', 'deactivated', 'suspended'),
        defaultValue: 'active',
        allowNull: false,
    },
    show_full_name: {
        type: DataTypes.BOOLEAN,
        defaultValue: false,
        allowNull: false,
    },
    show_phone_number: {
        type: DataTypes.BOOLEAN,
        defaultValue: false,
        allowNull: false,
    },
    total_carbon_saved: {
        type: DataTypes.FLOAT,
        defaultValue: 0.0, // Used for Sustainability Dashboard UC03
    },
    carbon_saved_buyer: {
        type: DataTypes.FLOAT,
        defaultValue: 0.0,
    },
    carbon_saved_seller: {
        type: DataTypes.FLOAT,
        defaultValue: 0.0,
    },
    items_reused: {
        type: DataTypes.INTEGER,
        defaultValue: 0,
    },
    is_active: {
        type: DataTypes.BOOLEAN,
        defaultValue: true,
    },
    accumulated_balance_due: {
        type: DataTypes.DECIMAL(10, 2),
        defaultValue: 0.00,
        allowNull: false,
    },
    deactivated_until: {
        type: DataTypes.DATE,
        allowNull: true,
    },
    deactivation_reason: {
        type: DataTypes.STRING,
        allowNull: true,
    },
}, {
    timestamps: true,
});

export default User;
