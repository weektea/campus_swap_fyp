import { User, Product, Transaction, Report, SupportTicket, Category } from '../models/index.js';
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

export const replyTicket = async (req, res) => {
    try {
        const { reply_content, status } = req.body;
        const ticket = await SupportTicket.findByPk(req.params.id);
        if (!ticket) return res.status(404).json({ error: 'Ticket not found' });
        
        ticket.reply_content = reply_content;
        ticket.status = status; // Resolved, Escalated, etc.
        await ticket.save();
        res.json({ message: 'Ticket replied', ticket });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};


// ======================= ADMINISTRATOR ONLY =======================

export const getSystemMetrics = async (req, res) => {
    try {
        const usersCount = await User.count();
        const activeUsers = await User.count({ where: { is_active: true } });
        const productsCount = await Product.count();
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
        
        // Calculate true carbon footprint by summing the conversion_factor of each sold item
        let estimatedCarbonSaved = 0.0;
        transactions.forEach(t => {
            if (t.product && t.product.categoryModel) {
                estimatedCarbonSaved += t.product.categoryModel.carbon_conversion_factor;
            } else {
                estimatedCarbonSaved += 5.0; // Fallback for old/legacy products with strictly string category
            }
        });

        res.json({
            total_users: usersCount,
            active_users: activeUsers,
            total_listings: productsCount,
            completed_transactions: transactions.length,
            carbon_saved_kg: estimatedCarbonSaved
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

        if (role) user.role = role;
        if (is_active !== undefined) user.is_active = is_active;
        if (deactivated_until !== undefined) user.deactivated_until = deactivated_until;
        if (deactivation_reason) user.deactivation_reason = deactivation_reason;
        
        await user.save();
        res.json({ message: 'User updated successfully', user });
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
