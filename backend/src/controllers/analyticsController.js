import { Op } from 'sequelize';
import { Transaction, Product, SupportTicket, Review, ActivityLog, User } from '../models/index.js';

export const getProfileAnalytics = async (req, res) => {
    try {
        const userId = req.user.id;

        // 1. Transaction & ESG Statistics (Past 6 Months)
        const sixMonthsAgo = new Date();
        sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);

        // Fetch completed sales (earnings + seller carbon points)
        const sales = await Transaction.findAll({
            where: {
                seller_id: userId,
                status: 'Completed',
                completed_at: {
                    [Op.gte]: sixMonthsAgo
                }
            },
            attributes: ['amount', 'awarded_carbon_points', 'completed_at']
        });

        // Fetch completed purchases (buyer carbon points)
        const purchases = await Transaction.findAll({
            where: {
                buyer_id: userId,
                status: 'Completed',
                completed_at: {
                    [Op.gte]: sixMonthsAgo
                }
            },
            attributes: ['awarded_carbon_points', 'completed_at']
        });

        // Set up 6-month buckets
        const monthlyData = {};
        for (let i = 5; i >= 0; i--) {
            const d = new Date();
            d.setMonth(d.getMonth() - i);
            const monthName = d.toLocaleString('en-US', { month: 'short' });
            const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
            monthlyData[key] = { month: monthName, earnings: 0.0, carbonSaved: 0.0 };
        }

        // Aggregate Sales
        for (const s of sales) {
            if (s.completed_at) {
                const date = new Date(s.completed_at);
                const key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
                if (monthlyData[key]) {
                    monthlyData[key].earnings += parseFloat(s.amount) || 0.0;
                    monthlyData[key].carbonSaved += parseFloat(s.awarded_carbon_points) || 0.0;
                }
            }
        }

        // Aggregate Purchases
        for (const p of purchases) {
            if (p.completed_at) {
                const date = new Date(p.completed_at);
                const key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
                if (monthlyData[key]) {
                    monthlyData[key].carbonSaved += parseFloat(p.awarded_carbon_points) || 0.0;
                }
            }
        }

        const monthlyStats = Object.values(monthlyData);

        // 2. Reputation Breakdown (only PUBLISHED reviews)
        const reviews = await Review.findAll({
            include: [{
                model: Transaction,
                as: 'transaction',
                where: { review_status: 'PUBLISHED' }
            }],
            where: { reviewee_id: userId }
        });

        let fiveStars = 0;
        let others = 0;

        for (const r of reviews) {
            if (r.rating === 5) {
                fiveStars++;
            } else {
                others++;
            }
        }

        // 3. Activity Timeline
        // A. Fetch recent audit logs from ActivityLog
        const logs = await ActivityLog.findAll({
            where: { user_id: userId },
            order: [['createdAt', 'DESC']],
            limit: 20
        });

        const timelineEvents = logs.map(l => ({
            action: l.action,
            timestamp: l.createdAt,
            source: 'log'
        }));

        // B. Dynamic synthesis to backfill timeline events for existing data
        if (timelineEvents.length < 10) {
            // Synthesize items listed
            const products = await Product.findAll({
                where: { seller_id: userId },
                limit: 10
            });
            for (const p of products) {
                if (!timelineEvents.some(e => e.action === 'ITEM_LISTED' && Math.abs(new Date(e.timestamp) - new Date(p.createdAt)) < 5000)) {
                    timelineEvents.push({
                        action: 'ITEM_LISTED',
                        timestamp: p.createdAt,
                        source: 'synthesized'
                    });
                }
            }

            // Synthesize sales (ITEM_SOLD)
            const completedSales = await Transaction.findAll({
                where: { seller_id: userId, status: 'Completed' },
                limit: 10
            });
            for (const s of completedSales) {
                const time = s.completed_at || s.updatedAt || s.createdAt;
                if (!timelineEvents.some(e => e.action === 'ITEM_SOLD' && Math.abs(new Date(e.timestamp) - new Date(time)) < 5000)) {
                    timelineEvents.push({
                        action: 'ITEM_SOLD',
                        timestamp: time,
                        source: 'synthesized'
                    });
                }
            }

            // Synthesize purchases (ITEM_BOUGHT)
            const completedPurchases = await Transaction.findAll({
                where: { buyer_id: userId, status: 'Completed' },
                limit: 10
            });
            for (const p of completedPurchases) {
                const time = p.completed_at || p.updatedAt || p.createdAt;
                if (!timelineEvents.some(e => e.action === 'ITEM_BOUGHT' && Math.abs(new Date(e.timestamp) - new Date(time)) < 5000)) {
                    timelineEvents.push({
                        action: 'ITEM_BOUGHT',
                        timestamp: time,
                        source: 'synthesized'
                    });
                }
            }

            // Synthesize tickets opened (TICKET_OPENED)
            const tickets = await SupportTicket.findAll({
                where: { user_id: userId },
                limit: 10
            });
            for (const t of tickets) {
                if (!timelineEvents.some(e => e.action === 'TICKET_OPENED' && Math.abs(new Date(e.timestamp) - new Date(t.createdAt)) < 5000)) {
                    timelineEvents.push({
                        action: 'TICKET_OPENED',
                        timestamp: t.createdAt,
                        source: 'synthesized'
                    });
                }
            }
        }

        // Sort and limit timeline to recent 15 events
        timelineEvents.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
        const finalTimeline = timelineEvents.slice(0, 15);

        res.json({
            monthlyStats,
            ratingsDistribution: {
                fiveStars,
                others
            },
            timeline: finalTimeline
        });

    } catch (error) {
        console.error('Profile Analytics aggregation error:', error);
        res.status(500).json({ error: 'Failed to aggregate profile analytics' });
    }
};

export const getAdminAnalytics = async (req, res) => {
    try {
        const sixMonthsAgo = new Date();
        sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
        sixMonthsAgo.setDate(1);
        sixMonthsAgo.setHours(0, 0, 0, 0);

        // --- 1. User Growth Analysis ---
        const users = await User.findAll({
            where: {
                createdAt: { [Op.gte]: sixMonthsAgo }
            },
            attributes: ['createdAt']
        });

        // --- 2. Completed Transaction Earnings ---
        const transactions = await Transaction.findAll({
            where: {
                status: 'Completed',
                completed_at: { [Op.gte]: sixMonthsAgo }
            },
            include: [{
                model: Product,
                as: 'product',
                include: [{
                    model: Category,
                    as: 'categoryModel'
                }]
            }],
            order: [['completed_at', 'ASC']]
        });

        // Set up month buckets (past 6 months: current month + past 5)
        const monthBuckets = [];
        for (let i = 5; i >= 0; i--) {
            const d = new Date();
            d.setMonth(d.getMonth() - i);
            const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
            const label = d.toLocaleString('en-US', { month: 'short', year: '2-digit' });
            monthBuckets.push({ key, label, registrations: 0, earnings: 0.0 });
        }

        // Populate User growth registrations
        users.forEach(u => {
            const d = new Date(u.createdAt);
            const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
            const bucket = monthBuckets.find(b => b.key === key);
            if (bucket) {
                bucket.registrations += 1;
            }
        });

        // Order Type breakdown: Sale vs. Rent
        let saleCount = 0;
        let rentCount = 0;

        // Carbon Savings by Product Category (Bar chart data)
        const carbonSavingsByCategory = {};

        // Populate Earnings & Carbon Savings
        transactions.forEach(t => {
            const d = new Date(t.completed_at || t.createdAt);
            const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
            const bucket = monthBuckets.find(b => b.key === key);
            if (bucket) {
                bucket.earnings += parseFloat(t.amount || 0);
            }

            // Order Type Breakdown
            if (t.product) {
                if (t.product.type === 'Rent') {
                    rentCount += 1;
                } else {
                    saleCount += 1;
                }

                // Category distribution
                const catName = t.product.categoryModel ? t.product.categoryModel.name : (t.product.category || 'Other');
                const carbonVal = parseFloat(t.awarded_carbon_points || 2.5);
                if (!carbonSavingsByCategory[catName]) {
                    carbonSavingsByCategory[catName] = 0.0;
                }
                carbonSavingsByCategory[catName] += carbonVal;
            }
        });

        // --- Linear Regression / Trend Prediction for next 3 months ---
        // monthly earnings actual y values
        const earningsY = monthBuckets.map(b => b.earnings);
        const n = earningsY.length;
        
        let sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;
        for (let i = 0; i < n; i++) {
            sumX += i;
            sumY += earningsY[i];
            sumXY += i * earningsY[i];
            sumXX += i * i;
        }
        const denominator = (n * sumXX - sumX * sumX);
        const slope = denominator === 0 ? 0.0 : (n * sumXY - sumX * sumY) / denominator;
        const intercept = (sumY - slope * sumX) / n;

        // Future predictions (next 3 months)
        const predictionMonths = [];
        const predictionValues = [];
        for (let i = n; i < n + 3; i++) {
            const d = new Date();
            d.setMonth(d.getMonth() + (i - n + 1));
            const label = d.toLocaleString('en-US', { month: 'short', year: '2-digit' });
            const val = Math.max(0.0, parseFloat((slope * i + intercept).toFixed(2)));
            predictionMonths.push(label);
            predictionValues.push(val);
        }

        // --- Security & Anomaly Logs ---
        const anomalyLogs = await ActivityLog.findAll({
            where: {
                action: {
                    [Op.like]: 'ANOMALY:%'
                }
            },
            include: [{
                model: User,
                as: 'user',
                attributes: ['username', 'email']
            }],
            order: [['createdAt', 'DESC']],
            limit: 20
        });

        // Construct standard counts
        const totalUsers = await User.count();
        const activeListings = await Product.count({ where: { status: 'Available' } });
        const completedCount = await Transaction.count({ where: { status: 'Completed' } });
        const totalCarbon = await Transaction.sum('awarded_carbon_points', { where: { status: 'Completed' } }) || 0.0;

        res.json({
            total_users: totalUsers,
            active_listings: activeListings,
            completed_transactions: completedCount,
            total_carbon_saved: parseFloat(totalCarbon.toFixed(2)),
            growth_labels: monthBuckets.map(b => b.label),
            growth_data: monthBuckets.map(b => b.registrations),
            earnings_labels: monthBuckets.map(b => b.label),
            earnings_actual: earningsY,
            prediction_labels: predictionMonths,
            prediction_values: predictionValues,
            order_type_breakdown: {
                sale: saleCount,
                rent: rentCount
            },
            carbon_by_category: Object.entries(carbonSavingsByCategory).map(([category, value]) => ({
                category,
                value: parseFloat(value.toFixed(2))
            })),
            anomaly_logs: anomalyLogs.map(l => ({
                id: l.id,
                action: l.action,
                timestamp: l.createdAt,
                username: l.user ? l.user.username : 'System Anomaly'
            }))
        });

    } catch (e) {
        console.error('Admin Analytics Error:', e);
        res.status(500).json({ error: 'Failed to aggregate admin analytics data' });
    }
};

export const exportEnvironmentalReport = async (req, res) => {
    try {
        const { startDate, endDate } = req.query;
        if (!startDate || !endDate) {
            return res.status(400).json({ error: 'Missing start or end date' });
        }

        const start = new Date(startDate);
        const end = new Date(endDate);
        end.setHours(23, 59, 59, 999);

        const transactions = await Transaction.findAll({
            where: {
                status: 'Completed',
                completed_at: {
                    [Op.between]: [start, end]
                }
            },
            include: [
                {
                    model: Product,
                    as: 'product',
                    include: [{ model: Category, as: 'categoryModel' }]
                },
                {
                    model: User,
                    as: 'buyer',
                    attributes: ['username']
                },
                {
                    model: User,
                    as: 'seller',
                    attributes: ['username']
                }
            ],
            order: [['completed_at', 'ASC']]
        });

        // Generate CSV string
        let csv = 'Transaction ID,Completed Date,Product Title,Category,Price (RM),Carbon Saved (kg CO2e),Buyer,Seller\n';
        transactions.forEach(t => {
            const dateStr = t.completed_at ? new Date(t.completed_at).toISOString().split('T')[0] : 'N/A';
            const title = t.product ? t.product.title.replace(/"/g, '""') : 'N/A';
            const cat = t.product && t.product.categoryModel ? t.product.categoryModel.name : (t.product?.category || 'Other');
            const price = t.amount || '0.00';
            const carbon = t.awarded_carbon_points || '0.00';
            const buyer = t.buyer ? t.buyer.username : 'N/A';
            const seller = t.seller ? t.seller.username : 'N/A';

            csv += `"${t.id}","${dateStr}","${title}","${cat}",${price},${carbon},"${buyer}","${seller}"\n`;
        });

        res.setHeader('Content-Type', 'text/csv');
        res.setHeader('Content-Disposition', `attachment; filename="Environmental_Impact_Report_${startDate}_to_${endDate}.csv"`);
        res.send(csv);

    } catch (e) {
        console.error('Export Report Error:', e);
        res.status(500).json({ error: 'Failed to generate report' });
    }
};
