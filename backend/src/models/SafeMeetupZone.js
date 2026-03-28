import { DataTypes } from 'sequelize';
import sequelize from '../config/database.js';

const SafeMeetupZone = sequelize.define('SafeMeetupZone', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    name: {
        type: DataTypes.STRING,
        allowNull: false, // e.g., 'Main Library Entrance'
    },
    latitude: {
        type: DataTypes.FLOAT,
        allowNull: false, // For OpenStreetMap mapping
    },
    longitude: {
        type: DataTypes.FLOAT,
        allowNull: false, // For OpenStreetMap mapping
    },
    description: {
        type: DataTypes.STRING,
        allowNull: true,
    },
    is_active: {
        type: DataTypes.BOOLEAN,
        defaultValue: true, // Let admins disable zones if needed
    }
}, {
    timestamps: true,
});

export default SafeMeetupZone;
