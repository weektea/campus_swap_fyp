import { User, Product, Transaction, Report, SupportTicket, Dispute, Notification } from '../models/index.js';
import { createNotification } from './notificationController.js';
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

                // Create Notification for the buyer
                for (const tx of activeTransactions) {
                    tx.status = 'Cancelled';
                    await tx.save();
                    
                    await createNotification(
                        tx.buyer_id,
                        'Order Cancelled - Item Suspended',
                        `Your reserved item "${product.title}" has been suspended due to policy violations. Order (ID: ${tx.id}) has been automatically cancelled.`,
                        'System',
                        tx.id
                    );
                }

                // Deduct Seller Reputation Score for suspended listing (-0.5 penalty)
                const seller = await User.findByPk(product.seller_id);
                if (seller) {
                    const currentScore = parseFloat(seller.reputation_score !== undefined && seller.reputation_score !== null ? seller.reputation_score : 5.0);
                    seller.reputation_score = Math.max(1.0, parseFloat((currentScore - 0.5).toFixed(1)));
                    await seller.save();
                }

                // Create Notification for the Seller
                const reasonText = admin_notes ? `Reason: "${admin_notes}"` : `Violation: ${report.violation_type || 'Policy Violation'}`;
                await createNotification(
                    product.seller_id,
                    'Listing Suspended - Action Required',
                    `Your listing "${product.title}" was suspended following report review. ${reasonText}.\n\nIf you believe this is an error, please visit Help Center to submit a Support Ticket to appeal to moderators, or review our Community Guidelines before re-posting.`,
                    'System',
                    product.id
                );
            }
        }

        // If Upheld and it is a User report -> Warn the user (reduce reputation by 1.0)
        if (status === 'Uphold' && report.reported_user_id) {
            const user = await User.findByPk(report.reported_user_id);
            if (user) {
                user.reputation_score = Math.max(1.0, user.reputation_score - 1.0);
                user.warning_count = (user.warning_count || 0) + 1;
                
                let isSuspended = false;
                if (user.warning_count >= 3) {
                    user.status = 'suspended';
                    user.is_active = false;
                    isSuspended = true;
                }
                await user.save();

                // Notify the reported user with Community Guidelines citation
                const messageText = isSuspended
                    ? `Your account has been suspended following report #${report.id.toString().substring(0, 8).toUpperCase()} due to accumulating ${user.warning_count} warnings for violating Campus Swap Community Guidelines.`
                    : `A formal warning has been issued to your account following report #${report.id.toString().substring(0, 8).toUpperCase()} for violating Campus Swap Community Guidelines. You have received ${user.warning_count}/3 warnings. Receiving 3 warnings will result in automatic account suspension.`;

                await createNotification(
                    user.id,
                    isSuspended ? 'Account Suspended' : 'Account Warning Issued',
                    messageText,
                    'System',
                    report.id
                );
            }
        }

        // Notify the reporter
        let msg = status === 'Uphold' 
            ? 'Thank you for your contribution to a safer campus.' 
            : 'Your report was reviewed and dismissed.';
        await createNotification(
            report.reporter_id,
            `Report ${status}`,
            msg,
            'System',
            report.id
        );

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
        await createNotification(
            dispute.complainant_id,
            'Dispute Updated',
            `Your dispute status was updated to ${dispute.status}.`,
            'Dispute',
            dispute.id
        );

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

        if (ticket.type === 'SUSPENSION_APPEAL' && req.user.role === 'moderator') {
            return res.status(403).json({ error: 'Only Administrators can claim/handle suspension appeals.' });
        }

        // Pessimistic Locking
        if (ticket.lockedByModeratorId && ticket.lockedByModeratorId !== moderatorId) {
            return res.status(409).json({ error: 'Ticket is currently being handled by another moderator.' });
        }

        ticket.lockedByModeratorId = moderatorId;
        ticket.lockedAt = new Date();
        ticket.status = 'In-Progress';
        await ticket.save();

        // Notify user of claim
        await createNotification(
            ticket.user_id,
            'Support Ticket In-Progress',
            'A moderator has claimed and is reviewing your support ticket.',
            'System',
            ticket.id
        );

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

        if (ticket.type === 'SUSPENSION_APPEAL' && req.user.role === 'moderator') {
            return res.status(403).json({ error: 'Only Administrators can claim/handle suspension appeals.' });
        }

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
        await createNotification(
            ticket.user_id,
            'Support Ticket Resolved',
            'A moderator has replied and resolved your ticket.',
            'System',
            ticket.id
        );

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
            where: { 
                status: ['Open', 'In-Progress', 'Pending'],
                type: { [Op.ne]: 'SUSPENSION_APPEAL' }
            },
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
        
        // Sum carbon offset based on transaction snapshots (fallback to dynamic database factor or 2.5 if null)
        const completedTransactions = await Transaction.findAll({
            where: { status: 'Completed' },
            include: [{
                model: Product,
                as: 'product',
                include: [
                    { model: Category, as: 'categoryModel' },
                    { model: SubCategory, as: 'subcategoryModel' }
                ]
            }]
        });

        let co2Saved = 0.0;
        completedTransactions.forEach(t => {
            if (t.awarded_carbon_points !== null && t.awarded_carbon_points !== undefined) {
                co2Saved += parseFloat(t.awarded_carbon_points);
            } else if (t.product) {
                const catName = t.product.categoryModel ? t.product.categoryModel.name : (t.product.category || 'Others');
                const subCatName = t.product.subcategoryModel ? t.product.subcategoryModel.name : null;
                co2Saved += getCarbonValue(catName, subCatName, t.product);
            } else {
                co2Saved += 2.5; // fallback
            }
        });

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
