import sequelize from './src/config/database.js';
import { 
    User, Product, UserInteraction, SavedItem, Report, 
    Message, Review, Dispute, SupportTicket, Transaction, TicketMessage 
} from './src/models/index.js';
import { Op } from 'sequelize';

const dummyUsernames = [
    'tech_alice', 'gadget_bob', 'silicon_charlie', 'byte_david', 'circuit_eve', 'vector_frank', 'pixel_grace',
    'study_ivy', 'nerd_jack', 'library_karen', 'bookworm_leo', 'pencil_mia', 'exam_noah', 'thesis_olivia',
    'runner_paul', 'sneaker_quinn', 'badminton_ryan', 'sporty_sam', 'cycle_tina', 'active_uma'
];

async function undo() {
    try {
        console.log('Connecting to database...');
        await sequelize.authenticate();
        console.log('Connection successful.');

        // 1. Find dummy user IDs
        const dummyUsers = await User.findAll({
            where: {
                username: {
                    [Op.in]: dummyUsernames
                }
            }
        });
        const dummyUserIds = dummyUsers.map(u => u.id);
        console.log(`Found ${dummyUserIds.length} dummy users to delete.`);

        // 2. Find dummy product IDs (those containing picsum.photos)
        const allProducts = await Product.findAll();
        const dummyProducts = allProducts.filter(p => {
            const imgStr = JSON.stringify(p.image_urls || []);
            return imgStr.includes('picsum.photos');
        });
        const dummyProductIds = dummyProducts.map(p => p.id);
        console.log(`Found ${dummyProductIds.length} dummy products to delete.`);

        if (dummyUserIds.length === 0 && dummyProductIds.length === 0) {
            console.log('No dummy ML data found to cleanup. Exit.');
            process.exit(0);
        }

        // 3. Delete dependent rows in child tables to avoid Foreign Key violations
        console.log('Cleaning up child database records...');

        // UserInteractions
        let deletedCount = await UserInteraction.destroy({
            where: {
                [Op.or]: [
                    { user_id: { [Op.in]: dummyUserIds } },
                    { product_id: { [Op.in]: dummyProductIds } }
                ]
            }
        });
        console.log(`- Deleted ${deletedCount} UserInteraction records.`);

        // SavedItems
        deletedCount = await SavedItem.destroy({
            where: {
                [Op.or]: [
                    { user_id: { [Op.in]: dummyUserIds } },
                    { product_id: { [Op.in]: dummyProductIds } }
                ]
            }
        });
        console.log(`- Deleted ${deletedCount} SavedItem records.`);

        // Reports
        deletedCount = await Report.destroy({
            where: {
                [Op.or]: [
                    { reporter_id: { [Op.in]: dummyUserIds } },
                    { reported_user_id: { [Op.in]: dummyUserIds } },
                    { product_id: { [Op.in]: dummyProductIds } }
                ]
            }
        });
        console.log(`- Deleted ${deletedCount} Report records.`);

        // Messages
        deletedCount = await Message.destroy({
            where: {
                [Op.or]: [
                    { sender_id: { [Op.in]: dummyUserIds } },
                    { receiver_id: { [Op.in]: dummyUserIds } }
                ]
            }
        });
        console.log(`- Deleted ${deletedCount} Message records.`);

        // Find transactions related to dummy users/products to clean up reviews/disputes first
        const relatedTransactions = await Transaction.findAll({
            where: {
                [Op.or]: [
                    { buyer_id: { [Op.in]: dummyUserIds } },
                    { seller_id: { [Op.in]: dummyUserIds } },
                    { product_id: { [Op.in]: dummyProductIds } }
                ]
            }
        });
        const transactionIds = relatedTransactions.map(t => t.id);

        // TicketMessages
        deletedCount = await TicketMessage.destroy({
            where: {
                [Op.or]: [
                    { sender_id: { [Op.in]: dummyUserIds } },
                    { reference_id: { [Op.in]: transactionIds } }
                ]
            }
        });
        console.log(`- Deleted ${deletedCount} TicketMessage records.`);

        // Disputes
        deletedCount = await Dispute.destroy({
            where: {
                [Op.or]: [
                    { complainant_id: { [Op.in]: dummyUserIds } },
                    { transaction_id: { [Op.in]: transactionIds } }
                ]
            }
        });
        console.log(`- Deleted ${deletedCount} Dispute records.`);

        // Reviews
        deletedCount = await Review.destroy({
            where: {
                [Op.or]: [
                    { reviewer_id: { [Op.in]: dummyUserIds } },
                    { reviewee_id: { [Op.in]: dummyUserIds } },
                    { transaction_id: { [Op.in]: transactionIds } }
                ]
            }
        });
        console.log(`- Deleted ${deletedCount} Review records.`);

        // SupportTickets
        deletedCount = await SupportTicket.destroy({
            where: {
                user_id: { [Op.in]: dummyUserIds }
            }
        });
        console.log(`- Deleted ${deletedCount} SupportTicket records.`);

        // Transactions
        if (transactionIds.length > 0) {
            deletedCount = await Transaction.destroy({
                where: {
                    id: { [Op.in]: transactionIds }
                }
            });
            console.log(`- Deleted ${deletedCount} Transaction records.`);
        }

        // 4. Delete products
        if (dummyProductIds.length > 0) {
            deletedCount = await Product.destroy({
                where: {
                    id: { [Op.in]: dummyProductIds }
                }
            });
            console.log(`Successfully deleted ${deletedCount} dummy Product records.`);
        }

        // 5. Delete users
        if (dummyUserIds.length > 0) {
            deletedCount = await User.destroy({
                where: {
                    id: { [Op.in]: dummyUserIds }
                }
            });
            console.log(`Successfully deleted ${deletedCount} dummy User records.`);
        }

        console.log('\n🎉 ML Dummy Data cleanup completed successfully!');
        process.exit(0);
    } catch (e) {
        console.error('Cleanup failed with error:', e);
        process.exit(1);
    }
}

undo();
