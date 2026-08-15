import { Review, Transaction, User, Product } from '../models/index.js';
import axios from 'axios';

const ML_SERVICE_URL = process.env.ML_SERVICE_URL || 'http://localhost:5000';

// Fallback toxicity checker if ML service is unreachable
const LOCAL_TOXIC_KEYWORDS = [
    'fuck', 'shit', 'bitch', 'bastard', 'asshole', 'idiot', 'moron',
    'stupid', 'dumb', 'scum', 'loser', 'trash', 'crap', 'bullshit', 'dick',
    'cunt', 'piss', 'slut', 'whore', 'scammer', 'scam', 'fraud', 'thief',
    'cheat', 'cheater', 'liar', 'robbed', 'fake', 'stole', 'kill', 'die'
];

export const analyzeTextWithNLP = async (text) => {
    if (!text || !text.trim()) {
        return { is_toxic: false, sentiment_score: 0.0, flag_reason: null };
    }
    try {
        const response = await axios.post(`${ML_SERVICE_URL}/nlp/analyze-review`, { text }, { timeout: 3000 });
        if (response.data) {
            return {
                is_toxic: Boolean(response.data.is_toxic),
                sentiment_score: parseFloat(response.data.sentiment_score || 0.0),
                flag_reason: response.data.flag_reason || null
            };
        }
    } catch (err) {
        console.warn('[NLP Microservice Warning] Could not reach ML service, using lexical fallback:', err.message);
    }

    // Local fallback
    const lower = text.toLowerCase();
    const matched = LOCAL_TOXIC_KEYWORDS.filter(k => new RegExp(`\\b${k}\\b`, 'i').test(lower));
    if (matched.length > 0) {
        return {
            is_toxic: true,
            sentiment_score: -0.65,
            flag_reason: `Abusive / profane keywords detected: [${matched.slice(0, 3).join(', ')}]`
        };
    }
    return { is_toxic: false, sentiment_score: 0.1, flag_reason: null };
};

export const updateReputation = async (userId) => {
    // Only calculate reputation from PUBLISHED, non-toxic reviews
    const reviews = await Review.findAll({
        include: [{
            model: Transaction,
            as: 'transaction',
            where: { review_status: 'PUBLISHED' }
        }],
        where: { 
            reviewee_id: userId,
            status: 'PUBLISHED',
            is_toxic: false
        }
    });

    const user = await User.findByPk(userId);
    if (!user) return null;

    if (reviews.length > 0) {
        const totalRating = reviews.reduce((sum, r) => sum + r.rating, 0);
        const calculatedScore = totalRating / reviews.length;
        user.reputation_score = parseFloat(calculatedScore.toFixed(1));
        user.total_reviews = reviews.length;
        await user.save();
        return user.reputation_score;
    } else {
        // Default reputation if no valid published reviews
        user.reputation_score = 5.0;
        user.total_reviews = 0;
        await user.save();
        return 5.0;
    }
};

export const autoPublishExpiredReviews = async () => {
    try {
        const { Op } = await import('sequelize');
        const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
        const expiredTransactions = await Transaction.findAll({
            where: {
                review_status: ['BUYER_REVIEWED', 'SELLER_REVIEWED'],
                updatedAt: { [Op.lte]: sevenDaysAgo }
            }
        });

        for (const tx of expiredTransactions) {
            tx.review_status = 'PUBLISHED';
            await tx.save();
            await updateReputation(tx.buyer_id);
            await updateReputation(tx.seller_id);
        }
    } catch (e) {
        console.error('Failed to auto-publish expired reviews:', e);
    }
};

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

        // Check for double review
        const existingReview = await Review.findOne({ where: { transaction_id, reviewer_id } });
        if (existingReview) {
            return res.status(400).json({ error: 'You have already reviewed this transaction' });
        }

        // 1. Run Automated NLP Toxicity & Sentiment Moderation
        const nlpResult = await analyzeTextWithNLP(comment);
        const isToxic = nlpResult.is_toxic;
        const reviewStatus = isToxic ? 'FLAGGED_FOR_REVIEW' : 'PUBLISHED';

        // 2. Create Review Record
        const review = await Review.create({
            transaction_id,
            reviewer_id,
            reviewee_id,
            rating,
            comment,
            is_toxic: isToxic,
            sentiment_score: nlpResult.sentiment_score,
            flag_reason: nlpResult.flag_reason,
            status: reviewStatus
        });

        // 3. Preserve Mutual Blind Review State Machine on Transaction
        if (transaction.buyer_id === reviewer_id) {
            transaction.rating_from_buyer = rating;
            transaction.buyer_comment = comment;

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

        // ONLY Update Reputation Score if the review state is PUBLISHED on transaction
        // (updateReputation will automatically filter out flagged toxic reviews)
        if (transaction.review_status === 'PUBLISHED') {
            await updateReputation(transaction.buyer_id);
            newScore = await updateReputation(transaction.seller_id);
        }

        res.status(201).json({
            review,
            new_reputation: newScore,
            review_status: transaction.review_status,
            is_flagged: isToxic,
            moderation_note: isToxic
                ? 'Your review contains sensitive language and has been submitted for moderator review before public display.'
                : null
        });
    } catch (error) {
        console.error('Create Review Error:', error);
        res.status(500).json({ error: 'Failed to create review' });
    }
};

export const getUserReviews = async (req, res) => {
    try {
        await autoPublishExpiredReviews();

        const { user_id } = req.params;
        const reviews = await Review.findAll({
            where: { 
                reviewee_id: user_id,
                status: 'PUBLISHED',
                is_toxic: false
            },
            include: [
                { model: User, as: 'reviewer', attributes: ['username', 'full_name'] },
                { 
                    model: Transaction, 
                    as: 'transaction', 
                    attributes: ['review_status', 'product_id'],
                    where: { review_status: 'PUBLISHED' },
                    include: [
                        { model: Product, as: 'product', attributes: ['title'] }
                    ]
                }
            ],
            order: [['createdAt', 'DESC']]
        });

        res.json(reviews);
    } catch (error) {
        console.error('Get Reviews Error:', error);
        res.status(500).json({ error: 'Failed to fetch reviews' });
    }
};

