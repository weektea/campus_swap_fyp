import { DataTypes } from 'sequelize';
import sequelize from '../config/database.js';

const Follow = sequelize.define('Follow', {
    follow_id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
        field: 'follow_id'
    },
    follower_id: {
        type: DataTypes.UUID,
        allowNull: false,
        field: 'follower_id'
    },
    following_id: {
        type: DataTypes.UUID,
        allowNull: false,
        field: 'following_id'
    }
}, {
    timestamps: true,
    createdAt: 'followed_at',
    updatedAt: false
});

export default Follow;
