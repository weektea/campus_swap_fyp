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

                        -- Ensure is_email_verified, otp, and otp_expiry columns exist in Users table
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Users' AND column_name='is_email_verified') THEN
                            ALTER TABLE "Users" ADD COLUMN "is_email_verified" BOOLEAN DEFAULT FALSE NOT NULL;
                        END IF;
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Users' AND column_name='otp') THEN
                            ALTER TABLE "Users" ADD COLUMN "otp" VARCHAR(255);
                        END IF;
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Users' AND column_name='otp_expiry') THEN
                            ALTER TABLE "Users" ADD COLUMN "otp_expiry" TIMESTAMP WITH TIME ZONE;
                        END IF;

                        -- 6. Ensure awarded_carbon_points exists in Transactions table
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Transactions' AND column_name='awarded_carbon_points') THEN
                            ALTER TABLE "Transactions" ADD COLUMN "awarded_carbon_points" DOUBLE PRECISION;
                        END IF;

                        -- 7. Ensure status column exists in Users table
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Users' AND column_name='status') THEN
                            ALTER TABLE "Users" ADD COLUMN "status" VARCHAR(255) DEFAULT 'active';
                            UPDATE "Users" SET "status" = 'deactivated' WHERE "is_active" = FALSE AND "deactivation_reason" = 'Deactivated by user';
                            UPDATE "Users" SET "status" = 'suspended' WHERE "is_active" = FALSE AND ("deactivation_reason" IS NULL OR "deactivation_reason" != 'Deactivated by user');
                            UPDATE "Users" SET "status" = 'active' WHERE "is_active" = TRUE OR "is_active" IS NULL;
                        END IF;

                        -- 8. Ensure type column exists in SupportTickets table
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='SupportTickets' AND column_name='type') THEN
                            ALTER TABLE "SupportTickets" ADD COLUMN "type" VARCHAR(255) DEFAULT 'SUPPORT';
                        END IF;

                        -- 9. Ensure platform_fee column exists in Transactions table
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Transactions' AND column_name='platform_fee') THEN
                            ALTER TABLE "Transactions" ADD COLUMN "platform_fee" DECIMAL(10, 2) DEFAULT 0.00;
                        END IF;

                        -- 10. Ensure accumulated_balance_due column exists in Users table
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Users' AND column_name='accumulated_balance_due') THEN
                            ALTER TABLE "Users" ADD COLUMN "accumulated_balance_due" DECIMAL(10, 2) DEFAULT 0.00;
                        END IF;

                        -- 11. Ensure accepted_payment_methods column exists in Products table
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Products' AND column_name='accepted_payment_methods') THEN
                            ALTER TABLE "Products" ADD COLUMN "accepted_payment_methods" JSON DEFAULT '["Cash", "TNG", "Bank Transfer"]'::json;
                        END IF;

                        -- 12. Ensure selected_payment_method column exists in Transactions table
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Transactions' AND column_name='selected_payment_method') THEN
                            ALTER TABLE "Transactions" ADD COLUMN "selected_payment_method" VARCHAR(255);
                        END IF;

                        -- 13. Ensure rental_type column exists in Transactions table
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Transactions' AND column_name='rental_type') THEN
                            ALTER TABLE "Transactions" ADD COLUMN "rental_type" VARCHAR(50) DEFAULT 'Short-term';
                        END IF;

                        -- 14. Ensure group_size column exists in Transactions table
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Transactions' AND column_name='group_size') THEN
                            ALTER TABLE "Transactions" ADD COLUMN "group_size" INTEGER DEFAULT 1;
                        END IF;

                        -- 15. Ensure co_renter_id column exists in Transactions table
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Transactions' AND column_name='co_renter_id') THEN
                            ALTER TABLE "Transactions" ADD COLUMN "co_renter_id" UUID;
                        END IF;

                        -- 16. Ensure product_id in Reports table is nullable
                        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Reports' AND column_name='product_id' AND is_nullable='NO') THEN
                            ALTER TABLE "Reports" ALTER COLUMN "product_id" DROP NOT NULL;
                        END IF;

                        -- 17. Ensure Users table has is_flagged, flag_reason, manual_unflagged, and warning_count columns
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Users' AND column_name='is_flagged') THEN
                            ALTER TABLE "Users" ADD COLUMN "is_flagged" BOOLEAN DEFAULT FALSE;
                        END IF;
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Users' AND column_name='flag_reason') THEN
                            ALTER TABLE "Users" ADD COLUMN "flag_reason" VARCHAR(255);
                        END IF;
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Users' AND column_name='manual_unflagged') THEN
                            ALTER TABLE "Users" ADD COLUMN "manual_unflagged" BOOLEAN DEFAULT FALSE;
                        END IF;
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Users' AND column_name='warning_count') THEN
                            ALTER TABLE "Users" ADD COLUMN "warning_count" INTEGER DEFAULT 0 NOT NULL;
                        END IF;

                        -- 18. Ensure onboarding columns exist in Users table
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Users' AND column_name='primary_intent') THEN
                            ALTER TABLE "Users" ADD COLUMN "primary_intent" VARCHAR(50) DEFAULT 'browse';
                        END IF;
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Users' AND column_name='preference_tags') THEN
                            ALTER TABLE "Users" ADD COLUMN "preference_tags" JSON DEFAULT '[]'::json;
                        END IF;
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Users' AND column_name='is_onboarded') THEN
                            ALTER TABLE "Users" ADD COLUMN "is_onboarded" BOOLEAN DEFAULT FALSE;
                        END IF;
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Users' AND column_name='fcm_token') THEN
                            ALTER TABLE "Users" ADD COLUMN "fcm_token" TEXT;
                        END IF;

                        -- 19. Ensure cancellation_reason column exists in Transactions table
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Transactions' AND column_name='cancellation_reason') THEN
                            ALTER TABLE "Transactions" ADD COLUMN "cancellation_reason" TEXT;
                        END IF;

                        -- 18. Ensure logs table has event_type, description, and admin_id columns
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='logs' AND column_name='event_type') THEN
                            ALTER TABLE "logs" ADD COLUMN "event_type" VARCHAR(255);
                        END IF;
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='logs' AND column_name='description') THEN
                            ALTER TABLE "logs" ADD COLUMN "description" TEXT;
                        END IF;
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='logs' AND column_name='admin_id') THEN
                            ALTER TABLE "logs" ADD COLUMN "admin_id" UUID;
                        END IF;

                        -- 19. Ensure Module 6 Rental System columns exist in Products table
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Products' AND column_name='rental_unit') THEN
                            ALTER TABLE "Products" ADD COLUMN "rental_unit" VARCHAR(50) DEFAULT 'Day';
                        END IF;
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Products' AND column_name='rental_price_per_hour') THEN
                            ALTER TABLE "Products" ADD COLUMN "rental_price_per_hour" DECIMAL(10, 2);
                        END IF;
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Products' AND column_name='rental_price_per_month') THEN
                            ALTER TABLE "Products" ADD COLUMN "rental_price_per_month" DECIMAL(10, 2);
                        END IF;
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Products' AND column_name='rental_price_per_semester') THEN
                            ALTER TABLE "Products" ADD COLUMN "rental_price_per_semester" DECIMAL(10, 2);
                        END IF;

                        -- 20. Ensure deposit_amount, deposit_status, and platform_fee columns exist in Transactions table
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Transactions' AND column_name='deposit_amount') THEN
                            ALTER TABLE "Transactions" ADD COLUMN "deposit_amount" DECIMAL(10, 2) DEFAULT 0.00;
                        END IF;
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Transactions' AND column_name='deposit_status') THEN
                            ALTER TABLE "Transactions" ADD COLUMN "deposit_status" VARCHAR(50) DEFAULT 'Held';
                        END IF;
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Transactions' AND column_name='platform_fee') THEN
                            ALTER TABLE "Transactions" ADD COLUMN "platform_fee" DECIMAL(10, 2) DEFAULT 0.00;
                        END IF;
                    END $$;
                `);

                // Dynamically add 'On Rent' value to the transactions status enum in Postgres catalog
                try {
                    await sequelize.query('ALTER TYPE "enum_Transactions_status" ADD VALUE \'On Rent\';');
                    console.log('Transactions status enum updated successfully with On Rent');
                } catch (enumErr) {
                    // Ignore error if value already exists or enum is not created yet
                }

                // Dynamically add 'Partially_Refunded' value to the transactions deposit_status enum in Postgres catalog
                try {
                    await sequelize.query('ALTER TYPE "enum_Transactions_deposit_status" ADD VALUE \'Partially_Refunded\';');
                    console.log('Transactions deposit_status enum updated successfully with Partially_Refunded');
                } catch (enumErr) {
                    // Ignore error if value already exists or enum is not created yet
                }

                // Dynamically add 'Rental Damage' value to the disputes reason enum in Postgres catalog
                try {
                    await sequelize.query('ALTER TYPE "enum_Disputes_reason" ADD VALUE \'Rental Damage\';');
                    console.log('Disputes reason enum updated successfully with Rental Damage');
                } catch (enumErr) {
                    // Ignore error if value already exists or enum is not created yet
                }

                // Dynamically add 'PRICE_DROP' value to the notifications type enum in Postgres catalog
                try {
                    await sequelize.query('ALTER TYPE "enum_Notifications_type" ADD VALUE \'PRICE_DROP\';');
                    console.log('Notifications type enum updated successfully with PRICE_DROP');
                } catch (enumErr) {
                    // Ignore error if value already exists or enum is not created yet
                }

                // Dynamically add 'NEW_SELLER_ITEM' value to the notifications type enum in Postgres catalog
                try {
                    await sequelize.query('ALTER TYPE "enum_Notifications_type" ADD VALUE \'NEW_SELLER_ITEM\';');
                    console.log('Notifications type enum updated successfully with NEW_SELLER_ITEM');
                } catch (enumErr) {
                    // Ignore error if value already exists or enum is not created yet
                }

                // Dynamically add 'CHAT' value to the notifications type enum in Postgres catalog
                try {
                    await sequelize.query('ALTER TYPE "enum_Notifications_type" ADD VALUE \'CHAT\';');
                    console.log('Notifications type enum updated successfully with CHAT');
                } catch (enumErr) {
                    // Ignore error if value already exists or enum is not created yet
                }


                // Dynamically add cancelled_by_id column to Transactions table if missing
                try {
                    await sequelize.query('ALTER TABLE "Transactions" ADD COLUMN IF NOT EXISTS cancelled_by_id UUID;');
                    await sequelize.query('ALTER TABLE "Transactions" ADD COLUMN IF NOT EXISTS meetup_pin VARCHAR(10);');
                    await sequelize.query('ALTER TABLE "Transactions" ADD COLUMN IF NOT EXISTS stripe_session_id VARCHAR(255);');
                    await sequelize.query('ALTER TABLE "Transactions" ADD COLUMN IF NOT EXISTS stripe_payment_intent_id VARCHAR(255);');
                    await sequelize.query('ALTER TABLE "Transactions" ADD COLUMN IF NOT EXISTS stripe_payment_status VARCHAR(50);');
                    console.log('Transactions table updated with Stripe and PIN columns');
                } catch (colErr) {
                    // Ignore if column already exists
                }

                // Ensure enum_StudentWhitelists_status type exists safely
                try {
                    await sequelize.query(`
                        DO $$
                        BEGIN
                            IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'enum_StudentWhitelists_status') THEN
                                CREATE TYPE "enum_StudentWhitelists_status" AS ENUM('Active', 'Expired');
                            END IF;
                        END $$;
                    `);
                    console.log('StudentWhitelists enum verified');
                } catch (enumErr) {
                    // Ignore if type already exists
                }

                // Ensure Reviews table NLP moderation columns and enum exist safely
                try {
                    await sequelize.query(`
                        DO $$
                        BEGIN
                            IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'enum_Reviews_status') THEN
                                CREATE TYPE "enum_Reviews_status" AS ENUM('PENDING', 'PUBLISHED', 'FLAGGED_FOR_REVIEW');
                            END IF;
                        END $$;
                        ALTER TABLE "Reviews" ADD COLUMN IF NOT EXISTS "is_toxic" BOOLEAN DEFAULT FALSE;
                        ALTER TABLE "Reviews" ADD COLUMN IF NOT EXISTS "sentiment_score" FLOAT DEFAULT 0.0;
                        ALTER TABLE "Reviews" ADD COLUMN IF NOT EXISTS "flag_reason" VARCHAR(255);
                        ALTER TABLE "Reviews" ADD COLUMN IF NOT EXISTS "status" "enum_Reviews_status" DEFAULT 'PUBLISHED';
                    `);
                    console.log('Reviews table NLP columns verified');
                } catch (reviewMigErr) {
                    console.log('Reviews table migration note:', reviewMigErr.message);
                }

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
import itemRoutes from './routes/itemRoutes.js';
import transactionRoutes from './routes/transactionRoutes.js';
import savedRoutes from './routes/savedRoutes.js';
import messageRoutes from './routes/messageRoutes.js';
import reviewRoutes from './routes/reviewRoutes.js';
import notificationRoutes from './routes/notificationRoutes.js';
import uploadRoutes from './routes/uploadRoutes.js';
import recommendationRoutes from './routes/recommendationRoutes.js';
import { startCronJobs } from './scripts/cronJobs.js';
import categoryRoutes from './routes/categoryRoutes.js';
import subcategoryRoutes from './routes/subcategoryRoutes.js';
import disputeRoutes from './routes/disputeRoutes.js';
import sustainabilityRoutes from './routes/sustainabilityRoutes.js';
import ticketRoutes from './routes/ticketRoutes.js';
import zoneRoutes from './routes/zoneRoutes.js';
import analyticsRoutes from './routes/analyticsRoutes.js';
import onboardingRoutes from './routes/onboardingRoutes.js';
import facultyRoutes from './routes/facultyRoutes.js';
import paymentRoutes from './routes/paymentRoutes.js';

app.use('/api/auth', authRoutes);
app.use('/api/onboarding', onboardingRoutes);
app.use('/api/products', productRoutes);
app.use('/api/items', itemRoutes);
app.use('/api/transactions', transactionRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/saved', savedRoutes);
app.use('/api/messages', messageRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/recommendations', recommendationRoutes);
app.use('/api/interactions', recommendationRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/subcategories', subcategoryRoutes);
app.use('/api/disputes', disputeRoutes);
app.use('/api/sustainability', sustainabilityRoutes);
app.use('/api/tickets', ticketRoutes);
app.use('/api/support_tickets', ticketRoutes);
app.use('/api/zones', zoneRoutes);
app.use('/api/faculties', facultyRoutes);
app.use('/api/profile/analytics', analyticsRoutes);

import { getPolicyByType } from './controllers/systemController.js';
app.get('/api/policies/:type', getPolicyByType);

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
