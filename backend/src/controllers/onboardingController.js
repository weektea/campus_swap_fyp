import { User, Category, SubCategory } from '../models/index.js';
import axios from 'axios';

const ML_SERVICE_URL = process.env.ML_SERVICE_URL || 'http://localhost:5000';

// GET /api/onboarding/options
export const getOnboardingOptions = async (req, res) => {
    try {
        // Fetch active sub-categories dynamically from DB with parent Category info
        const subcategoriesDB = await SubCategory.findAll({
            attributes: ['id', 'name', 'category_id'],
            include: [{
                model: Category,
                as: 'categoryModel',
                attributes: ['name']
            }],
            order: [['name', 'ASC']]
        });

        // Subcategory emoji mapper
        const subEmojiMap = {
            'Audio': '🎧',
            'Laptops': '💻',
            'PC Accessories': '⌨️',
            'Smartphones': '📱',
            'Tablets': '📲',
            'Bags & Luggage': '🎒',
            'Clothing': '👕',
            'Fashion Accessories': '🕶️',
            'Shoes': '👟',
            'Appliances': '🔌',
            'Chairs': '🪑',
            'Sofas': '🛋️',
            'Storage': '📦',
            'Tables & Desks': '🖥️',
            'Books': '📚',
            'Calculators': '🧮',
            'Notes & Past Papers': '📝',
            'Apparel': '🎽',
            'Bicycles': '🚲',
            'Equipment': '⚽',
            'Art Supplies': '🎨',
            'Paper': '📄',
            'Writing': '✏️',
            'Cosmetics & Beauty': '💄',
            'Drinkware': '🥤',
            'Miscellaneous': '🏷️'
        };

        const categoryEmojiMap = {
            'Electronics & Gadgets': '📱',
            'Books & Study Materials': '📚',
            'Fashion & Accessories': '👕',
            'Furniture & Appliances': '🛋️',
            'Sports': '🏀',
            'Stationery': '✏️',
            'Others': '📦'
        };

        const subcategories = subcategoriesDB.map(sub => {
            const catName = sub.categoryModel ? sub.categoryModel.name : '';
            return {
                id: sub.id,
                name: sub.name,
                category_id: sub.category_id,
                category_name: catName,
                icon: subEmojiMap[sub.name] || categoryEmojiMap[catName] || '🏷️'
            };
        });

        const intents = [
            {
                id: 'buy',
                emoji: '🛍️',
                title: "I'm looking to buy",
                subtitle: 'Discover great deals on textbooks, electronics, & dorm items'
            },
            {
                id: 'rent',
                emoji: '🔑',
                title: 'I want to rent items',
                subtitle: 'Short-term & semester rentals for gadgets, tools & books'
            },
            {
                id: 'sell',
                emoji: '📦',
                title: 'I want to sell items',
                subtitle: 'Declutter your room and earn extra cash from verified peers'
            },
            {
                id: 'browse',
                emoji: '👀',
                title: 'Just browsing around',
                subtitle: 'Explore campus market trends & eco-friendly swaps'
            }
        ];

        res.json({
            intents,
            subcategories,
            categories: subcategories // backward compatibility
        });
    } catch (error) {
        console.error('Get Onboarding Options Error:', error);
        res.status(500).json({ error: 'Failed to retrieve onboarding options' });
    }
};

// POST /api/onboarding/preferences
export const submitOnboardingPreferences = async (req, res) => {
    try {
        const { primary_intent, preference_tags } = req.body;
        const userId = req.user.id;

        const user = await User.findByPk(userId);
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        const validIntents = ['buy', 'sell', 'browse', 'rent'];
        const intent = validIntents.includes(primary_intent) ? primary_intent : 'browse';
        const tags = Array.isArray(preference_tags) ? preference_tags : [];

        user.primary_intent = intent;
        user.preference_tags = tags;
        user.is_onboarded = true;
        await user.save();

        // Safe ML microservice sync fallback (Wrapped in try-catch to prevent app crash)
        try {
            await axios.post(`${ML_SERVICE_URL}/api/user/sync-preferences`, {
                user_id: String(userId),
                primary_intent: intent,
                preference_tags: tags
            }, { timeout: 3000 });
            console.log(`[ML-SYNC] Successfully synced onboarding preferences for user ${userId}`);
        } catch (mlErr) {
            console.warn(`[ML-SYNC] Warning: Could not sync preferences to Python ML service (${mlErr.message}). Onboarding proceeding cleanly.`);
        }

        const userJSON = user.toJSON();
        delete userJSON.password_hash;

        res.status(200).json({
            message: 'Onboarding preferences saved successfully',
            user: userJSON
        });
    } catch (error) {
        console.error('Submit Onboarding Preferences Error:', error);
        res.status(500).json({ error: 'Failed to save onboarding preferences' });
    }
};
