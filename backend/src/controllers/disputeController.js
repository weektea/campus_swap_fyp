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

export const triageDispute = async (req, res) => {
    try {
        const { id } = req.params;
        const { action, mod_notes } = req.body; // 'Dismiss', 'Investigate', 'Escalate'

        const dispute = await Dispute.findByPk(id);
        if (!dispute) return res.status(404).json({ error: 'Dispute not found' });
        if (dispute.status === 'Resolved') {
            return res.status(400).json({ error: 'This dispute has already been resolved by an Admin and cannot be modified.' });
        }

        if (action === 'Dismiss') {
            dispute.status = 'Dismissed';
        } else if (action === 'Investigate') {
            dispute.status = 'Investigating';
        } else if (action === 'Escalate') {
            dispute.status = 'Escalated';
        } else {
            return res.status(400).json({ error: 'Invalid triage action' });
        }

        if (mod_notes) dispute.admin_notes = mod_notes; // Storing mod notes in admin_notes field
        await dispute.save();

        res.json({ message: `Dispute triaged as ${action}`, dispute });
    } catch (error) {
        console.error('Triage Dispute Error:', error);
        res.status(500).json({ error: 'Failed to triage dispute' });
    }
};

export const arbitrateDispute = async (req, res) => {
    try {
        const { id } = req.params;
        const { winning_party, admin_notes } = req.body; // 'Buyer' or 'Seller'

        const dispute = await Dispute.findByPk(id);
        if (!dispute) return res.status(404).json({ error: 'Dispute not found' });
        if (dispute.status !== 'Escalated') {
            return res.status(400).json({ error: 'Only escalated disputes can be arbitrated' });
        }

        const transaction = await Transaction.findByPk(dispute.transaction_id);
        if (!transaction) return res.status(404).json({ error: 'Transaction not found' });

        if (winning_party === 'Buyer') {
            // Buyer wins: Cancel order, refund
            transaction.status = 'Cancelled';
            dispute.status = 'Resolved';
            await transaction.save();
        } else if (winning_party === 'Seller') {
            // Seller wins: Complete order, deposit to seller
            transaction.status = 'Completed';
            dispute.status = 'Resolved';
            await transaction.save();
        } else {
            return res.status(400).json({ error: 'winning_party must be Buyer or Seller' });
        }

        dispute.admin_notes = admin_notes || 'Arbitrated by admin.';
        await dispute.save();

        res.json({ message: `Dispute resolved in favor of ${winning_party}`, dispute, transaction });
    } catch (error) {
        console.error('Arbitrate Dispute Error:', error);
        res.status(500).json({ error: 'Failed to arbitrate dispute' });
    }
};
