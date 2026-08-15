import cron from 'node-cron';
import { Op } from 'sequelize';
import { Transaction, User, Review, StudentWhitelist } from '../models/index.js';
import { executeBackup, pruneOldBackups } from '../utils/backupHelper.js';

export const checkAndExpireOldStudents = async () => {
    try {
        const currentYear = new Date().getFullYear();
        // If (Current Year - enrollment_year > 4), status is Expired
        // That means enrollment_year < (currentYear - 4)
        const cutoffYear = currentYear - 4;
        const [updatedCount] = await StudentWhitelist.update(
            { status: 'Expired' },
            {
                where: {
                    status: 'Active',
                    enrollment_year: {
                        [Op.lt]: cutoffYear
                    }
                }
            }
        );
        if (updatedCount > 0) {
            console.log(`[Cron Whitelist] Automatically marked ${updatedCount} students as Expired (enrollment year < ${cutoffYear}).`);
        }
    } catch (e) {
        console.error('Error in student whitelist auto-expiry check:', e);
    }
};

const updateReputation = async (userId) => {
    try {
        const reviews = await Review.findAll({
            include: [{
                model: Transaction,
                as: 'transaction',
                where: { review_status: 'PUBLISHED' }
            }],
            where: { reviewee_id: userId }
        });

        if (reviews.length > 0) {
            const totalRating = reviews.reduce((sum, r) => sum + r.rating, 0);
            const calculatedScore = totalRating / reviews.length;
            
            const user = await User.findByPk(userId);
            if (user) {
                user.reputation_score = parseFloat(calculatedScore.toFixed(1));
                user.total_reviews = reviews.length;
                await user.save();
            }
        }
    } catch (e) {
        console.error(`Failed to update reputation for user ${userId}:`, e);
    }
};

export const startCronJobs = () => {
    // Run initial whitelist check on startup
    checkAndExpireOldStudents();

    // Auto-expire students daily at midnight
    cron.schedule('0 0 * * *', async () => {
        console.log('Running daily Student Whitelist status auto-expiration check...');
        await checkAndExpireOldStudents();
    });

    // Run every day at midnight
    cron.schedule('0 0 * * *', async () => {
        console.log('Running timeout cron job for Mutual Blind Reviews...');
        try {
            const fourteenDaysAgo = new Date();
            fourteenDaysAgo.setDate(fourteenDaysAgo.getDate() - 14);

            const transactionsToPublish = await Transaction.findAll({
                where: {
                    status: 'Completed',
                    review_status: {
                        [Op.ne]: 'PUBLISHED'
                    },
                    completed_at: {
                        [Op.lt]: fourteenDaysAgo
                    }
                }
            });

            for (const transaction of transactionsToPublish) {
                transaction.review_status = 'PUBLISHED';
                // If neither rated, could set default ratings here
                await transaction.save();

                await updateReputation(transaction.seller_id);
                await updateReputation(transaction.buyer_id);
                console.log(`Transaction ${transaction.id} reviews published via timeout.`);
            }
        } catch (error) {
            console.error('Error in timeout cron job:', error);
        }
    });

    // Automated database backup daily at midnight
    cron.schedule('0 0 * * *', async () => {
        console.log('Running scheduled daily database backup...');
        try {
            const log = await executeBackup('Auto');
            console.log(`Daily auto-backup completed successfully. Backup Log ID: ${log.id}`);
            
            // Clean up files older than 7 days
            await pruneOldBackups();
        } catch (err) {
            console.error('Scheduled database backup failed:', err);
        }
    });
};
