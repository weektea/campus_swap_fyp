import cron from 'node-cron';
import { Op } from 'sequelize';
import { Transaction, User } from '../models/index.js';

const updateReputation = async (userId) => {
    const transactions = await Transaction.findAll({
        where: { review_status: 'PUBLISHED' }
    });
    let totalScore = 0;
    let count = 0;
    for (const t of transactions) {
        if (t.seller_id === userId && t.rating_from_buyer) {
            totalScore += t.rating_from_buyer;
            count++;
        } else if (t.buyer_id === userId && t.rating_from_seller) {
            totalScore += t.rating_from_seller;
            count++;
        }
    }
    if (count > 0) {
        const newScore = (totalScore / count).toFixed(2);
        await User.update({ reputation_score: newScore }, { where: { id: userId } });
    }
};

export const startCronJobs = () => {
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
};
