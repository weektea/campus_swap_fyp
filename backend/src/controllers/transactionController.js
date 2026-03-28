import { Transaction, Product, User, Review } from '../models/index.js';
import { createNotification } from './notificationController.js';

export const createTransaction = async (req, res) => {
    try {
        const { buyer_id, seller_id, product_id, amount, meetup_location, scheduled_at } = req.body;

        // Validate
        if (!buyer_id || !seller_id || !product_id || !amount) {
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

        // Mark product as Reserved
        await Product.update({ status: 'Reserved' }, { where: { id: product_id } });

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
                { model: User, as: 'buyer', attributes: ['id', 'full_name', 'email', 'profile_picture'] },
                { model: User, as: 'seller', attributes: ['id', 'full_name', 'email', 'profile_picture'] },
                { model: Review, as: 'reviews', required: false }
            ]
        });

        if (!transaction) return res.status(404).json({ error: 'Transaction not found' });

        // Security check
        if (req.user.id !== transaction.buyer_id && req.user.id !== transaction.seller_id) {
             return res.status(403).json({ error: 'Not authorized to view this transaction' });
        }

        res.json(transaction);
    } catch (error) {
        console.error('Get Transaction By ID Error:', error);
        res.status(500).json({ error: 'Failed to fetch transaction details' });
    }
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
            // Ideally update Buyer's reputation
        } else {
            transaction.rating_from_buyer = rating;
            // Ideally update Seller's reputation
        }
        await transaction.save();

        res.json({ message: 'Rating submitted' });
    } catch (e) {
        console.error('Rating Error', e);
        res.status(500).json({ error: 'Failed to rate' });
    }
};
