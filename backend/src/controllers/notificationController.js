import { Notification } from '../models/index.js';

export const getUserNotifications = async (req, res) => {
    try {
        const { user_id } = req.params;
        const notifications = await Notification.findAll({
            where: { user_id },
            order: [['createdAt', 'DESC']]
        });
        res.json(notifications);
    } catch (error) {
        console.error('Get Notifications Error:', error);
        res.status(500).json({ error: 'Failed to fetch notifications' });
    }
};

export const markAsRead = async (req, res) => {
    try {
        const { id } = req.params;
        await Notification.update({ is_read: true }, { where: { id } });
        res.json({ success: true });
    } catch (error) {
        console.error('Mark Read Error:', error);
        res.status(500).json({ error: 'Failed to update notification' });
    }
};

export const createNotification = async (userId, title, message, type, relatedId) => {
    try {
        await Notification.create({
            user_id: userId,
            title,
            message,
            type,
            related_id: relatedId
        });
    } catch (error) {
        console.error('Create Notification Error:', error);
    }
};
