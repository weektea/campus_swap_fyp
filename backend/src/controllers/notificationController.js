import { Notification, User } from '../models/index.js';
import { sendFcmNotification } from '../services/fcmService.js';
import { emitToUser } from '../config/socket.js';

/**
 * Retrieves all notifications for the authenticated user, ordered by creation date descending.
 */
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

/**
 * Marks a specific notification as read for the authenticated user.
 */
export const markAsRead = async (req, res) => {
    try {
        const { id } = req.params;
        const user_id = req.user.id;
        await Notification.update({ is_read: true }, { where: { id, user_id } });
        res.json({ success: true });
    } catch (error) {
        console.error('Mark Read Error:', error);
        res.status(500).json({ error: 'Failed to update notification' });
    }
};

/**
 * Marks all notifications as read for the authenticated user.
 */
export const markAllAsRead = async (req, res) => {
    try {
        const user_id = req.user.id;
        await Notification.update({ is_read: true }, { where: { user_id, is_read: false } });
        res.json({ success: true, message: 'All notifications marked as read' });
    } catch (error) {
        console.error('Mark All Read Error:', error);
        res.status(500).json({ error: 'Failed to mark all notifications as read' });
    }
};


/**
 * Saves or updates the FCM device token for the authenticated user.
 */
export const saveFcmToken = async (req, res) => {
    try {
        const { fcm_token } = req.body;
        const user_id = req.user.id;
        if (!fcm_token) {
            return res.status(400).json({ error: 'fcm_token is required' });
        }
        await User.update({ fcm_token }, { where: { id: user_id } });
        res.json({ success: true, message: 'FCM Token updated successfully' });
    } catch (error) {
        console.error('Save FCM Token Error:', error);
        res.status(500).json({ error: 'Failed to update FCM Token' });
    }
};

/**
 * Removes the FCM device token for the authenticated user on logout.
 */
export const removeFcmToken = async (req, res) => {
    try {
        const user_id = req.user.id;
        await User.update({ fcm_token: null }, { where: { id: user_id } });
        res.json({ success: true, message: 'FCM Token cleared successfully' });
    } catch (error) {
        console.error('Remove FCM Token Error:', error);
        res.status(500).json({ error: 'Failed to clear FCM Token' });
    }
};


/**
 * Helper function to create a new notification and dispatch an FCM Push Notification.
 */
export const createNotification = async (userId, title, message, type, relatedId) => {
    try {
        let createdNote;
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
                createdNote = existing;
            }
        }
        if (!createdNote) {
            createdNote = await Notification.create({
                user_id: userId,
                title,
                message,
                type,
                related_id: relatedId
            });
        }

        // Real-time instant WebSocket notification dispatch (0ms latency)
        emitToUser(userId, 'new_notification', createdNote.toJSON ? createdNote.toJSON() : createdNote);

        // Fetch user FCM token & dispatch Push Notification
        const user = await User.findByPk(userId, { attributes: ['fcm_token'] });
        if (user && user.fcm_token) {
            await sendFcmNotification(user.fcm_token, title, message, {
                relatedId: String(relatedId || ''),
                type: String(type || ''),
                notificationId: String(createdNote.id)
            });
        }
    } catch (error) {
        console.error('Create Notification Error:', error);
    }
};

/**
 * Deletes a specific notification belonging to the authenticated user.
 */
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

/**
 * Deletes all read notifications belonging to the authenticated user.
 */
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
