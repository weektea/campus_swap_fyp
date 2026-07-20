import { Op } from 'sequelize';
import sequelize from '../config/database.js';
import { User, ActivityLog, SystemSetting, PlatformPolicy } from '../models/index.js';

// GET /admin/system/health
export const getSystemHealth = async (req, res) => {
    try {
        // 1. Uptime in hours/seconds
        const uptimeSeconds = process.uptime();
        const uptimeHours = (uptimeSeconds / 3600).toFixed(2);

        // 2. Memory Usage
        const mem = process.memoryUsage();
        const memoryUsage = {
            heapUsed: (mem.heapUsed / 1024 / 1024).toFixed(2) + ' MB',
            heapTotal: (mem.heapTotal / 1024 / 1024).toFixed(2) + ' MB',
            rss: (mem.rss / 1024 / 1024).toFixed(2) + ' MB'
        };

        // 3. Database status check
        let dbStatus = 'healthy';
        try {
            await sequelize.query('SELECT 1');
        } catch (dbErr) {
            console.error('Database health check failed:', dbErr);
            dbStatus = 'error';
        }

        // 4. Active JWT connections count (approx. by users with active logs in the last 1 hour)
        const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
        const activeSessions = await ActivityLog.count({
            distinct: true,
            col: 'user_id',
            where: {
                createdAt: {
                    [Op.gte]: oneHourAgo
                }
            }
        });

        res.json({
            uptime: `${uptimeHours} hours (${Math.round(uptimeSeconds)} seconds)`,
            memory_usage: memoryUsage,
            db_status: dbStatus,
            active_sessions: Math.max(activeSessions, 1), // At least current admin
            timestamp: new Date()
        });
    } catch (e) {
        console.error('Error fetching system health:', e);
        res.status(500).json({ error: 'Failed to retrieve system health metrics' });
    }
};

// GET /admin/system/settings
export const getSystemSettings = async (req, res) => {
    try {
        let settings = await SystemSetting.findAll();
        // Seed initial values if empty
        if (settings.length === 0) {
            await SystemSetting.bulkCreate([
                { key: 'MAX_REPORTS_PER_10MIN', value: '10', description: 'Anti-spam limit for submitting report tickets' },
                { key: 'DEFAULT_CARBON_FACTOR', value: '2.5', description: 'Default CO2 reduction weight in kg per item reused' },
                { key: 'MAINTENANCE_MODE', value: 'false', description: 'Restricts platform access for system upgrades (true/false)' },
                { key: 'ANTI_SPAM_LIMIT', value: '5', description: 'Maximum listing requests allowed per minute' }
            ]);
            settings = await SystemSetting.findAll();
        }
        res.json(settings);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

// PUT /admin/system/settings
export const updateSystemSettings = async (req, res) => {
    try {
        const { settings } = req.body;
        if (!settings || typeof settings !== 'object') {
            return res.status(400).json({ error: 'Invalid settings payload format' });
        }

        // Bulk update database keys
        for (const [key, value] of Object.entries(settings)) {
            await SystemSetting.upsert({
                key,
                value: String(value),
                updated_by: req.user.id
            });
        }

        // Log the config updates to the Audit Trail
        await ActivityLog.create({
            user_id: req.user.id,
            action: `SYSTEM_SETTINGS_UPDATED: Keys [${Object.keys(settings).join(', ')}]`
        });

        res.json({ message: 'System configurations updated successfully' });
    } catch (e) {
        console.error('Failed updating system settings:', e);
        res.status(500).json({ error: 'Failed to update system configurations' });
    }
};

// GET /api/policies/:type (Public policy fetch)
export const getPolicyByType = async (req, res) => {
    try {
        const type = req.params.type.toUpperCase();
        if (!['TERMS', 'PRIVACY', 'COMMUNITY_RULES'].includes(type)) {
            return res.status(400).json({ error: 'Invalid policy type' });
        }

        let policy = await PlatformPolicy.findOne({ where: { policy_type: type } });
        // Seed default policy if not found in db
        if (!policy) {
            let defaultContent = '';
            if (type === 'TERMS') {
                defaultContent = '# Terms & Conditions\n\nWelcome to Campus Swap!\n\n1. Active Campus Enrollment: You must verify your student email domain to list items.\n2. Fair Exchanges: We prohibit counterfeit items or illegal items.\n3. Safety first: We recommend utilizing designated campus meetup zones.';
            } else if (type === 'PRIVACY') {
                defaultContent = '# Privacy Guidelines\n\nWe prioritize student privacy.\n\n1. Verification: Verification IDs are handled securely.\n2. Chat histories: Chat communication logs are stored for security reviews.';
            } else {
                defaultContent = '# Community Rules\n\n1. Respect peer exchange values.\n2. Avoid listing spam or duplicates.\n3. Complete transaction meetups inside safe-zones.';
            }

            policy = await PlatformPolicy.create({
                policy_type: type,
                content: defaultContent,
                version: '1.0.0'
            });
        }

        res.json(policy);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

// PUT /admin/system/policies/:type (Admin policy edit)
export const updatePolicy = async (req, res) => {
    try {
        const type = req.params.type.toUpperCase();
        if (!['TERMS', 'PRIVACY', 'COMMUNITY_RULES'].includes(type)) {
            return res.status(400).json({ error: 'Invalid policy type' });
        }

        const { content, version } = req.body;
        if (!content || !version) {
            return res.status(400).json({ error: 'Content and version strings are required' });
        }

        let policy = await PlatformPolicy.findOne({ where: { policy_type: type } });
        if (policy) {
            policy.content = content;
            policy.version = version;
            await policy.save();
        } else {
            policy = await PlatformPolicy.create({
                policy_type: type,
                content,
                version
            });
        }

        // Log audit trail
        await ActivityLog.create({
            user_id: req.user.id,
            action: `PLATFORM_POLICY_UPDATED: Type [${type}], Version [${version}]`
        });

        res.json({ message: `Policy ${type} updated successfully`, policy });
    } catch (e) {
        console.error('Failed to update policy content:', e);
        res.status(500).json({ error: 'Failed to save updated platform policy guidelines' });
    }
};
