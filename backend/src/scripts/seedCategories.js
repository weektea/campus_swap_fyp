import sequelize from '../config/database.js';
import { Category, SubCategory } from '../models/index.js';

const mockCategories = [
    {
        name: 'Electronics & Gadgets',
        icon_url: 'computer-icon',
        carbon_conversion_factor: 55.5,
        subcategories: [
            { name: 'Audio', factor: 15.0 },
            { name: 'Laptops', factor: 250.0 },
            { name: 'PC Accessories', factor: 10.0 },
            { name: 'Smartphones', factor: 65.0 },
            { name: 'Tablets', factor: 110.0 },
            { name: 'Others', factor: 50.0 }
        ]
    },
    {
        name: 'Fashion & Accessories',
        icon_url: 'shirt-icon',
        carbon_conversion_factor: 8.2,
        subcategories: [
            { name: 'Bags & Luggage', factor: 20.0 },
            { name: 'Clothing', factor: 15.0 },
            { name: 'Fashion Accessories', factor: 5.0 },
            { name: 'Shoes', factor: 15.0 }
        ]
    },
    {
        name: 'Furniture & Appliances',
        icon_url: 'chair-icon',
        carbon_conversion_factor: 30.0,
        subcategories: [
            { name: 'Appliances', factor: 80.0 },
            { name: 'Chairs', factor: 35.0 },
            { name: 'Sofas', factor: 150.0 },
            { name: 'Storage', factor: 50.0 },
            { name: 'Tables & Desks', factor: 60.0 },
            { name: 'Others', factor: 40.0 }
        ]
    },
    {
        name: 'Books & Study Materials',
        icon_url: 'book-icon',
        carbon_conversion_factor: 3.5,
        subcategories: [
            { name: 'Books', factor: 2.5 },
            { name: 'Calculators', factor: 8.0 },
            { name: 'Notes & Past Papers', factor: 1.5 },
            { name: 'Others', factor: 2.0 }
        ]
    },
    {
        name: 'Sports',
        icon_url: 'sports-icon',
        carbon_conversion_factor: 15.0,
        subcategories: [
            { name: 'Apparel', factor: 10.0 },
            { name: 'Bicycles', factor: 120.0 },
            { name: 'Equipment', factor: 20.0 },
            { name: 'Others', factor: 15.0 }
        ]
    },
    {
        name: 'Stationery',
        icon_url: 'edit-icon',
        carbon_conversion_factor: 2.0,
        subcategories: [
            { name: 'Art Supplies', factor: 3.0 },
            { name: 'Paper', factor: 5.0 },
            { name: 'Writing', factor: 0.5 },
            { name: 'Others', factor: 2.0 }
        ]
    },
    {
        name: 'Others',
        icon_url: 'box-icon',
        carbon_conversion_factor: 10.0,
        subcategories: [
            { name: 'Cosmetics & Beauty', factor: 2.0 },
            { name: 'Drinkware', factor: 5.0 },
            { name: 'Miscellaneous', factor: 5.0 }
        ]
    }
];

async function seedData() {
    try {
        await sequelize.authenticate();
        console.log('Database connected. Starting to seed mock categories and carbon factors...');

        // Important: Ensure models are synced
        await sequelize.sync();

        for (const catData of mockCategories) {
            const [cat, created] = await Category.findOrCreate({
                where: { name: catData.name },
                defaults: {
                    icon_url: catData.icon_url,
                    carbon_conversion_factor: catData.carbon_conversion_factor
                }
            });

            if (created) {
                console.log(`Created Category: ${cat.name} (Saves ${cat.carbon_conversion_factor}kg CO2)`);
            } else {
                console.log(`Checking existing Category: ${cat.name}`);
            }

            // Sync and seed subcategories
            for (const subData of catData.subcategories) {
                const [sub, subCreated] = await SubCategory.findOrCreate({
                    where: { category_id: cat.id, name: subData.name },
                    defaults: { carbon_conversion_factor: subData.factor }
                });

                if (subCreated) {
                    console.log(`  └─ Created SubCategory: ${sub.name} (Saves ${sub.carbon_conversion_factor}kg CO2)`);
                } else if (sub.carbon_conversion_factor !== subData.factor) {
                    sub.carbon_conversion_factor = subData.factor;
                    await sub.save();
                    console.log(`  └─ Updated SubCategory "${sub.name}" carbon factor to ${subData.factor}kg CO2`);
                }
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
