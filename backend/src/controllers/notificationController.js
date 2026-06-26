import { Notification } from '../models/index.js';

export const getUserNotifications = async (req, res) => {
    try {
        const user_id = req.user.id;
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
        if (relatedId) {
            const existing = await Notification.findOne({
                where: {
                    user_id: userId,
                    title,
                    related_id: relatedId,
                    is_read: false
                }
            });
            if (existing) {
                existing.message = message;
                existing.createdAt = new Date(); // Bubble to top
                await existing.save();
                return;
            }
        }
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

export const deleteNotification = async (req, res) => {
    try {
        const { id } = req.params;
        const user_id = req.user.id;
        const result = await Notification.destroy({ where: { id, user_id } });
        if (result === 0) {
            return res.status(404).json({ error: 'Notification not found or unauthorized' });
        }
        res.json({ success: true });
    } catch (error) {
        console.error('Delete Notification Error:', error);
        res.status(500).json({ error: 'Failed to delete notification' });
    }
};

export const clearReadNotifications = async (req, res) => {
    try {
        const user_id = req.user.id;
        await Notification.destroy({ where: { user_id, is_read: true } });
        res.json({ success: true });
    } catch (error) {
        console.error('Clear Read Notifications Error:', error);
        res.status(500).json({ error: 'Failed to clear read notifications' });
    }
};

