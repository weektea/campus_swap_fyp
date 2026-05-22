import { Review, Transaction, User } from '../models/index.js';

export const createReview = async (req, res) => {
    try {
        const reviewer_id = req.user.id;
        const { transaction_id, reviewee_id, rating, comment } = req.body;

        // Validation
        if (!transaction_id || !reviewee_id || !rating) {
            return res.status(400).json({ error: 'Missing required review fields' });
        }

        // Check if transaction exists and is completed
        const transaction = await Transaction.findByPk(transaction_id);
        if (!transaction) return res.status(404).json({ error: 'Transaction not found' });

        if (transaction.status !== 'Completed') {
            return res.status(400).json({ error: 'Cannot review incomplete transaction' });
        }

        // Verify Reviewer Involvement
        if (transaction.buyer_id !== reviewer_id && transaction.seller_id !== reviewer_id) {
            return res.status(403).json({ error: 'You are not a party in this transaction' });
        }

        // Verify Reviewee Involvement (cannot review random person)
        if (transaction.buyer_id !== reviewee_id && transaction.seller_id !== reviewee_id) {
            return res.status(400).json({ error: 'Reviewee was not a party in this transaction' });
        }

        // Prevent Self-Review
        if (reviewer_id === reviewee_id) {
            return res.status(400).json({ error: 'Cannot review yourself' });
        }

        // Check for double review (Optional: one review per transaction per user)
        const existingReview = await Review.findOne({ where: { transaction_id, reviewer_id } });
        if (existingReview) {
            return res.status(400).json({ error: 'You have already reviewed this transaction' });
        }

        // Create Review
        const review = await Review.create({
            transaction_id,
            reviewer_id,
            reviewee_id,
            rating,
            comment
        });

        // Sync to Transaction (Denormalization) and Advance State Machine
        if (transaction.buyer_id === reviewer_id) {
            transaction.rating_from_buyer = rating;
            transaction.buyer_comment = comment; // Save comment to transaction table as well if needed, although review table holds it.

            if (transaction.review_status === 'PENDING_REVIEWS') {
                transaction.review_status = 'BUYER_REVIEWED';
            } else if (transaction.review_status === 'SELLER_REVIEWED') {
                transaction.review_status = 'PUBLISHED';
            }
        } else {
            transaction.rating_from_seller = rating;
            transaction.seller_comment = comment;

            if (transaction.review_status === 'PENDING_REVIEWS') {
                transaction.review_status = 'SELLER_REVIEWED';
            } else if (transaction.review_status === 'BUYER_REVIEWED') {
                transaction.review_status = 'PUBLISHED';
            }
        }
        await transaction.save();

        let newScore = null;

        // ONLY Update Reputation Score if the review state is PUBLISHED
        if (transaction.review_status === 'PUBLISHED') {
            const updateReputation = async (userId) => {
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
                    return calculatedScore;
                }
                return null;
            };

            // Recalculate for both buyer and seller since both are now published
            await updateReputation(transaction.buyer_id);
            newScore = await updateReputation(transaction.seller_id);
        }

        res.status(201).json({ review, new_reputation: newScore, review_status: transaction.review_status });
    } catch (error) {
        console.error('Create Review Error:', error);
        res.status(500).json({ error: 'Failed to create review' });
    }
};

export const getUserReviews = async (req, res) => {
    try {
        const { user_id } = req.params;
        const reviews = await Review.findAll({
            where: { reviewee_id: user_id },
            include: [
                { model: User, as: 'reviewer', attributes: ['full_name'] },
                { model: Transaction, as: 'transaction', attributes: ['review_status'] }
            ],
            order: [['createdAt', 'DESC']]
        });

        // Mask reviews that are not yet PUBLISHED
        const maskedReviews = reviews.map(r => {
            const reviewObj = r.toJSON();
            if (reviewObj.transaction && reviewObj.transaction.review_status !== 'PUBLISHED') {
                return {
                    ...reviewObj,
                    rating: null,
                    comment: 'Awaiting the other party to submit their review to unlock.',
                    is_hidden: true
                };
            }
            return reviewObj;
        });

        res.json(maskedReviews);
    } catch (error) {
        console.error('Get Reviews Error:', error);
        res.status(500).json({ error: 'Failed to fetch reviews' });
    }
};
