import { Transaction, Product, User, Review, Category, SubCategory, Dispute } from '../models/index.js';
import { createNotification } from './notificationController.js';
import { emitToUser, emitToAdmins } from '../config/socket.js';

export const createTransaction = async (req, res) => {
    try {
        const { buyer_id, seller_id, product_id, meetup_location, scheduled_at } = req.body;
        let amount = req.body.amount;

        // Validate
        if (!buyer_id || !seller_id || !product_id || amount === undefined || amount === null) {
            return res.status(400).json({ error: 'Missing required transaction details' });
        }

        // Check Product Availability
        const product = await Product.findByPk(product_id);
        if (!product) {
            return res.status(404).json({ error: 'Product not found' });
        }
        if (product.status !== 'Available') {
            return res.status(400).json({ error: 'Product is no longer available' });
        }

        // UC17 Rental Constraints
        let { rental_start_date, rental_end_date } = req.body;
        if (product.type === 'Rent') {
            if (!rental_start_date || !rental_end_date) {
                return res.status(400).json({ error: 'Rental start and end dates are required for this product.' });
            }
            const startDate = new Date(rental_start_date);
            const endDate = new Date(rental_end_date);
            const diffTime = Math.abs(endDate - startDate);
            const rentalDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
            
            if (product.max_rental_duration && rentalDays > product.max_rental_duration) {
                return res.status(400).json({ error: `Cannot exceed maximum rental duration of ${product.max_rental_duration} days.` });
            }
            // Auto overwrite amount securely
            amount = (rentalDays * parseFloat(product.rental_price_per_day)).toFixed(2);
        }

        // Atomic Reservation to prevent double-booking
        const [affectedRows] = await Product.update(
            { status: 'Reserved' },
            { where: { id: product_id, status: 'Available' } }
        );

        if (affectedRows === 0) {
            return res.status(409).json({ error: 'Product was just reserved or is no longer available.' });
        }

        // Create Transaction
        const transaction = await Transaction.create({
            buyer_id,
            seller_id,
            product_id,
            amount,
            meetup_location,
            scheduled_at,
            rental_start_date,
            rental_end_date,
            status: 'Pending'
        });

        // Notify Seller
        await createNotification(
            seller_id,
            product.type === 'Rent' ? 'New Rental Request' : 'New Purchase Request',
            `A student wants to ${product.type === 'Rent' ? 'rent' : 'buy'} your item for RM ${amount}.`,
            'Transaction',
            transaction.id
        );

        res.status(201).json(transaction);
    } catch (error) {
        console.error('Create Transaction Error:', error);
        res.status(500).json({ error: 'Failed to create transaction' });
    }
};

export const getUserTransactions = async (req, res) => {
    try {
        const { user_id } = req.params;
        const { type } = req.query; // 'buying' or 'selling'

        const whereClause = type === 'selling'
            ? { seller_id: user_id }
            : { buyer_id: user_id };

        const transactions = await Transaction.findAll({
            where: whereClause,
            include: [
                { model: Product, as: 'product' },
                {
                    model: User,
                    as: type === 'selling' ? 'buyer' : 'seller',
                    attributes: ['id', 'username', 'full_name', 'email']
                },
                {
                    model: Review,
                    as: 'reviews', // Need to check association alias
                    required: false
                }
            ],
            order: [['createdAt', 'DESC']]
        });
        const maskedTransactions = transactions.map(tx => {
            const txObj = tx.toJSON();
            
            // Filter reviews in memory to match reviewer_id = user_id (avoid Sequelize query filtering gotcha)
            if (txObj.reviews) {
                txObj.reviews = txObj.reviews.filter(r => r.reviewer_id === user_id);
            }

            if (txObj.review_status !== 'PUBLISHED') {
                if (type === 'buying') {
                    txObj.rating_from_seller = null;
                    txObj.seller_comment = "Awaiting the other party to submit their review to unlock.";
                } else if (type === 'selling') {
                    txObj.rating_from_buyer = null;
                    txObj.buyer_comment = "Awaiting the other party to submit their review to unlock.";
                }
            }
            return txObj;
        });

        res.json(maskedTransactions);
    } catch (error) {
        console.error('Get Transactions Error:', error);
        res.status(500).json({ error: 'Failed to fetch transactions' });
    }
};

export const getTransactionById = async (req, res) => {
    try {
        const { id } = req.params;
        const transaction = await Transaction.findByPk(id, {
            include: [
                { model: Product, as: 'product' },
                { model: User, as: 'buyer', attributes: ['id', 'username', 'full_name', 'email', 'profile_image_url'] },
                { model: User, as: 'seller', attributes: ['id', 'username', 'full_name', 'email', 'profile_image_url'] },
                { model: Review, as: 'reviews', required: false }
            ]
        });

        if (!transaction) return res.status(404).json({ error: 'Transaction not found' });

        // Security check (use string comparison for UUID/int compatibility)
        const reqUserId = String(req.user.id);
        if (reqUserId !== String(transaction.buyer_id) && reqUserId !== String(transaction.seller_id)) {
             return res.status(403).json({ error: 'Not authorized to view this transaction' });
        }

        const txObj = transaction.toJSON();
        if (txObj.review_status !== 'PUBLISHED') {
            if (reqUserId === String(txObj.buyer_id)) {
                txObj.rating_from_seller = null;
                txObj.seller_comment = "Awaiting the other party to submit their review to unlock.";
                if (txObj.reviews) {
                    txObj.reviews = txObj.reviews.filter(r => String(r.reviewer_id) === reqUserId);
                }
            } else if (reqUserId === String(txObj.seller_id)) {
                txObj.rating_from_buyer = null;
                txObj.buyer_comment = "Awaiting the other party to submit their review to unlock.";
                if (txObj.reviews) {
                    txObj.reviews = txObj.reviews.filter(r => String(r.reviewer_id) === reqUserId);
                }
            }
        }

        res.json(txObj);
    } catch (error) {
        console.error('Get Transaction By ID Error:', error);
        res.status(500).json({ error: 'Failed to fetch transaction details' });
    }
};

const CARBON_SAVINGS = {
    // 1. Electronics & Gadgets
    'Audio': 15.0,
    'Laptops': 250.0,
    'PC Accessories': 10.0,
    'Smartphones': 65.0,
    'Tablets': 110.0,
    'Electronics_Others': 50.0,
    'Electronics & Gadgets': 55.5,
    
    // 2. Fashion & Accessories
    'Bags & Luggage': 20.0,
    'Clothing': 15.0,
    'Fashion Accessories': 5.0,
    'Shoes': 15.0,
    'Fashion & Accessories': 8.2,
    
    // 3. Furniture & Appliances
    'Appliances': 80.0,
    'Chairs': 35.0,
    'Sofas': 150.0,
    'Storage': 50.0,
    'Tables & Desks': 60.0,
    'Furniture_Others': 40.0,
    'Furniture & Appliances': 30.0,
    
    // 4. Books & Study Materials
    'Books': 2.5,
    'Calculators': 8.0,
    'Notes & Past Papers': 1.5,
    'Books_Others': 2.0,
    'Books & Study Materials': 3.5,
    
    // 5. Sports
    'Apparel': 10.0,
    'Bicycles': 120.0,
    'Equipment': 20.0,
    'Sports_Others': 15.0,
    'Sports': 15.0,
    
    // 6. Stationery
    'Art Supplies': 3.0,
    'Paper': 5.0,
    'Writing': 0.5,
    'Stationery_Others': 2.0,
    'Stationery': 2.0,
    
    // 7. Others
    'Cosmetics & Beauty': 2.0,
    'Drinkware': 5.0,
    'Miscellaneous': 5.0,
    'Others': 10.0
};

export const getCarbonValue = (category, subCategory, product = null) => {
    // Try database factors first
    if (product) {
        if (product.subcategoryModel && product.subcategoryModel.carbon_conversion_factor !== undefined && product.subcategoryModel.carbon_conversion_factor !== null) {
            const factor = parseFloat(product.subcategoryModel.carbon_conversion_factor);
            if (factor > 0) return factor;
        }
        if (product.categoryModel && product.categoryModel.carbon_conversion_factor !== undefined && product.categoryModel.carbon_conversion_factor !== null) {
            const factor = parseFloat(product.categoryModel.carbon_conversion_factor);
            if (factor > 0) return factor;
        }
    }

    if (subCategory && CARBON_SAVINGS[subCategory] !== undefined) {
        return CARBON_SAVINGS[subCategory];
    }
    
    // Fallback based on category name
    if (category && CARBON_SAVINGS[category] !== undefined) {
        return CARBON_SAVINGS[category];
    }
    
    // Legacy category maps
    const categoryMapping = {
        'Books': 'Books_Others',
        'Electronics': 'Electronics_Others',
        'Fashion': 'Fashion & Accessories',
        'Furniture': 'Furniture_Others',
        'Stationery': 'Stationery_Others',
        'Sports': 'Sports_Others',
        'Clothing & Fashion': 'Fashion & Accessories',
        'Textbooks & Stationery': 'Books & Study Materials',
        'Vehicles': 'Sports_Others'
    };
    
    if (category && categoryMapping[category]) {
        const mappedCat = categoryMapping[category];
        if (CARBON_SAVINGS[mappedCat] !== undefined) {
            return CARBON_SAVINGS[mappedCat];
        }
    }
    
    return 2.5; // Absolute Fallback
};

export const updateTransactionStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body; // 'Completed', 'Cancelled', 'Scheduled'

        const transaction = await Transaction.findByPk(id);
        if (!transaction) {
            return res.status(404).json({ error: 'Transaction not found' });
        }

        const oldStatus = transaction.status;

        // State Machine Validation
        const validTransitions = {
            'Pending': ['Scheduled', 'Cancelled'],
            'Scheduled': ['To Confirm', 'Cancelled'],
            'To Confirm': ['Completed', 'Cancelled', 'Disputed'],
            'Completed': [],
            'Cancelled': [],
            'Disputed': []
        };

        if (!validTransitions[oldStatus] || !validTransitions[oldStatus].includes(status)) {
            return res.status(400).json({ error: `Invalid transition from ${oldStatus} to ${status}` });
        }

        // Atomic status update to prevent race conditions (double clicks)
        const [affectedRows] = await Transaction.update(
            { status: status },
            { where: { id: id, status: oldStatus } }
        );

        if (affectedRows === 0) {
            return res.status(409).json({ error: 'Transaction status has already been updated.' });
        }

        // Reload to sync the instance in memory for subsequent operations
        await transaction.reload();

        const requesterId = req.user?.id;
        const otherPartyId = requesterId === transaction.buyer_id ? transaction.seller_id : transaction.buyer_id;

        // If completed, mark product as Sold or Reserved for rent
        if (status === 'Completed') {
            await Product.update(
                { status: 'Sold' },
                { where: { id: transaction.product_id } }
            );
            
            // Calculate Carbon Savings
            const product = await Product.findByPk(transaction.product_id, {
                include: [
                    { model: Category, as: 'categoryModel' },
                    { model: SubCategory, as: 'subcategoryModel' }
                ]
            });
            
            let co2Saved = 0.0;
            if (product) {
                 const catName = product.categoryModel ? product.categoryModel.name : product.category;
                 const subCatName = product.subcategoryModel ? product.subcategoryModel.name : null;
                 co2Saved = getCarbonValue(catName, subCatName, product);
            }

            transaction.completed_at = new Date();
            transaction.review_status = 'PENDING_REVIEWS';
            transaction.awarded_carbon_points = co2Saved;
            await transaction.save();
            
            if (product) {
                 if (transaction.buyer_id === transaction.seller_id) {
                     // Self-trade: only increment once to prevent double-counting
                     await User.increment(
                         { items_reused: 1, total_carbon_saved: co2Saved, carbon_saved_buyer: co2Saved, carbon_saved_seller: co2Saved },
                         { where: { id: transaction.buyer_id } }
                     );
                 } else {
                     // Update Buyer
                     await User.increment(
                         { items_reused: 1, total_carbon_saved: co2Saved, carbon_saved_buyer: co2Saved },
                         { where: { id: transaction.buyer_id } }
                     );
                     
                     // Update Seller
                     await User.increment(
                         { items_reused: 1, total_carbon_saved: co2Saved, carbon_saved_seller: co2Saved },
                         { where: { id: transaction.seller_id } }
                     );
                 }
            }

            // Notify Buyer that Seller completed it
            await createNotification(
                transaction.buyer_id,
                'Transaction Completed',
                `Seller has verified the completion. You can now rate your experience!`,
                'Transaction',
                transaction.id
            );
        }

        // If cancelled, mark product as Available
        if (status === 'Cancelled') {
            await Product.update(
                { status: 'Available' },
                { where: { id: transaction.product_id } }
            );
            // Notify the other party who did not cancel it
            await createNotification(
                otherPartyId,
                'Transaction Cancelled',
                `The transaction has been cancelled.`,
                'Transaction',
                transaction.id
            );
        }

        if (status === 'Scheduled') {
            // Notify Buyer
            await createNotification(
                transaction.buyer_id,
                'Request Approved',
                `Seller has accepted your request. Please proceed to Meetup/Payment.`,
                'Transaction',
                transaction.id
            );
        }

        // UC19 Payment Proof
        if (status === 'To Confirm') {
            if (req.body.payment_proof_url) {
                transaction.payment_proof_url = req.body.payment_proof_url;
                await transaction.save();
            }
            await createNotification(
                transaction.seller_id,
                'Payment/Meetup Submitted',
                `Buyer has submitted action. Please verify and complete the order.`,
                'Transaction',
                transaction.id
            );
        }
        // If disputed, create a Dispute entry automatically
        if (status === 'Disputed') {
            // Save pre-dispute status
            transaction.pre_dispute_status = oldStatus;
            await transaction.save();

            // Check if a dispute already exists
            const existingDispute = await Dispute.findOne({ where: { transaction_id: transaction.id } });
            if (!existingDispute) {
                const dispute = await Dispute.create({
                    transaction_id: transaction.id,
                    complainant_id: requesterId || transaction.seller_id,
                    reason: 'Fraud',
                    description: `Seller reported an issue/declined payment proof during the confirmation stage.`,
                    evidence_urls: transaction.payment_proof_url ? [transaction.payment_proof_url] : [],
                    status: 'New'
                });

                // Notify Buyer
                await createNotification(
                    transaction.buyer_id,
                    'Transaction Disputed',
                    `Seller declined your payment proof. A dispute has been opened for moderation.`,
                    'Transaction',
                    dispute.id
                );

                // Notify Seller
                await createNotification(
                    transaction.seller_id,
                    'Dispute Opened',
                    `You have reported an issue with the payment proof. A dispute has been opened for moderation.`,
                    'Transaction',
                    dispute.id
                );

                // Emit new dispute event to admin room
                emitToAdmins('new_dispute_raised', dispute);
            }
        }

        // Emit status update to specific buyer and seller sockets
        emitToUser(transaction.buyer_id, 'transaction_status_updated', { transaction_id: transaction.id, status: transaction.status });
        emitToUser(transaction.seller_id, 'transaction_status_updated', { transaction_id: transaction.id, status: transaction.status });

        res.json(transaction);
    } catch (error) {
        console.error('Update Status Error:', error);
        res.status(500).json({ error: 'Failed to update transaction' });
    }
};

export const addRating = async (req, res) => {
    try {
        const { id } = req.params;
        const { rating, review, is_seller } = req.body; // is_seller = true if rating buyer

        const transaction = await Transaction.findByPk(id);
        if (!transaction) return res.status(404).json({ error: 'Transaction not found' });

        if (is_seller) {
            transaction.rating_from_seller = rating;
            transaction.seller_comment = review;
            
            if (transaction.review_status === 'PENDING_REVIEWS') {
                transaction.review_status = 'SELLER_REVIEWED';
            } else if (transaction.review_status === 'BUYER_REVIEWED') {
                transaction.review_status = 'PUBLISHED';
            }
        } else {
            transaction.rating_from_buyer = rating;
            transaction.buyer_comment = review;

            if (transaction.review_status === 'PENDING_REVIEWS') {
                transaction.review_status = 'BUYER_REVIEWED';
            } else if (transaction.review_status === 'SELLER_REVIEWED') {
                transaction.review_status = 'PUBLISHED';
            }
        }
        await transaction.save();

        if (transaction.review_status === 'PUBLISHED') {
            // Recalculate and update reputation for both parties
            const updateReputation = async (userId) => {
                const transactions = await Transaction.findAll({
                    where: {
                        review_status: 'PUBLISHED'
                    }
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
                    await User.update({ reputation_score: newScore, total_reviews: count }, { where: { id: userId } });
                }
            };

            await updateReputation(transaction.seller_id);
            await updateReputation(transaction.buyer_id);
        }

        res.json({ message: 'Rating submitted', review_status: transaction.review_status });
    } catch (e) {
        console.error('Rating Error', e);
        res.status(500).json({ error: 'Failed to rate' });
    }
};
