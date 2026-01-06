import { Transaction, Product, User } from '../models/index.js';
import { createNotification } from './notificationController.js';

export const createTransaction = async (req, res) => {
    try {
        const { buyer_id, seller_id, product_id, amount, meetup_location, scheduled_at } = req.body;

        // Validate
        if (!buyer_id || !seller_id || !product_id || !amount) {
            return res.status(400).json({ error: 'Missing required transaction details' });
        }

        // Create Transaction
        const transaction = await Transaction.create({
            buyer_id,
            seller_id,
            product_id,
            amount,
            meetup_location,
            scheduled_at,
            status: 'Pending'
        });

        // Mark product as Reserved
        await Product.update({ status: 'Reserved' }, { where: { id: product_id } });

        // Notify Seller
        await createNotification(
            seller_id,
            'New Purchase Request',
            `A buyer wants to buy your item for RM ${amount}.`,
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

        // If completed, mark product as Sold
        if (status === 'Completed') {
            await Product.update(
                { status: 'Sold' },
                { where: { id: transaction.product_id } }
            );
            // Notify Seller (Buyer completes)
            await createNotification(
                transaction.seller_id,
                'Transaction Completed',
                `Buyer has received the item. Money will be released.`,
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
            // Notify other party
            // Simplification: if cancelled by buyer, notify seller and vice versa.
            // For MVP, just notify both to be safe or just the one who didn't cancel (needs user context which we lack here slightly, so notify seller mainly)
            await createNotification(
                transaction.seller_id,
                'Transaction Cancelled',
                `The transaction for your item has been cancelled.`,
                'Transaction',
                transaction.id
            );
        }

        if (status === 'Scheduled') {
            // Notify Buyer
            await createNotification(
                transaction.buyer_id,
                'Meetup Confirmed',
                `Seller has confirmed the meetup. Check details.`,
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
