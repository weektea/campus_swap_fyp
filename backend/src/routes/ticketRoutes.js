import express from 'express';
import { verifyToken } from '../middleware/authMiddleware.js';
import { Report, Dispute, SupportTicket, TicketMessage, Product, User, Transaction } from '../models/index.js';
import Notification from '../models/Notification.js';

const router = express.Router();

// Get My Reports
router.get('/my-reports', verifyToken, async (req, res) => {
    try {
        const reports = await Report.findAll({
            where: { reporter_id: req.user.userId },
            include: [{ model: Product, as: 'product', attributes: ['id', 'title', 'price', 'imageUrl'] }],
            order: [['createdAt', 'DESC']]
        });
        res.json(reports);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get My Disputes
router.get('/my-disputes', verifyToken, async (req, res) => {
    try {
        const disputes = await Dispute.findAll({
            where: { complainant_id: req.user.userId },
            include: [
                { 
                    model: Transaction, as: 'transaction', 
                    include: [{ model: Product, as: 'product', attributes: ['id', 'title'] }]
                }
            ],
            order: [['createdAt', 'DESC']]
        });
        res.json(disputes);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get My Support Tickets
router.get('/my-tickets', verifyToken, async (req, res) => {
    try {
        const tickets = await SupportTicket.findAll({
            where: { user_id: req.user.userId },
            order: [['createdAt', 'DESC']]
        });
        res.json(tickets);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get Thread Messages
router.get('/thread/:reference_id', verifyToken, async (req, res) => {
    try {
        const messages = await TicketMessage.findAll({
            where: { reference_id: req.params.reference_id },
            include: [{ model: User, as: 'sender', attributes: ['id', 'username', 'role'] }],
            order: [['createdAt', 'ASC']]
        });
        res.json(messages);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Post Thread Message
router.post('/thread/:reference_id', verifyToken, async (req, res) => {
    try {
        const { reference_type, content, attachment_url } = req.body;
        
        const message = await TicketMessage.create({
            reference_id: req.params.reference_id,
            reference_type,
            sender_id: req.user.userId,
            content,
            attachment_url
        });

        // Notify the other party
        // If sender is user -> notify handler/admin (maybe skip for now, admins poll dashboard)
        // If sender is moderator -> notify user
        if (req.user.role === 'admin' || req.user.role === 'moderator') {
            let targetUserId;
            if (reference_type === 'Dispute') {
                const dispute = await Dispute.findByPk(req.params.reference_id);
                targetUserId = dispute?.complainant_id;
            } else if (reference_type === 'SupportTicket') {
                const ticket = await SupportTicket.findByPk(req.params.reference_id);
                targetUserId = ticket?.user_id;
            }

            if (targetUserId) {
                await Notification.create({
                    user_id: targetUserId,
                    title: 'New Message from Support',
                    message: `A moderator has replied to your ${reference_type.toLowerCase()}.`,
                    type: 'System',
                    related_id: req.params.reference_id
                });
            }
        }

        res.status(201).json(message);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

export default router;
