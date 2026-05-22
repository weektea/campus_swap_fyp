import { Transaction, Product, User, Review } from '../models/index.js';
import { createNotification } from './notificationController.js';

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
                    attributes: ['full_name', 'email']
                },
                {
                    model: Review,
                    as: 'reviews', // Need to check association alias
                    required: false,
                    where: { reviewer_id: user_id } // Only get reviews by THIS user for this transaction
                }
            ],
            order: [['createdAt', 'DESC']]
        });
        res.json(transactions);
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
                { model: User, as: 'buyer', attributes: ['id', 'full_name', 'email', 'profile_image_url'] },
                { model: User, as: 'seller', attributes: ['id', 'full_name', 'email', 'profile_image_url'] },
                { model: Review, as: 'reviews', required: false }
            ]
        });

        if (!transaction) return res.status(404).json({ error: 'Transaction not found' });

        // Security check (use string comparison for UUID/int compatibility)
        const reqUserId = String(req.user.id);
        if (reqUserId !== String(transaction.buyer_id) && reqUserId !== String(transaction.seller_id)) {
             return res.status(403).json({ error: 'Not authorized to view this transaction' });
        }

        res.json(transaction);
    } catch (error) {
        console.error('Get Transaction By ID Error:', error);
        res.status(500).json({ error: 'Failed to fetch transaction details' });
    }
};

const CARBON_SAVINGS = {
    'Textbooks': 5.0,
    'Novels': 2.7,
    'Comics': 3.0,
    'Reference': 4.5,
    'Books_Others': 3.0,
    
    'Laptops': 250.0,
    'Smartphones': 75.0,
    'Accessories': 8.0,
    'Audio': 15.0,
    'Electronics_Others': 50.0,
    
    'Clothing': 8.0,
    'Shoes': 14.0,
    'Bags': 10.0,
    'Fashion_Accessories': 2.5,
    
    'Chairs': 35.0,
    'Tables': 80.0,
    'Storage': 60.0,
    'Furniture_Others': 15.0,
    
    'Writing': 0.5,
    'Paper': 1.5,
    'Art Supplies': 3.0,
    'Stationery_Others': 2.0,
    
    'Equipment': 15.0,
    'Apparel': 6.0,
    'Bicycles': 150.0,
    'Sports_Others': 10.0,
    
    'Miscellaneous': 10.0
};

export const getCarbonValue = (category, subCategory) => {
    if (CARBON_SAVINGS[subCategory]) return CARBON_SAVINGS[subCategory];
    
    // Fallback based on category
    if (category === 'Books') return CARBON_SAVINGS['Books_Others'];
    if (category === 'Electronics') return CARBON_SAVINGS['Electronics_Others'];
    if (category === 'Fashion') return CARBON_SAVINGS['Fashion_Accessories'];
    if (category === 'Furniture') return CARBON_SAVINGS['Furniture_Others'];
    if (category === 'Stationery') return CARBON_SAVINGS['Stationery_Others'];
    if (category === 'Sports') return CARBON_SAVINGS['Sports_Others'];
    
    // Absolute Fallback (Code default to prevent crashes)
    return 2.5;
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

        transaction.status = status;
        await transaction.save();

        const requesterId = req.user?.id;
        const otherPartyId = requesterId === transaction.buyer_id ? transaction.seller_id : transaction.buyer_id;

        // If completed, mark product as Sold or Reserved for rent
        if (status === 'Completed') {
            await Product.update(
                { status: 'Sold' },
                { where: { id: transaction.product_id } }
            );
            
            transaction.completed_at = new Date();
            transaction.review_status = 'PENDING_REVIEWS';
            await transaction.save();
            
            // Calculate Carbon Savings
            const product = await Product.findByPk(transaction.product_id);
            if (product) {
                 const co2Saved = getCarbonValue(product.category, product.sub_category_id);
                 
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
