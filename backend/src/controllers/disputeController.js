import { Dispute, Transaction } from '../models/index.js';
import { createNotification } from './notificationController.js';

export const createDispute = async (req, res) => {
    try {
        const complainant_id = req.user.id;
        const { transaction_id, category, description } = req.body;

        if (!transaction_id || !description) {
            return res.status(400).json({ error: 'Missing dispute details' });
        }

        const transaction = await Transaction.findByPk(transaction_id);
        if (!transaction) return res.status(404).json({ error: 'Transaction not found' });

        // Map Flutter category to DB Enum
        let dbReason = 'Other';
        if (category === 'Item not received') dbReason = 'Not Received';
        else if (category.includes('Item damaged')) dbReason = 'Damaged';
        else if (category.includes('Fake payment proof')) dbReason = 'Fraud';

        const dispute = await Dispute.create({
            transaction_id,
            complainant_id,
            reason: dbReason,
            description,
            status: 'New'
        });

        // Identify other party to notify
        const otherPartyId = complainant_id === transaction.buyer_id ? transaction.seller_id : transaction.buyer_id;

        // Notify other party
        await createNotification(
            otherPartyId,
            'Transaction Disputed',
            `A dispute was filed against this transaction. A moderator will review it soon.`,
            'Transaction',
            transaction.id
        );

        // Also notify the complainant that it was received
        await createNotification(
            complainant_id,
            'Dispute Submitted',
            `Your dispute has been logged. Our moderation team will investigate.`,
            'System',
            transaction.id
        );

        res.status(201).json(dispute);
    } catch (error) {
        console.error('Create Dispute Error:', error);
        res.status(500).json({ error: 'Failed to create dispute' });
    }
};
