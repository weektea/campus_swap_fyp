import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import pg from 'pg';
import axios from 'axios';
import { Op } from 'sequelize';
import { createServer } from 'http';
import { initSocket } from './config/socket.js';

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;
const ML_SERVICE_URL = process.env.ML_SERVICE_URL || 'http://localhost:5000';

const httpServer = createServer(app);
initSocket(httpServer);

app.use(cors());
app.use(express.json());

// Database Connection
import sequelize from './config/database.js';
import { User, Product, Transaction } from './models/index.js';

async function runProductCategoryMigration() {
    try {
        const { Category, SubCategory } = await import('./models/index.js');
        
        // 1. First, seed and sync all active categories and subcategories
        const activeCategories = [
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

        console.log("Seeding/Syncing active categories and subcategories...");
        for (const catData of activeCategories) {
            const [cat] = await Category.findOrCreate({
                where: { name: catData.name },
                defaults: {
                    icon_url: catData.icon_url,
                    carbon_conversion_factor: catData.carbon_conversion_factor
                }
            });

            // Ensure all subcategories exist and have the correct carbon factor
            for (const subData of catData.subcategories) {
                const [sub, created] = await SubCategory.findOrCreate({
                    where: { category_id: cat.id, name: subData.name },
                    defaults: { carbon_conversion_factor: subData.factor }
                });

                if (!created && sub.carbon_conversion_factor !== subData.factor) {
                    sub.carbon_conversion_factor = subData.factor;
                    await sub.save();
                }
            }
        }
        console.log("Category seeding/syncing complete.");

        // Define exact mappings for legacy category & subcategory combinations
        const legacySubCatMap = {
            'Clothing & Fashion__Bags': { category: 'Fashion & Accessories', subcategory: 'Bags & Luggage' },
            'Clothing & Fashion__Men\'s Wear': { category: 'Fashion & Accessories', subcategory: 'Clothing' },
            'Clothing & Fashion__Shoes': { category: 'Fashion & Accessories', subcategory: 'Shoes' },
            'Clothing & Fashion__Women\'s Wear': { category: 'Fashion & Accessories', subcategory: 'Clothing' },
            'Electronics & Gadgets__Accessories': { category: 'Electronics & Gadgets', subcategory: 'PC Accessories' },
            'Furniture & Appliances__Beds & Mattresses': { category: 'Furniture & Appliances', subcategory: 'Others' },
            'Furniture & Appliances__Desk & Chairs': { category: 'Furniture & Appliances', subcategory: 'Tables & Desks' },
            'Furniture & Appliances__Fans': { category: 'Furniture & Appliances', subcategory: 'Appliances' },
            'Furniture & Appliances__Mini Fridges': { category: 'Furniture & Appliances', subcategory: 'Appliances' },
            'Textbooks & Stationery__Business Books': { category: 'Books & Study Materials', subcategory: 'Books' },
            'Textbooks & Stationery__BUsiness Books': { category: 'Books & Study Materials', subcategory: 'Books' },
            'Textbooks & Stationery__Calculators': { category: 'Books & Study Materials', subcategory: 'Calculators' },
            'Textbooks & Stationery__Engineering Books': { category: 'Books & Study Materials', subcategory: 'Books' },
            'Textbooks & Stationery__Notes': { category: 'Books & Study Materials', subcategory: 'Notes & Past Papers' },
            'Vehicles__Bicycles': { category: 'Sports', subcategory: 'Bicycles' },
            'Vehicles__Car Accessories': { category: 'Others', subcategory: 'Miscellaneous' },
            'Vehicles__E-Scooters': { category: 'Others', subcategory: 'Miscellaneous' }
        };

        const categoryMapping = {
            'Clothing & Fashion': 'Fashion & Accessories',
            'Textbooks & Stationery': 'Books & Study Materials',
            'Vehicles': 'Sports'
        };

        const allProducts = await Product.findAll();
        console.log(`Category migration: Checking all ${allProducts.length} products for legacy categories...`);
        let migratedCount = 0;

        for (const product of allProducts) {
            let catName = product.category;
            let subCatName = null;
            let needsSave = false;

            // Try to resolve current category and subcategory names from database if IDs are present
            if (product.sub_category_id) {
                const subCatObj = await SubCategory.findByPk(product.sub_category_id, {
                    include: [{ model: Category, as: 'categoryModel' }]
                });
                if (subCatObj) {
                    subCatName = subCatObj.name;
                    if (subCatObj.categoryModel) {
                        catName = subCatObj.categoryModel.name;
                    }
                }
            }

            if (!catName) {
                catName = product.category || 'Others';
            }

            // Construct lookup key
            const lookupKey = subCatName ? `${catName}__${subCatName}` : null;
            let targetCategoryName = null;
            let targetSubCategoryName = null;

            if (lookupKey && legacySubCatMap[lookupKey]) {
                targetCategoryName = legacySubCatMap[lookupKey].category;
                targetSubCategoryName = legacySubCatMap[lookupKey].subcategory;
            } else if (categoryMapping[catName]) {
                targetCategoryName = categoryMapping[catName];
                // Fallback subcategory assignment based on keywords
                const title = (product.title || '').toLowerCase();
                if (targetCategoryName === 'Fashion & Accessories') {
                    if (title.includes('bag') || title.includes('backpack') || title.includes('luggage')) {
                        targetSubCategoryName = 'Bags & Luggage';
                    } else if (title.includes('shoe') || title.includes('sneaker') || title.includes('boot')) {
                        targetSubCategoryName = 'Shoes';
                    } else if (title.includes('shirt') || title.includes('pants') || title.includes('dress') || title.includes('clothing') || title.includes('wear')) {
                        targetSubCategoryName = 'Clothing';
                    } else {
                        targetSubCategoryName = 'Fashion Accessories';
                    }
                } else if (targetCategoryName === 'Books & Study Materials') {
                    if (title.includes('calculator')) {
                        targetSubCategoryName = 'Calculators';
                    } else if (title.includes('note') || title.includes('past paper') || title.includes('exam')) {
                        targetSubCategoryName = 'Notes & Past Papers';
                    } else {
                        targetSubCategoryName = 'Books';
                    }
                } else if (targetCategoryName === 'Sports') {
                    if (title.includes('bike') || title.includes('bicycle') || title.includes('cycling')) {
                        targetSubCategoryName = 'Bicycles';
                    } else if (title.includes('apparel') || title.includes('jersey') || title.includes('shirt')) {
                        targetSubCategoryName = 'Apparel';
                    } else {
                        targetSubCategoryName = 'Equipment';
                    }
                } else {
                    targetSubCategoryName = 'Others';
                }
            } else {
                // If it's a legacy subcategory under a category that itself isn't legacy (e.g. Electronics & Gadgets__Accessories)
                const possibleKey = subCatName ? `${product.category}__${subCatName}` : null;
                if (possibleKey && legacySubCatMap[possibleKey]) {
                    targetCategoryName = legacySubCatMap[possibleKey].category;
                    targetSubCategoryName = legacySubCatMap[possibleKey].subcategory;
                }
            }

            // Also check for subcategory alignment (for products whose categories are correct but subcategories are wrong, e.g. G102 has category Electronics & Gadgets but subcategory Laptops)
            if (!targetCategoryName && !targetSubCategoryName) {
                const title = (product.title || '').toLowerCase();
                if (catName === 'Electronics & Gadgets' && (subCatName === 'Laptops' || subCatName === 'Others' || !subCatName)) {
                    if (title.includes('mouse') || title.includes('keyboard') || title.includes('cable') || title.includes('charger')) {
                        targetCategoryName = 'Electronics & Gadgets';
                        targetSubCategoryName = 'PC Accessories';
                    }
                } else if (catName === 'Fashion & Accessories' && (subCatName === 'Bags & Luggage' || subCatName === 'Others' || !subCatName)) {
                    if (title.includes('shoe') || title.includes('sneaker') || title.includes('boot')) {
                        targetCategoryName = 'Fashion & Accessories';
                        targetSubCategoryName = 'Shoes';
                    }
                } else if (catName === 'Sports' && (subCatName === 'Others' || !subCatName)) {
                    if (title.includes('bike') || title.includes('bicycle') || title.includes('cycling')) {
                        targetCategoryName = 'Sports';
                        targetSubCategoryName = 'Bicycles';
                    }
                }
            }

            // Special vehicle fallback check
            if (catName === 'Vehicles' && targetCategoryName === 'Sports' && targetSubCategoryName !== 'Bicycles') {
                targetCategoryName = 'Others';
                targetSubCategoryName = 'Miscellaneous';
            }

            // Apply updates if target was resolved
            if (targetCategoryName && targetSubCategoryName) {
                console.log(`Migrating product "${product.title}" from "${catName} -> ${subCatName || 'None'}" to "${targetCategoryName} -> ${targetSubCategoryName}"`);
                
                // Find or create category object
                let targetCategoryObj = await Category.findOne({ where: { name: targetCategoryName } });
                if (!targetCategoryObj) {
                    targetCategoryObj = await Category.findOne({ where: { name: 'Others' } });
                }
                
                if (targetCategoryObj) {
                    // Find or create subcategory object
                    let targetSubCategoryObj = await SubCategory.findOne({
                        where: { category_id: targetCategoryObj.id, name: targetSubCategoryName }
                    });
                    if (!targetSubCategoryObj) {
                        targetSubCategoryObj = await SubCategory.findOne({
                            where: { category_id: targetCategoryObj.id, name: 'Others' }
                        });
                    }
                    if (!targetSubCategoryObj) {
                        targetSubCategoryObj = await SubCategory.findOne({
                            where: { category_id: targetCategoryObj.id }
                        });
                    }

                    if (targetSubCategoryObj) {
                        product.category = targetCategoryName;
                        product.category_id = targetCategoryObj.id;
                        product.sub_category_id = targetSubCategoryObj.id;
                        needsSave = true;
                    }
                }
            }

            // General Self-healing: if category_id or sub_category_id is missing, find them
            if (!product.category_id && product.category) {
                let categoryObj = await Category.findOne({ where: { name: product.category } });
                if (!categoryObj) categoryObj = await Category.findOne({ where: { name: 'Others' } });
                if (categoryObj) {
                    product.category_id = categoryObj.id;
                    needsSave = true;
                }
            }

            if (product.category_id && !product.sub_category_id) {
                let targetSub = await SubCategory.findOne({ where: { category_id: product.category_id, name: 'Others' } });
                if (!targetSub) targetSub = await SubCategory.findOne({ where: { category_id: product.category_id } });
                if (targetSub) {
                    product.sub_category_id = targetSub.id;
                    needsSave = true;
                }
            }

            if (needsSave) {
                await product.save();
                migratedCount++;
            }
        }

        console.log(`Category migration: Completed migrating ${migratedCount} products.`);

        // Now delete legacy subcategories and categories from DB to completely purge them from UI
        // NOTE: Commented out because the migration has already run and cleaned up the database.
        // This prevents re-added categories (e.g. if the admin decides to recreate "Vehicles" in the future) from being deleted on server reboot.
        /*
        console.log("Cleaning up legacy database categories and subcategories...");

        // 1. Delete legacy subcategories under active categories
        const activeCatsWithLegacySubs = [
            { catName: 'Electronics & Gadgets', subNames: ['Accessories'] },
            { catName: 'Furniture & Appliances', subNames: ['Beds & Mattresses', 'Desk & Chairs', 'Fans', 'Mini Fridges'] }
        ];

        for (const item of activeCatsWithLegacySubs) {
            const cat = await Category.findOne({ where: { name: item.catName } });
            if (cat) {
                const deletedCount = await SubCategory.destroy({
                    where: {
                        category_id: cat.id,
                        name: { [Op.in]: item.subNames }
                    }
                });
                if (deletedCount > 0) {
                    console.log(`Deleted ${deletedCount} legacy subcategories from category "${item.catName}"`);
                }
            }
        }

        // 2. Delete legacy categories and their subcategories
        const legacyCategories = ['Clothing & Fashion', 'Textbooks & Stationery', 'Vehicles'];
        for (const legacyCatName of legacyCategories) {
            const cat = await Category.findOne({ where: { name: legacyCatName } });
            if (cat) {
                // Delete its subcategories first
                const deletedSubs = await SubCategory.destroy({
                    where: { category_id: cat.id }
                });
                if (deletedSubs > 0) {
                    console.log(`Deleted ${deletedSubs} subcategories from legacy category "${legacyCatName}"`);
                }
                // Delete the category
                await cat.destroy();
                console.log(`Deleted legacy category "${legacyCatName}"`);
            }
        }
        */
        console.log("Legacy category cleanup block bypassed (already completed).");

        console.log("Legacy category cleanup completed successfully!");
    } catch (e) {
        console.error('Category migration and cleanup failed:', e);
    }
}

// Test DB Connection & Sync - Start server ONLY after DB is ready
if (process.env.NODE_ENV !== 'test') {
    sequelize.authenticate()
        .then(async () => {
            console.log('Connected to PostgreSQL');
            
            // Migration query helper: Rename columns if they exist under old names
            try {
                await sequelize.query(`
                    DO $$
                    BEGIN
                        -- Rename id to saved_item_id if it exists and target doesn't
                        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='SavedItems' AND column_name='id') 
                           AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='SavedItems' AND column_name='saved_item_id') THEN
                            ALTER TABLE "SavedItems" RENAME COLUMN "id" TO "saved_item_id";
                        END IF;
                        
                        -- Rename createdAt to saved_at if it exists and target doesn't
                        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='SavedItems' AND column_name='createdAt') 
                           AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='SavedItems' AND column_name='saved_at') THEN
                            ALTER TABLE "SavedItems" RENAME COLUMN "createdAt" TO "saved_at";
                        END IF;

                        -- Drop updatedAt if it exists
                        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='SavedItems' AND column_name='updatedAt') THEN
                            ALTER TABLE "SavedItems" DROP COLUMN "updatedAt";
                        END IF;

                        -- 1. Ensure username column exists
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Users' AND column_name='username') THEN
                            ALTER TABLE "Users" ADD COLUMN "username" VARCHAR(255);
                        END IF;

                        -- 2. Ensure full_name column exists
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Users' AND column_name='full_name') THEN
                            ALTER TABLE "Users" ADD COLUMN "full_name" VARCHAR(255);
                        END IF;

                        -- 3. Populate full_name from username if it is null
                        UPDATE "Users" 
                        SET "full_name" = INITCAP(REPLACE("username", '_', ' '))
                        WHERE "full_name" IS NULL;

                        -- 4. Alter columns to NOT NULL and add UNIQUE constraint for username
                        ALTER TABLE "Users" ALTER COLUMN "full_name" SET NOT NULL;
                        ALTER TABLE "Users" ALTER COLUMN "username" SET NOT NULL;

                        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE table_name='Users' AND constraint_name='Users_username_key') THEN
                            ALTER TABLE "Users" ADD CONSTRAINT "Users_username_key" UNIQUE ("username");
                        END IF;

                        -- 5. Add show_full_name and show_phone_number columns if they do not exist
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Users' AND column_name='show_full_name') THEN
                            ALTER TABLE "Users" ADD COLUMN "show_full_name" BOOLEAN DEFAULT FALSE NOT NULL;
                        ELSE
                            ALTER TABLE "Users" ALTER COLUMN "show_full_name" SET DEFAULT FALSE;
                        END IF;
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Users' AND column_name='show_phone_number') THEN
                            ALTER TABLE "Users" ADD COLUMN "show_phone_number" BOOLEAN DEFAULT FALSE NOT NULL;
                        ELSE
                            ALTER TABLE "Users" ALTER COLUMN "show_phone_number" SET DEFAULT FALSE;
                        END IF;

                        -- Force all existing users to false to align with "default hide" policy
                        UPDATE "Users" SET "show_full_name" = FALSE, "show_phone_number" = FALSE;

                        -- 6. Ensure awarded_carbon_points exists in Transactions table
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Transactions' AND column_name='awarded_carbon_points') THEN
                            ALTER TABLE "Transactions" ADD COLUMN "awarded_carbon_points" DOUBLE PRECISION;
                        END IF;
                    END $$;
                `);
                console.log('SavedItems and Users table pre-sync migrations executed successfully');
            } catch (migrationErr) {
                console.error('SavedItems table pre-sync migrations failed (might have run already):', migrationErr.message);
                try {
                    await sequelize.query('DROP TABLE IF EXISTS "SavedItems" CASCADE;');
                    console.log('SavedItems table dropped as recovery fallback due to migration failure.');
                } catch (dropErr) {
                    console.error('Failed to drop SavedItems table on fallback:', dropErr.message);
                }
            }

            return sequelize.sync();
        })
        .then(async () => {
            console.log('Database synced');
            await runProductCategoryMigration();
            httpServer.listen(port, '0.0.0.0', () => {
                console.log(`Server running on port ${port}`);
            });
            startCronJobs();
        })
        .catch(err => {
            console.error('DB Connection/Sync error - server NOT started:', err);
            process.exit(1);
        });
} else {
    httpServer.listen(port, '0.0.0.0', () => {
        console.log(`Server running on port ${port} (test mode)`);
    });
}

// Routes
import authRoutes from './routes/authRoutes.js';
import productRoutes from './routes/productRoutes.js';
import transactionRoutes from './routes/transactionRoutes.js';
import savedRoutes from './routes/savedRoutes.js';
import messageRoutes from './routes/messageRoutes.js';
import reviewRoutes from './routes/reviewRoutes.js';
import notificationRoutes from './routes/notificationRoutes.js';
import uploadRoutes from './routes/uploadRoutes.js';
import recommendationRoutes from './routes/recommendationRoutes.js';
import { startCronJobs } from './scripts/cronJobs.js';
import categoryRoutes from './routes/categoryRoutes.js';
import disputeRoutes from './routes/disputeRoutes.js';
import sustainabilityRoutes from './routes/sustainabilityRoutes.js';
import ticketRoutes from './routes/ticketRoutes.js';
import zoneRoutes from './routes/zoneRoutes.js';

app.use('/api/auth', authRoutes);
app.use('/api/products', productRoutes);
app.use('/api/transactions', transactionRoutes);
app.use('/api/saved', savedRoutes);
app.use('/api/messages', messageRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/recommendations', recommendationRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/disputes', disputeRoutes);
app.use('/api/sustainability', sustainabilityRoutes);
app.use('/api/tickets', ticketRoutes);
app.use('/api/support_tickets', ticketRoutes);
app.use('/api/zones', zoneRoutes);

import adminRoutes from './routes/adminRoutes.js';
import moderatorRoutes from './routes/moderatorRoutes.js';
app.use('/api/admin', adminRoutes);
app.use('/api/moderator', moderatorRoutes);

app.use('/admin', express.static('src/public/admin')); // Serve Admin UI
app.use('/web', express.static('src/public/web')); // Serve Student Web UI
app.use('/uploads', express.static('uploads')); // Serve Images

app.get('/', (req, res) => {
    res.json({ message: 'Welcome to Campus Swap API' });
});

app.get('/api/health', (req, res) => {
    res.json({ status: 'OK', timestamp: new Date() });
});

// File Upload Setup
import multer from 'multer';
import FormData from 'form-data';
import fs from 'fs';

const upload = multer({ dest: 'uploads/' });

app.post('/api/products/classify', upload.single('file'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No file uploaded' });
        }

        const formData = new FormData();
        formData.append('file', fs.createReadStream(req.file.path), req.file.originalname);

        console.log('Forwarding image to ML Service at port 5000...');
        const response = await axios.post(`${ML_SERVICE_URL}/predict/image`, formData, {
            headers: {
                ...formData.getHeaders(),
            },
        });

        // Valid response from ML
        res.json(response.data);

        // Cleanup: delete temp file safely
        try {
            if (fs.existsSync(req.file.path)) fs.unlinkSync(req.file.path);
        } catch (unlinkErr) {
            console.warn('Cleanup warning (EBUSY):', unlinkErr.message);
        }
    } catch (error) {
        console.error('ML Service Error:', error.message);
        // Cleanup if file exists, safely
        try {
            if (req.file && fs.existsSync(req.file.path)) fs.unlinkSync(req.file.path);
        } catch (unlinkErr) {
            console.warn('Cleanup warning on error (EBUSY):', unlinkErr.message);
        }

        // Fallback (if ML is down)
        res.json({
            category: 'Others',
            sub_category: 'Miscellaneous',
            confidence: 0.0,
            note: 'ML Service unavailable, defaulting to Others.'
        });
    }
});

app.post('/api/products/recommend', async (req, res) => {
    try {
        const response = await axios.post(`${ML_SERVICE_URL}/recommend`, req.body);
        res.json(response.data);
    } catch (error) {
        console.error('ML Service Error:', error.message);
        res.json({
            product_ids: ['mock_1', 'mock_2'],
            confidence: 0.8,
            note: 'ML Service unavailable, using mock.'
        });
    }
});

app.post('/api/products/price-suggestion', async (req, res) => {
    try {
        const response = await axios.post(`${ML_SERVICE_URL}/predict-price`, req.body);
        res.json(response.data);
    } catch (error) {
        console.error('ML Service Error:', error.message);
        // Fallback
        res.json({ estimated_price: 45.00, currency: 'RM', note: 'Mock Fallback' });
    }
});

app.post('/api/products/generate-description', async (req, res) => {
    try {
        const response = await axios.post(`${ML_SERVICE_URL}/generate-description`, req.body);
        res.json(response.data);
    } catch (error) {
        console.error('ML Service Error:', error.message);
        res.json({ description: 'Great condition, must have! (Fallback)' });
    }
});
