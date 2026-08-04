import { DataTypes } from 'sequelize';
import sequelize from '../config/database.js';

const Faculty = sequelize.define('Faculty', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    code: {
        type: DataTypes.STRING,
        allowNull: false,
        unique: true,
    },
    name: {
        type: DataTypes.STRING,
        allowNull: false,
    },
    is_active: {
        type: DataTypes.BOOLEAN,
        defaultValue: true,
    },
}, {
    timestamps: true,
});

export const seedInitialFaculties = async () => {
    try {
        const count = await Faculty.count();
        if (count === 0) {
            const defaultFaculties = [
                { code: 'FAFB', name: 'Faculty of Accountancy, Finance and Business' },
                { code: 'FOAS', name: 'Faculty of Applied Sciences' },
                { code: 'FOCS', name: 'Faculty of Computing and Information Technology' },
                { code: 'FOBE', name: 'Faculty of Built Environment' },
                { code: 'FOET', name: 'Faculty of Engineering and Technology' },
                { code: 'FCCI', name: 'Faculty of Communication and Creative Industries' },
                { code: 'FSSH', name: 'Faculty of Social Science and Humanities' },
            ];
            await Faculty.bulkCreate(defaultFaculties);
            console.log('Successfully seeded default TARUMT faculties.');
        }
    } catch (err) {
        console.error('Error seeding initial faculties:', err);
    }
};

export default Faculty;
