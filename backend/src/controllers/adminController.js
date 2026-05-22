import { User, Product, Transaction, Report, SupportTicket, Category, Dispute } from '../models/index.js';
import { Op } from 'sequelize';
import { exec } from 'child_process';
import path from 'path';

// ======================= MODERATOR & ADMIN SHARED =======================

export const getListings = async (req, res) => {
    try {
        const products = await Product.findAll({ include: [{ model: User, as: 'seller', attributes: ['full_name', 'email'] }] });
        res.json(products);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

export const suspendListing = async (req, res) => {
    try {
        const product = await Product.findByPk(req.params.id);
        if (!product) return res.status(404).json({ error: 'Product not found' });
        
        product.status = 'Suspended';
        await product.save();

        // UC10 / UC12 Cascade: Cancel any active order holding this product
        await Transaction.update(
            { status: 'Cancelled' },
            { where: { product_id: product.id, status: ['Pending', 'Scheduled', 'To Confirm'] } }
        );

        res.json({ message: 'Listing suspended successfully and active transactions cancelled.', product });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

export const getReports = async (req, res) => {
    try {
        const reports = await Report.findAll({ include: ['reporter', 'product'] });
        res.json(reports);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

export const resolveReport = async (req, res) => {
    try {
        const { status, admin_notes } = req.body;
        const report = await Report.findByPk(req.params.id);
        if (!report) return res.status(404).json({ error: 'Report not found' });
        
        report.status = status; // e.g. Uphold, Dismissed, Escalated
        if (admin_notes) report.admin_notes = admin_notes;
        await report.save();

        // If Upheld, Suspend the product and Cascade Cancel orders
        if (status === 'Uphold' && report.product_id) {
            const product = await Product.findByPk(report.product_id);
            if (product) {
                product.status = 'Suspended';
                await product.save();

                // Cascade: Cancel any active order holding this product
                await Transaction.update(
                    { status: 'Cancelled' },
                    { where: { product_id: product.id, status: ['Pending', 'Scheduled', 'To Confirm'] } }
                );
            }
        }

        res.json({ message: 'Report updated', report });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

export const getTickets = async (req, res) => {
    try {
        const tickets = await SupportTicket.findAll({ include: ['student'] });
        res.json(tickets);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

export const lockTicket = async (req, res) => {
    try {
        const ticketId = req.params.id;
        const moderatorId = req.user.id;

        const ticket = await SupportTicket.findByPk(ticketId);
        if (!ticket) return res.status(404).json({ error: 'Ticket not found' });

        // Pessimistic Locking with 30 minute timeout
        if (ticket.lockedByModeratorId && ticket.lockedByModeratorId !== moderatorId) {
            const lockTime = new Date(ticket.lockedAt);
            const now = new Date();
            const diffMinutes = (now - lockTime) / (1000 * 60);

            if (diffMinutes < 30) {
                return res.status(409).json({ error: 'Ticket is currently locked by another moderator.' });
            }
        }

        ticket.lockedByModeratorId = moderatorId;
        ticket.lockedAt = new Date();
        ticket.status = 'In-Progress';
        await ticket.save();

        res.json({ message: 'Ticket locked successfully', ticket });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

export const replyTicket = async (req, res) => {
    try {
        const { reply_content, status } = req.body;
        const ticket = await SupportTicket.findByPk(req.params.id);
        if (!ticket) return res.status(404).json({ error: 'Ticket not found' });
        
        // Ensure the person replying is the one who locked it (or if they are admin)
        if (ticket.lockedByModeratorId && ticket.lockedByModeratorId !== req.user.id && req.user.role !== 'admin') {
            return res.status(403).json({ error: 'You do not hold the lock for this ticket.' });
        }

        ticket.reply_content = reply_content;
        ticket.status = status; // Resolved, Escalated, etc.
        
        // Release the lock
        ticket.lockedByModeratorId = null;
        ticket.lockedAt = null;

        await ticket.save();
        res.json({ message: 'Ticket replied and lock released', ticket });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};


// ======================= ADMINISTRATOR ONLY =======================

export const getSystemMetrics = async (req, res) => {
    try {
        const usersCount = await User.count();
        const activeUsers = await User.count({ where: { is_active: true } });
        const suspendedUsers = await User.count({ where: { is_active: false } });
        const productsCount = await Product.count();
        
        const activeDisputes = await Dispute.count({
            where: { status: ['New', 'Investigating'] }
        });

        const transactions = await Transaction.findAll({ 
            where: { status: 'Completed' },
            include: [{
                model: Product,
                as: 'product',
                include: [{
                    model: Category,
                    as: 'categoryModel' // Joined safely to get real conversion factor!
                }]
            }]
        });
        
        // Calculate metrics
        let estimatedCarbonSaved = 0.0;
        let gmv = 0.0;
        let categoryCarbonMap = {};

        transactions.forEach(t => {
            // GMV
            gmv += parseFloat(t.amount || 0);

            // Carbon
            let itemCarbon = 5.0; // Fallback
            let catName = 'Other';

            if (t.product && t.product.categoryModel) {
                itemCarbon = t.product.categoryModel.carbon_conversion_factor;
                catName = t.product.categoryModel.name;
            } else if (t.product && t.product.category) {
                catName = t.product.category;
            }

            estimatedCarbonSaved += itemCarbon;
            
            if (!categoryCarbonMap[catName]) categoryCarbonMap[catName] = 0;
            categoryCarbonMap[catName] += itemCarbon;
        });

        // Determine Top Eco-Category
        let topEcoCategory = 'None';
        let maxCarbon = -1;
        for (const [cat, carbon] of Object.entries(categoryCarbonMap)) {
            if (carbon > maxCarbon) {
                maxCarbon = carbon;
                topEcoCategory = cat;
            }
        }

        res.json({
            total_users: usersCount,
            active_users: activeUsers,
            suspended_users: suspendedUsers,
            total_listings: productsCount,
            active_disputes: activeDisputes,
            completed_transactions: transactions.length,
            gmv: gmv.toFixed(2),
            carbon_saved_kg: estimatedCarbonSaved,
            top_eco_category: topEcoCategory
        });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

export const getAllUsers = async (req, res) => {
    try {
        const users = await User.findAll();
        res.json(users);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

export const manageUserRoleOrBan = async (req, res) => {
    try {
        const { is_active, deactivated_until, deactivation_reason, role } = req.body;
        const user = await User.findByPk(req.params.id);
        if (!user) return res.status(404).json({ error: 'User not found' });

        // Security check: Prevent Admin civil war or self-lockout
        if (user.id === req.user.id) {
            return res.status(400).json({ error: 'You cannot ban or change roles for your own account.' });
        }
        if (user.role === 'admin') {
            return res.status(403).json({ error: 'You cannot modify the status of another Administrator.' });
        }

        if (role) user.role = role;
        
        let suspendListings = false;
        if (is_active !== undefined) {
            user.is_active = is_active;
            if (is_active === false) {
                suspendListings = true;
            }
        }
        
        if (deactivated_until !== undefined) user.deactivated_until = deactivated_until;
        if (deactivation_reason) user.deactivation_reason = deactivation_reason;
        
        await user.save();

        // Cascade Updates: Suspend all active listings if user is banned
        if (suspendListings) {
            await Product.update(
                { status: 'Suspended' },
                { where: { seller_id: user.id, status: 'Available' } }
            );
        }

        res.json({ message: 'User updated successfully', user, cascade_suspension: suspendListings });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

// Extremely basic mock triggers for Backup/Restore logic (Needs correct postgres OS config to run fully)
export const backupDatabase = async (req, res) => {
    // Basic conceptual wrapper for pg_dump
    res.json({ message: 'Database backup sequence initiated.', backup_file: 'backup_2026.sql' });
};

export const restoreDatabase = async (req, res) => {
    res.json({ message: 'Database restore sequence initiated. Server will go down momentarily.' });
};
