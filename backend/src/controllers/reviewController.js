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

        // Update Reputation Score (Simple Average)
        // Fetch all reviews for this user to calculate new average
        const reviews = await Review.findAll({ where: { reviewee_id } });
        const totalRating = reviews.reduce((sum, r) => sum + r.rating, 0);
        const newScore = totalRating / reviews.length;

        // Update User Model (assuming reputation_score field exists or we just calculate on fly)
        // For MVP, if User model has this field:
        const user = await User.findByPk(reviewee_id);
        if (user) {
            user.reputation_score = parseFloat(newScore.toFixed(1));
            await user.save();
        }

        res.status(201).json({ review, new_reputation: newScore });
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
                { model: User, as: 'reviewer', attributes: ['full_name'] }
            ],
            order: [['createdAt', 'DESC']]
        });
        res.json(reviews);
    } catch (error) {
        console.error('Get Reviews Error:', error);
        res.status(500).json({ error: 'Failed to fetch reviews' });
    }
};
