import express from 'express';
import { Op } from 'sequelize';
import { authenticateToken as verifyToken } from '../middleware/authMiddleware.js';
import { Report, Dispute, SupportTicket, TicketMessage, Product, User, Transaction } from '../models/index.js';
import Notification from '../models/Notification.js';
import { emitToUser, emitToAdmins } from '../config/socket.js';

const router = express.Router();

// Create Support Ticket
router.post('/', verifyToken, async (req, res) => {
    try {
        const { category, subject, description } = req.body;
        if (!category || !subject || !description) {
            return res.status(400).json({ error: 'Missing support ticket details' });
        }

        // Anti-Spam: Check if user has 3 or more open tickets
        const openTicketsCount = await SupportTicket.count({
            where: {
                user_id: req.user.id,
                status: 'Open'
            }
        });
        if (openTicketsCount >= 3) {
            return res.status(429).json({ error: 'You have reached the maximum number of open tickets' });
        }

        // Map Flutter category to DB ENUM ('Account', 'Bug', 'Harassment', 'General')
        let dbCategory = 'General';
        if (['Account', 'Bug', 'Harassment', 'General'].includes(category)) {
            dbCategory = category;
        }

        const ticket = await SupportTicket.create({
            user_id: req.user.id,
            category: dbCategory,
            subject,
            description,
            status: 'Open'
        });

        // Emit new ticket event to admin room
        emitToAdmins('new_ticket_submitted', ticket);

        res.status(201).json(ticket);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get My Reports
router.get('/my-reports', verifyToken, async (req, res) => {
    try {
        const reports = await Report.findAll({
            where: { reporter_id: req.user.id },
            include: [{ model: Product, as: 'product', attributes: ['id', 'title', 'price', 'image_urls'] }],
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
            include: [
                { 
                    model: Transaction, as: 'transaction', 
                    include: [{ model: Product, as: 'product', attributes: ['id', 'title'] }]
                }
            ],
            where: {
                [Op.or]: [
                    { complainant_id: req.user.id },
                    { '$transaction.buyer_id$': req.user.id },
                    { '$transaction.seller_id$': req.user.id }
                ]
            },
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
            where: { user_id: req.user.id },
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
            include: [{ model: User, as: 'sender', attributes: ['id', 'email', 'role', 'username', 'full_name'] }],
            order: [['createdAt', 'ASC']]
        });
        res.json(messages);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get Thread Status
router.get('/thread/:reference_id/status', verifyToken, async (req, res) => {
    try {
        let status = 'Open';
        let type = 'SupportTicket';
        
        const dispute = await Dispute.findByPk(req.params.reference_id);
        if (dispute) {
            status = dispute.status;
            type = 'Dispute';
        } else {
            const ticket = await SupportTicket.findByPk(req.params.reference_id);
            if (ticket) {
                status = ticket.status;
                type = 'SupportTicket';
            }
        }
        res.json({ status, type });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Post Thread Message
router.post('/thread/:reference_id', verifyToken, async (req, res) => {
    try {
        const { reference_type, content, attachment_url } = req.body;

        // Check if ticket or dispute is resolved/closed
        if (reference_type === 'Dispute') {
            const dispute = await Dispute.findByPk(req.params.reference_id);
            if (dispute && dispute.status === 'Resolved') {
                return res.status(400).json({ error: 'This dispute is resolved and closed.' });
            }
        } else if (reference_type === 'SupportTicket') {
            const ticket = await SupportTicket.findByPk(req.params.reference_id);
            if (ticket && ticket.status === 'Resolved') {
                return res.status(400).json({ error: 'This support ticket is resolved and closed.' });
            }
        }
        
        const message = await TicketMessage.create({
            reference_id: req.params.reference_id,
            reference_type,
            sender_id: req.user.id,
            content,
            attachment_url
        });

        // Conversational State Machine Status Transitions
        if (req.user.role === 'admin' || req.user.role === 'moderator') {
            // Message from staff -> set status to 'Awaiting Reply'
            if (reference_type === 'Dispute') {
                const dispute = await Dispute.findByPk(req.params.reference_id);
                if (dispute && dispute.status !== 'Resolved') {
                    dispute.status = 'Awaiting Reply';
                    await dispute.save();
                }
            } else if (reference_type === 'SupportTicket') {
                const ticket = await SupportTicket.findByPk(req.params.reference_id);
                if (ticket && ticket.status !== 'Resolved') {
                    ticket.status = 'Awaiting Reply';
                    await ticket.save();
                }
            }
        } else {
            // Message from student -> reset status from 'Awaiting Reply'
            if (reference_type === 'Dispute') {
                const dispute = await Dispute.findByPk(req.params.reference_id);
                if (dispute && dispute.status === 'Awaiting Reply') {
                    dispute.status = 'Investigating';
                    await dispute.save();
                }
            } else if (reference_type === 'SupportTicket') {
                const ticket = await SupportTicket.findByPk(req.params.reference_id);
                if (ticket && ticket.status === 'Awaiting Reply') {
                    ticket.status = 'In-Progress';
                    await ticket.save();
                }
            }
        }

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
                const title = reference_type === 'Dispute' ? 'Dispute Message' : 'Support Ticket Message';
                const messageText = `A moderator has replied to your ${reference_type.toLowerCase()}.`;

                // Deduplicate unread notifications for this thread
                const existingNotification = await Notification.findOne({
                    where: {
                        user_id: targetUserId,
                        related_id: req.params.reference_id,
                        title,
                        is_read: false
                    }
                });

                if (existingNotification) {
                    existingNotification.message = messageText;
                    existingNotification.createdAt = new Date(); // Bubble to top
                    await existingNotification.save();
                } else {
                    await Notification.create({
                        user_id: targetUserId,
                        title,
                        message: messageText,
                        type: 'System',
                        related_id: req.params.reference_id
                    });
                }
            }
        }

        const msgWithSender = await TicketMessage.findByPk(message.id, {
            include: [{ model: User, as: 'sender', attributes: ['id', 'email', 'role', 'username', 'full_name'] }]
        });

        if (req.user.role === 'admin' || req.user.role === 'moderator') {
            if (reference_type === 'Dispute') {
                const dispute = await Dispute.findByPk(req.params.reference_id, {
                    include: [{ model: Transaction, as: 'transaction' }]
                });
                if (dispute) {
                    if (dispute.complainant_id) emitToUser(dispute.complainant_id, 'receive_new_message', msgWithSender || message);
                    if (dispute.transaction) {
                        if (dispute.transaction.buyer_id) emitToUser(dispute.transaction.buyer_id, 'receive_new_message', msgWithSender || message);
                        if (dispute.transaction.seller_id) emitToUser(dispute.transaction.seller_id, 'receive_new_message', msgWithSender || message);
                    }
                }
            } else if (reference_type === 'SupportTicket') {
                const ticket = await SupportTicket.findByPk(req.params.reference_id);
                if (ticket?.user_id) {
                    emitToUser(ticket.user_id, 'receive_new_message', msgWithSender || message);
                }
            }
        } else {
            emitToAdmins('receive_new_message', msgWithSender || message);
            if (reference_type === 'Dispute') {
                const dispute = await Dispute.findByPk(req.params.reference_id, {
                    include: [{ model: Transaction, as: 'transaction' }]
                });
                if (dispute && dispute.transaction) {
                    const counterpartId = req.user.id === dispute.transaction.buyer_id 
                        ? dispute.transaction.seller_id 
                        : dispute.transaction.buyer_id;
                    emitToUser(counterpartId, 'receive_new_message', msgWithSender || message);
                }
            }
        }

        res.status(201).json(message);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

export default router;
