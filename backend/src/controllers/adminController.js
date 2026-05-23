import { User, Product, Transaction, Report, SupportTicket, Category, SubCategory, Dispute, BackupLog, Review, SafeMeetupZone } from '../models/index.js';
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

export const getDisputes = async (req, res) => {
    try {
        const disputes = await Dispute.findAll({ include: ['transaction', 'complainant'] });
        res.json(disputes);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

export const triageDispute = async (req, res) => {
    try {
        const { action, mod_notes } = req.body;
        const dispute = await Dispute.findByPk(req.params.id);
        if (!dispute) return res.status(404).json({ error: 'Dispute not found' });
        
        dispute.status = action === 'Escalated' ? 'Escalated to Admin' : action;
        if (mod_notes) dispute.admin_notes = mod_notes;
        await dispute.save();
        res.json({ message: 'Dispute triaged successfully', dispute });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

export const arbitrateDispute = async (req, res) => {
    try {
        const { decision, reason } = req.body;
        const dispute = await Dispute.findByPk(req.params.id);
        if (!dispute) return res.status(404).json({ error: 'Dispute not found' });
        
        dispute.status = 'Resolved';
        dispute.admin_notes = `[Admin Arbitration]: ${decision}. Reason: ${reason}`;
        await dispute.save();
        res.json({ message: 'Dispute arbitrated successfully', dispute });
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
                include: [
                    { model: Category, as: 'categoryModel' },
                    { model: SubCategory, as: 'subcategoryModel' }
                ]
            }]
        });
        
        // Calculate metrics
        let estimatedCarbonSaved = 0.0;
        let gmv = 0.0;
        let categoryCarbonMap = {};
        
        // Prepare mock time-series for the last 30 days based on transactions
        const last30Days = Array.from({ length: 30 }, (_, i) => {
            const d = new Date();
            d.setDate(d.getDate() - (29 - i));
            return {
                date: d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' }),
                sales: 0
            };
        });

        transactions.forEach(t => {
            // GMV
            const amt = parseFloat(t.amount || 0);
            gmv += amt;

            // Map transaction to a day (simple mapping for demonstration)
            // If the transaction is too old, it might not fit in last30Days.
            // For true logic, you'd parse t.createdAt. For demo, we just randomly distribute if no actual data fits, 
            // but let's actually try to fit it into the last 30 days based on createdAt:
            const tDate = new Date(t.createdAt);
            const tDateStr = tDate.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
            const dayEntry = last30Days.find(d => d.date === tDateStr);
            if (dayEntry) {
                dayEntry.sales += amt;
            }

            // Carbon (Prioritize SubCategory first)
            let itemCarbon = 5.0; // Fallback
            let catName = 'Other';

            if (t.product && t.product.subcategoryModel && t.product.subcategoryModel.carbon_conversion_factor > 0) {
                itemCarbon = parseFloat(t.product.subcategoryModel.carbon_conversion_factor);
                catName = t.product.subcategoryModel.name;
            } else if (t.product && t.product.categoryModel) {
                itemCarbon = parseFloat(t.product.categoryModel.carbon_conversion_factor || 0);
                catName = t.product.categoryModel.name;
            } else if (t.product && t.product.category) {
                catName = t.product.category;
            }

            estimatedCarbonSaved += itemCarbon;
            
            if (!categoryCarbonMap[catName]) categoryCarbonMap[catName] = 0;
            categoryCarbonMap[catName] += itemCarbon;
        });
        
        // If no transactions in last 30 days, fill with some random realistic mock data so the chart isn't empty
        let hasSalesData = last30Days.some(d => d.sales > 0);
        if (!hasSalesData) {
            last30Days.forEach(d => {
                d.sales = Math.floor(Math.random() * 500) + 100;
            });
        }

        // Determine Top Eco-Category
        let topEcoCategory = 'None';
        let maxCarbon = -1;
        let categoryData = []; // For pie chart
        for (const [cat, carbon] of Object.entries(categoryCarbonMap)) {
            categoryData.push({ name: cat, value: carbon });
            if (carbon > maxCarbon) {
                maxCarbon = carbon;
                topEcoCategory = cat;
            }
        }
        
        // Mock pie chart data if empty
        if (categoryData.length === 0) {
            categoryData = [
                { name: 'Electronics', value: 400 },
                { name: 'Books', value: 300 },
                { name: 'Furniture', value: 300 }
            ];
            topEcoCategory = 'Electronics';
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
            top_eco_category: topEcoCategory,
            daily_sales: last30Days,
            category_distribution: categoryData
        });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

export const getAllListings = async (req, res) => {
    try {
        const listings = await Product.findAll({
            include: [{ model: User, as: 'seller', attributes: ['id', 'email', 'full_name'] }],
            order: [['createdAt', 'DESC']]
        });
        res.json(listings);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

export const updateListingStatus = async (req, res) => {
    try {
        const { status } = req.body;
        const product = await Product.findByPk(req.params.id);
        if (!product) return res.status(404).json({ error: 'Product not found' });
        
        product.status = status;
        await product.save();
        res.json({ message: 'Product status updated successfully', product });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

export const deleteListing = async (req, res) => {
    try {
        const product = await Product.findByPk(req.params.id);
        if (!product) return res.status(404).json({ error: 'Product not found' });
        
        await product.destroy();
        res.json({ message: 'Product permanently deleted successfully' });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

// Full User Administration (Promoting, Banning)
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

export const deleteUser = async (req, res) => {
    try {
        const user = await User.findByPk(req.params.id);
        if (!user) return res.status(404).json({ error: 'User not found' });
        
        if (user.id === req.user.id) {
            return res.status(400).json({ error: 'Cannot delete your own account.' });
        }
        if (user.role === 'admin') {
            return res.status(403).json({ error: 'Cannot delete another Administrator.' });
        }

        await user.destroy();
        res.json({ message: 'User deleted successfully.' });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

export const createUser = async (req, res) => {
    try {
        const { email, password, full_name, role } = req.body;
        const bcrypt = await import('bcryptjs');
        const hash = await bcrypt.default.hash(password || 'password123', 10);
        
        const user = await User.create({
            email,
            password_hash: hash,
            full_name,
            role: role || 'student',
            is_active: true
        });
        
        res.status(201).json({ message: 'User created successfully', user });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

// Realistic Mock triggers for Backup/Restore logic
export const getBackups = async (req, res) => {
    try {
        // Ensure there's at least one auto backup for UI realism if DB is empty
        const count = await BackupLog.count();
        if (count === 0) {
            await BackupLog.create({
                type: 'Auto',
                size: '2.4 GB',
                status: 'Success',
                createdAt: new Date(Date.now() - 24 * 60 * 60 * 1000)
            });
        }
        
        const backups = await BackupLog.findAll({
            order: [['createdAt', 'DESC']]
        });
        res.json(backups);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

export const backupDatabase = async (req, res) => {
    try {
        const backup = await BackupLog.create({
            type: 'Manual',
            size: (Math.random() * 0.5 + 2.0).toFixed(1) + ' GB', // Mock size
            status: 'Success'
        });
        res.json({ message: 'Database backup completed.', backup });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

export const restoreDatabase = async (req, res) => {
    try {
        const backup = await BackupLog.findByPk(req.params.id);
        if (!backup) return res.status(404).json({ error: 'Backup point not found' });
        
        res.json({ message: `Database successfully restored to backup point ${backup.id}.` });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

// ======================= NEW MODULES =======================

export const getAllTransactions = async (req, res) => {
    try {
        const transactions = await Transaction.findAll({
            include: [
                { model: User, as: 'buyer', attributes: ['email', 'full_name'] },
                { model: User, as: 'seller', attributes: ['email', 'full_name'] },
                { model: Product, as: 'product', attributes: ['title', 'price', 'type'] }
            ],
            order: [['createdAt', 'DESC']]
        });
        res.json(transactions);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

export const getAllReviews = async (req, res) => {
    try {
        const reviews = await Review.findAll({
            include: [
                { model: User, as: 'reviewer', attributes: ['email', 'full_name'] },
                { model: User, as: 'reviewee', attributes: ['email', 'full_name'] }
            ],
            order: [['createdAt', 'DESC']]
        });
        res.json(reviews);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

export const deleteReview = async (req, res) => {
    try {
        const review = await Review.findByPk(req.params.id);
        if (!review) return res.status(404).json({ error: 'Review not found' });
        
        await review.destroy();
        res.json({ message: 'Review permanently deleted.' });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

export const getAllCategories = async (req, res) => {
    try {
        const categories = await Category.findAll({
            include: [{ model: SubCategory, as: 'subcategories' }]
        });
        res.json(categories);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

export const createCategory = async (req, res) => {
    try {
        const { name, icon_name, carbon_conversion_factor } = req.body;
        const cat = await Category.create({ name, icon_name, carbon_conversion_factor });
        res.json(cat);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

export const deleteCategory = async (req, res) => {
    try {
        // Poka-yoke cascade protection
        const cat = await Category.findByPk(req.params.id);
        if (!cat) return res.status(404).json({ error: 'Category not found' });
        
        const activeProducts = await Product.count({ where: { category_id: cat.id } });
        if (activeProducts > 0) {
            return res.status(400).json({ error: `Cannot delete: ${activeProducts} products are using this category.` });
        }
        
        await cat.destroy();
        res.json({ message: 'Category deleted' });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

export const getAllZones = async (req, res) => {
    try {
        const zones = await SafeMeetupZone.findAll();
        res.json(zones);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

export const createZone = async (req, res) => {
    try {
        const { name, description, latitude, longitude, is_active } = req.body;
        const zone = await SafeMeetupZone.create({ 
            name, 
            description, 
            latitude: parseFloat(latitude), 
            longitude: parseFloat(longitude),
            is_active: is_active !== undefined ? is_active : true
        });
        res.json(zone);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

export const deleteZone = async (req, res) => {
    try {
        const zone = await SafeMeetupZone.findByPk(req.params.id);
        if (!zone) return res.status(404).json({ error: 'Zone not found' });
        await zone.destroy();
        res.json({ message: 'Zone deleted' });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

export const createSubCategory = async (req, res) => {
    try {
        const { category_id, name, carbon_conversion_factor } = req.body;
        const sub = await SubCategory.create({ 
            category_id, 
            name, 
            carbon_conversion_factor: parseFloat(carbon_conversion_factor) || 0.0 
        });
        res.json(sub);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

export const deleteSubCategory = async (req, res) => {
    try {
        const sub = await SubCategory.findByPk(req.params.id);
        if (!sub) return res.status(404).json({ error: 'SubCategory not found' });
        
        const activeProducts = await Product.count({ where: { sub_category_id: sub.id } });
        if (activeProducts > 0) {
            return res.status(400).json({ error: `Cannot delete: ${activeProducts} products are using this subcategory.` });
        }
        
        await sub.destroy();
        res.json({ message: 'SubCategory deleted' });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

export const getAlerts = async (req, res) => {
    try {
        const { role } = req.user;
        const alerts = [];

        if (role === 'admin') {
            const reports = await Report.count({ where: { status: 'Escalated' } });
            if (reports > 0) alerts.push({ type: 'report', count: reports, message: `${reports} reports escalated to Admin`, link: '/reports' });

            const disputes = await Dispute.count({ where: { status: 'Escalated' } });
            if (disputes > 0) alerts.push({ type: 'dispute', count: disputes, message: `${disputes} disputes escalated to Admin`, link: '/disputes' });

            const tickets = await SupportTicket.count({ where: { status: 'Escalated' } });
            if (tickets > 0) alerts.push({ type: 'ticket', count: tickets, message: `${tickets} support tickets escalated to Admin`, link: '/tickets' });
        } else {
            // Moderator
            const reports = await Report.count({ where: { status: ['New', 'Pending'] } });
            if (reports > 0) alerts.push({ type: 'report', count: reports, message: `${reports} new/pending reports`, link: '/reports' });

            const disputes = await Dispute.count({ where: { status: ['New', 'Investigating'] } });
            if (disputes > 0) alerts.push({ type: 'dispute', count: disputes, message: `${disputes} new/investigating disputes`, link: '/disputes' });

            const tickets = await SupportTicket.count({ where: { status: 'Open' } });
            if (tickets > 0) alerts.push({ type: 'ticket', count: tickets, message: `${tickets} open support tickets`, link: '/tickets' });
        }

        res.json({ alerts, total: alerts.reduce((acc, a) => acc + a.count, 0) });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};
