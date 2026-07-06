import sequelize from '../config/database.js';
import { SafeMeetupZone } from '../models/index.js';

// Coordinates centered around TAR UMT Penang Branch Campus (Tanjung Bungah)
const mockZones = [
    {
        name: 'Main Gate Guard House',
        latitude: 5.456811,
        longitude: 100.286345,
        description: 'Under CCTV surveillance 24/7. Highly recommended for evening meetups.',
        is_active: true
    },
    {
        name: 'Library Foyer',
        latitude: 5.457222,
        longitude: 100.285511,
        description: 'Quiet and bright area, lots of student traffic.',
        is_active: true
    },
    {
        name: 'Student Centre / Cafeteria',
        latitude: 5.457544,
        longitude: 100.286012,
        description: 'Open public space, great for social meetups and testing items.',
        is_active: true
    },
    {
        name: 'Block A Hall Entrance',
        latitude: 5.456512,
        longitude: 100.285222,
        description: 'Sheltered pickup/drop-off point.',
        is_active: true
    }
];

async function seedZones() {
    try {
        await sequelize.authenticate();
        console.log('Database connected. Seeding TAR UMT Penang OpenStreetMap Zones...');

        // Ensure models are synced
        await sequelize.sync();

        for (const zoneData of mockZones) {
            const [zone, created] = await SafeMeetupZone.findOrCreate({
                where: { name: zoneData.name },
                defaults: {
                    latitude: zoneData.latitude,
                    longitude: zoneData.longitude,
                    description: zoneData.description,
                    is_active: zoneData.is_active
                }
            });

            if (created) {
                console.log(`Created Safe Zone: ${zone.name} [${zone.latitude}, ${zone.longitude}]`);
            } else {
                let updated = false;
                if (zone.latitude !== zoneData.latitude) {
                    zone.latitude = zoneData.latitude;
                    updated = true;
                }
                if (zone.longitude !== zoneData.longitude) {
                    zone.longitude = zoneData.longitude;
                    updated = true;
                }
                if (zone.description !== zoneData.description) {
                    zone.description = zoneData.description;
                    updated = true;
                }
                if (zone.is_active !== zoneData.is_active) {
                    zone.is_active = zoneData.is_active;
                    updated = true;
                }
                if (updated) {
                    await zone.save();
                    console.log(`Updated details for Zone: ${zone.name}`);
                } else {
                    console.log(`Checking existing Zone: ${zone.name}`);
                }
            }
        }

        console.log('✅ OSM TAR UMT Penang Zones Seeded Successfully!');
        process.exit(0);

    } catch (error) {
        console.error('❌ Error seeding zones:', error);
        process.exit(1);
    }
}

seedZones();
