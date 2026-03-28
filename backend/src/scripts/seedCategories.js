import sequelize from '../config/database.js';
import { Category, SubCategory } from '../models/index.js';

const mockCategories = [
    {
        name: 'Electronics & Gadgets',
        icon_url: 'computer-icon',
        carbon_conversion_factor: 55.5, // Producing a new laptop/phone costs ~55.5kg CO2
        subcategories: ['Laptops', 'Smartphones', 'Tablets', 'Accessories']
    },
    {
        name: 'Furniture & Appliances',
        icon_url: 'chair-icon',
        carbon_conversion_factor: 30.0, // Bulky items save ~30.0kg CO2
        subcategories: ['Desk & Chairs', 'Mini Fridges', 'Fans', 'Beds & Mattresses']
    },
    {
        name: 'Textbooks & Stationery',
        icon_url: 'book-icon',
        carbon_conversion_factor: 3.5, // Printing a book costs ~3.5kg CO2
        subcategories: ['Engineering Books', 'Business Books', 'Calculators', 'Notes']
    },
    {
        name: 'Clothing & Fashion',
        icon_url: 'shirt-icon',
        carbon_conversion_factor: 8.2, // Fast fashion costs ~8.2kg CO2 per heavy item
        subcategories: ['Men\'s Wear', 'Women\'s Wear', 'Shoes', 'Bags']
    },
    {
        name: 'Vehicles',
        icon_url: 'bike-icon',
        carbon_conversion_factor: 120.0, // E-scooters/Bikes save massive carbon! ~120kg CO2
        subcategories: ['Bicycles', 'E-Scooters', 'Car Accessories']
    }
];

async function seedData() {
    try {
        await sequelize.authenticate();
        console.log('Database connected. Starting to seed mock categories and carbon factors...');

        // Important: Ensure models are synced
        await sequelize.sync();

        for (const catData of mockCategories) {
            // Use findOrCreate to prevent duplicates if user runs this twice
            const [cat, created] = await Category.findOrCreate({
                where: { name: catData.name },
                defaults: {
                    icon_url: catData.icon_url,
                    carbon_conversion_factor: catData.carbon_conversion_factor
                }
            });

            if (created) {
                console.log(`Created Category: ${cat.name} (Saves ${cat.carbon_conversion_factor}kg CO2)`);
                // Create subcategories
                for (const subName of catData.subcategories) {
                    await SubCategory.create({
                        category_id: cat.id,
                        name: subName
                    });
                }
            } else {
                console.log(`Skipped existing Category: ${cat.name}`);
            }
        }

        console.log('✅ Seeding completed! Your Sustainability Dashboard now has logic based on categories.');
        process.exit(0);

    } catch (error) {
        console.error('❌ Error seeding data:', error);
        process.exit(1);
    }
}

seedData();
