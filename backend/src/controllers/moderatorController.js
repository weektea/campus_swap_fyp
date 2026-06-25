import { User, Product, Transaction, Report, SupportTicket, Dispute, Notification } from '../models/index.js';
import { Op } from 'sequelize';

// ======================= MODERATOR EXCLUSIVE =======================

// UC10 / UC12: Report Processing
export const updateReportStatus = async (req, res) => {
    try {
        const { status, admin_notes } = req.body;
        const report = await Report.findByPk(req.params.id);
        if (!report) return res.status(404).json({ error: 'Report not found' });

        report.status = status; // 'Uphold', 'Dismissed'
        if (admin_notes) report.admin_notes = admin_notes;
        report.handled_by = req.user.id;
        await report.save();

        // Cascade Action if Uphold
        if (status === 'Uphold' && report.product_id) {
            const product = await Product.findByPk(report.product_id);
            if (product) {
                product.status = 'Suspended';
                await product.save();

                // Auto-cancel active pending/scheduled transactions
                const activeTransactions = await Transaction.findAll({
                    where: { product_id: product.id, status: ['Pending', 'Scheduled', 'To Confirm'] }
                });

                for (const tx of activeTransactions) {
                    tx.status = 'Cancelled';
                    await tx.save();
                    
                    // Create Notification for the buyer
                    await Notification.create({
                        user_id: tx.buyer_id,
                        type: 'Order_Cancelled',
                        message: `您的预订商品因违规已被下架，订单(ID: ${tx.id})已自动取消，请勿进行线下付款。`,
                        is_read: false
                    });
                }
            }
        }

        // If Upheld and it is a User report -> Warn the user (reduce reputation by 1.0)
        if (status === 'Uphold' && report.reported_user_id) {
            const user = await User.findByPk(report.reported_user_id);
            if (user) {
                user.reputation_score = Math.max(1.0, user.reputation_score - 1.0);
                await user.save();

                // Notify the reported user
                await Notification.create({
                    user_id: user.id,
                    title: 'Account Warning Issued',
                    message: `A formal warning has been issued to your account following report #${report.id.toString().substring(0, 8).toUpperCase()}. Your reputation score was decreased.`,
                    type: 'System',
                    related_id: report.id
                });
            }
        }

        // Notify the reporter
        let msg = status === 'Uphold' 
            ? 'Thank you for your contribution to a safer campus.' 
            : 'Your report was reviewed and dismissed.';
        await Notification.create({
            user_id: report.reporter_id,
            title: `Report ${status}`,
            message: msg,
            type: 'System',
            related_id: report.id
        });

        res.json({ message: `Report updated to ${status}`, report });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

// UC23: Dispute Triage
export const triageDispute = async (req, res) => {
    try {
        const { action, reply } = req.body; // action: 'Investigating', 'Dismiss', 'Mediation', 'Escalate'
        const dispute = await Dispute.findByPk(req.params.id);
        if (!dispute) return res.status(404).json({ error: 'Dispute not found' });

        if (reply) {
            dispute.admin_notes = dispute.admin_notes ? `${dispute.admin_notes}\n[Mod]: ${reply}` : `[Mod]: ${reply}`;
        }

        if (action === 'Escalate') {
            dispute.status = 'Escalated'; // Handed over to Admin
        } else if (action === 'Dismiss' || action === 'Mediation') {
            dispute.status = 'Resolved';
            
            // If dismissed, unfreeze the order to its pre-dispute status
            if (action === 'Dismiss') {
                const tx = await Transaction.findByPk(dispute.transaction_id);
                if (tx && tx.status === 'Disputed') {
                    const restoredStatus = tx.pre_dispute_status || 'Completed';
                    tx.status = restoredStatus;
                    tx.pre_dispute_status = null;
                    await tx.save();

                    // Align Product status
                    if (restoredStatus === 'Completed') {
                        await Product.update(
                            { status: 'Sold' },
                            { where: { id: tx.product_id } }
                        );
                    } else {
                        await Product.update(
                            { status: 'Reserved' },
                            { where: { id: tx.product_id } }
                        );
                    }
                }
            }
        } else {
            dispute.status = 'Investigating';
        }

        dispute.handled_by = req.user.id;
        await dispute.save();

        // Notify complainant
        await Notification.create({
            user_id: dispute.complainant_id,
            title: 'Dispute Updated',
            message: `Your dispute status was updated to ${dispute.status}.`,
            type: 'System',
            related_id: dispute.id
        });

        res.json({ message: 'Dispute triaged successfully', dispute });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

// UC28: Support Tickets
export const claimTicket = async (req, res) => {
    try {
        const ticketId = req.params.id;
        const moderatorId = req.user.id;

        const ticket = await SupportTicket.findByPk(ticketId);
        if (!ticket) return res.status(404).json({ error: 'Ticket not found' });

        // Pessimistic Locking
        if (ticket.lockedByModeratorId && ticket.lockedByModeratorId !== moderatorId) {
            return res.status(409).json({ error: 'Ticket is currently being handled by another moderator.' });
        }

        ticket.lockedByModeratorId = moderatorId;
        ticket.lockedAt = new Date();
        ticket.status = 'In-Progress';
        await ticket.save();

        // Notify user of claim
        await Notification.create({
            user_id: ticket.user_id,
            title: 'Support Ticket In-Progress',
            message: 'A moderator has claimed and is reviewing your support ticket.',
            type: 'System',
            related_id: ticket.id
        });

        res.json({ message: 'Ticket locked successfully', ticket });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

export const resolveTicket = async (req, res) => {
    try {
        const { reply_content } = req.body;
        const ticketId = req.params.id;
        
        const ticket = await SupportTicket.findByPk(ticketId);
        if (!ticket) return res.status(404).json({ error: 'Ticket not found' });

        // Check lock ownership
        if (ticket.lockedByModeratorId && ticket.lockedByModeratorId !== req.user.id) {
            return res.status(403).json({ error: 'You do not hold the lock for this ticket.' });
        }

        ticket.reply_content = reply_content;
        ticket.status = 'Resolved';
        ticket.lockedByModeratorId = null;
        ticket.lockedAt = null;
        ticket.handled_by = req.user.id;
        await ticket.save();

        // Notify user
        await Notification.create({
            user_id: ticket.user_id,
            title: 'Support Ticket Resolved',
            message: 'A moderator has replied and resolved your ticket.',
            type: 'System',
            related_id: ticket.id
        });

        res.json({ message: 'Ticket resolved successfully', ticket });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

// Helper: Get data for dashboard
export const getDashboardData = async (req, res) => {
    try {
        const reports = await Report.findAll({ 
            where: { status: 'Pending' },
            include: ['reporter', 'product', 'reported_user'] 
        });
        const disputes = await Dispute.findAll({ 
            where: { status: ['New', 'Investigating'] },
            include: ['transaction', 'complainant'] 
        });
        const tickets = await SupportTicket.findAll({ 
            where: { status: ['Open', 'In-Progress'] },
            include: ['student', 'handler'] 
        });

        res.json({ reports, disputes, tickets });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

// System Metrics
export const getSystemMetrics = async (req, res) => {
    try {
        const totalUsers = await User.count();
        const activeDisputes = await Dispute.count({ where: { status: ['New', 'Investigating'] } });
        const totalProducts = await Product.count();
        const totalTransactions = await Transaction.count({ where: { status: 'Completed' } });
        
        // MVP: roughly 5.2 kg CO2 saved per item reused
        const co2Saved = totalTransactions * 5.2;

        res.json({
            total_users: totalUsers,
            active_disputes: activeDisputes,
            total_products: totalProducts,
            total_transactions: totalTransactions,
            co2_saved_kg: parseFloat(co2Saved.toFixed(1))
        });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};
