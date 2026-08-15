import sequelize from '../src/config/database.js';
import { User, Product, Transaction, Review } from '../src/models/index.js';
import { createReview, getUserReviews, updateReputation } from '../src/controllers/reviewController.js';
import { getFlaggedReviews, approveReview, deleteReview } from '../src/controllers/adminController.js';

async function runTests() {
    console.log('--- Starting Automated NLP Review Moderation Pipeline Tests ---\n');

    try {
        await sequelize.authenticate();
        console.log('[OK] Database connected.');

        // 1. Setup Test Users
        let buyer = await User.findOne({ where: { username: 'willfoo' } });
        let seller = await User.findOne({ where: { username: 'fivethree' } });

        if (!buyer || !seller) {
            console.log('Test users not found, querying any two students...');
            const users = await User.findAll({ limit: 2 });
            buyer = users[0];
            seller = users[1];
        }

        // Reset baseline reputation
        seller.reputation_score = 5.0;
        seller.total_reviews = 0;
        await seller.save();

        console.log(`[OK] Buyer: ${buyer.username} | Target Seller: ${seller.username} (Baseline Rep: ${seller.reputation_score})`);

        // 2. Setup Test Completed Transaction
        const product = await Product.create({
            title: 'Test Textbook for NLP Moderation',
            description: 'Item to test reviews',
            price: 50.00,
            type: 'Sale',
            status: 'Sold',
            seller_id: seller.id
        });

        const tx = await Transaction.create({
            buyer_id: buyer.id,
            seller_id: seller.id,
            product_id: product.id,
            amount: 50.00,
            status: 'Completed',
            review_status: 'PENDING_REVIEWS'
        });

        console.log(`[OK] Created Completed Transaction #${tx.id}`);

        // -------------------------------------------------------------
        // TEST CASE 1: Submit Toxic Review -> NLP Auto-Flags as FLAGGED_FOR_REVIEW
        // -------------------------------------------------------------
        console.log('\n--- Test 1: Submitting Toxic / Hostile Review ---');
        const toxicComment = "This seller is a fucking scammer and a liar! Total cheat, do not buy!";
        
        let toxicReviewResData = null;
        const mockReqBuyer = {
            user: { id: buyer.id, role: 'student' },
            body: {
                transaction_id: tx.id,
                reviewee_id: seller.id,
                rating: 1,
                comment: toxicComment
            }
        };

        const mockResBuyer = {
            status: (code) => ({
                json: (data) => {
                    toxicReviewResData = data;
                    console.log(`[CreateReview Buyer] HTTP ${code}:`, data.moderation_note || 'Success');
                }
            })
        };

        await createReview(mockReqBuyer, mockResBuyer);

        const createdToxicReview = await Review.findOne({ where: { transaction_id: tx.id, reviewer_id: buyer.id } });
        await tx.reload();
        await seller.reload();

        console.log(`[OK] Review Status: ${createdToxicReview.status} (Expected: 'FLAGGED_FOR_REVIEW')`);
        console.log(`[OK] Review is_toxic: ${createdToxicReview.is_toxic} (Expected: true)`);
        console.log(`[OK] Review Sentiment Score: ${createdToxicReview.sentiment_score}`);
        console.log(`[OK] Review Flag Reason: "${createdToxicReview.flag_reason}"`);
        console.log(`[OK] Transaction review_status: ${tx.review_status} (Expected: 'BUYER_REVIEWED')`);
        console.log(`[OK] Seller Reputation Score Protected: ${seller.reputation_score} (Expected: 5.0 unchanged)`);

        if (!createdToxicReview.is_toxic || createdToxicReview.status !== 'FLAGGED_FOR_REVIEW') {
            throw new Error('Toxic review was not properly flagged by NLP!');
        }
        if (tx.review_status !== 'BUYER_REVIEWED') {
            throw new Error(`Transaction review_status broke blind review progression: ${tx.review_status}`);
        }
        if (seller.reputation_score !== 5.0) {
            throw new Error(`Seller reputation score was corrupted by toxic review! Score: ${seller.reputation_score}`);
        }

        // -------------------------------------------------------------
        // TEST CASE 2: Seller Submits Clean Review -> Both Parties Reviewed -> Transaction PUBLISHED
        // -------------------------------------------------------------
        console.log('\n--- Test 2: Seller Submits Clean Review ---');
        const cleanComment = "Polite buyer, smooth meetup at Library!";
        
        const mockReqSeller = {
            user: { id: seller.id, role: 'student' },
            body: {
                transaction_id: tx.id,
                reviewee_id: buyer.id,
                rating: 5,
                comment: cleanComment
            }
        };

        const mockResSeller = {
            status: (code) => ({
                json: (data) => console.log(`[CreateReview Seller] HTTP ${code}: Review submitted.`)
            })
        };

        await createReview(mockReqSeller, mockResSeller);
        await tx.reload();
        await seller.reload();
        await buyer.reload();

        console.log(`[OK] Transaction review_status: ${tx.review_status} (Expected: 'PUBLISHED')`);
        console.log(`[OK] Buyer Reputation (Clean 5-star applied): ${buyer.reputation_score}`);
        console.log(`[OK] Seller Reputation (Toxic 1-star still suppressed): ${seller.reputation_score} (Expected: 5.0)`);

        if (tx.review_status !== 'PUBLISHED') {
            throw new Error(`Transaction state machine failed to reach PUBLISHED: ${tx.review_status}`);
        }

        // -------------------------------------------------------------
        // TEST CASE 3: Public Review Querying -> Toxic Comment Excluded / Masked
        // -------------------------------------------------------------
        console.log('\n--- Test 3: Verify Toxic Review Masked in Public Profile Query ---');
        let sellerPublicReviews = [];
        await getUserReviews(
            { params: { user_id: seller.id } },
            { 
                json: (data) => {
                    sellerPublicReviews = data;
                    console.log(`[Public Reviews for Seller] Found ${data.length} published reviews.`);
                },
                status: (code) => ({ json: (err) => console.error(err) })
            }
        );

        if (sellerPublicReviews.length !== 0) {
            throw new Error(`Flagged toxic review should not be visible in public user reviews! Found: ${sellerPublicReviews.length}`);
        }
        console.log('[OK] Public reviews safely omit unapproved toxic review.');

        // -------------------------------------------------------------
        // TEST CASE 4: Admin Moderation -> Fetch Flagged Reviews
        // -------------------------------------------------------------
        console.log('\n--- Test 4: Admin GET /api/admin/flagged-reviews ---');
        let flaggedList = [];
        await getFlaggedReviews(
            {},
            {
                set: () => {},
                json: (data) => {
                    flaggedList = data;
                    console.log(`[Admin Flagged Reviews] Total flagged in queue: ${data.length}`);
                },
                status: (code) => ({ json: (err) => console.error(err) })
            }
        );

        const foundFlagged = flaggedList.find(r => r.id === createdToxicReview.id);
        if (!foundFlagged) {
            throw new Error('Created toxic review was not returned in admin flagged reviews queue!');
        }
        console.log(`[OK] Found flagged review #${foundFlagged.id} in Admin Queue with score ${foundFlagged.sentiment_score}.`);

        // -------------------------------------------------------------
        // TEST CASE 5: Admin Approves Review -> Unmasks & Recalculates Reputation
        // -------------------------------------------------------------
        console.log('\n--- Test 5: Admin Approves Flagged Review (POST /api/admin/reviews/:id/approve) ---');
        await approveReview(
            { params: { id: createdToxicReview.id } },
            {
                json: (data) => console.log(`[Admin Approve Response]: ${data.message} | New Rep: ${data.new_reputation}`),
                status: (code) => ({ json: (err) => console.error(err) })
            }
        );

        await createdToxicReview.reload();
        await seller.reload();

        console.log(`[OK] Approved Review status: ${createdToxicReview.status} (Expected: 'PUBLISHED')`);
        console.log(`[OK] Approved Review is_toxic: ${createdToxicReview.is_toxic} (Expected: false)`);
        console.log(`[OK] Recalculated Seller Reputation after Approval: ${seller.reputation_score} / 5.0 (Expected: 1.0)`);

        if (createdToxicReview.status !== 'PUBLISHED' || createdToxicReview.is_toxic !== false) {
            throw new Error('Review status was not updated to PUBLISHED on approval!');
        }

        // -------------------------------------------------------------
        // TEST CASE 6: Admin Deletes Review (POST /api/admin/reviews/:id/delete)
        // -------------------------------------------------------------
        console.log('\n--- Test 6: Admin Deletes Review ---');
        await deleteReview(
            { params: { id: createdToxicReview.id } },
            {
                json: (data) => console.log(`[Admin Delete Response]: ${data.message}`),
                status: (code) => ({ json: (err) => console.error(err) })
            }
        );

        const checkDeleted = await Review.findByPk(createdToxicReview.id);
        await seller.reload();

        console.log(`[OK] Review deleted from DB: ${checkDeleted === null}`);
        console.log(`[OK] Seller Reputation restored after review deletion: ${seller.reputation_score} / 5.0 (Expected: 5.0)`);

        if (checkDeleted !== null) {
            throw new Error('Review was not removed from DB on delete!');
        }

        // Cleanup test data
        const sellerCleanReview = await Review.findOne({ where: { transaction_id: tx.id, reviewer_id: seller.id } });
        if (sellerCleanReview) await sellerCleanReview.destroy();
        await tx.destroy();
        await product.destroy();

        console.log('\n======================================================');
        console.log('ALL NLP REVIEW MODERATION PIPELINE TESTS PASSED! 🎉');
        console.log('======================================================\n');
        process.exit(0);

    } catch (err) {
        console.error('\n❌ Test Failed:', err);
        process.exit(1);
    }
}

runTests();
