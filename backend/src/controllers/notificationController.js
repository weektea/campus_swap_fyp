import { Notification } from '../models/index.js';

/**
 * Retrieves all notifications for the authenticated user, ordered by creation date descending.
 *
 * @param {import('express').Request} req - The Express request object.
 * @param {import('express').Response} res - The Express response object.
 * @returns {Promise<void>} - Responds with a JSON array of notifications.
 * @throws {Error} - Responds with HTTP 500 if retrieval fails.
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
 *
 * @param {import('express').Request} req - The Express request object containing `id` parameter.
 * @param {import('express').Response} res - The Express response object.
 * @returns {Promise<void>} - Responds with success boolean.
 * @throws {Error} - Responds with HTTP 500 if database update fails.
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
 * Helper function to create a new notification. If a matching unread notification
 * with the same title and relatedId exists, it bubbles it to the top instead of duplicating.
 *
 * @param {string|number} userId - The target user identifier.
 * @param {string} title - The notification title.
 * @param {string} message - The notification message content.
 * @param {string} type - The notification category type.
 * @param {string|number} [relatedId] - The optional ID of the related object (e.g. product/transaction).
 * @returns {Promise<void>}
 * @throws {Error} - Catches internally and logs database insert failures.
 */
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

/**
 * Deletes a specific notification belonging to the authenticated user.
 *
 * @param {import('express').Request} req - The Express request object containing `id` parameter.
 * @param {import('express').Response} res - The Express response object.
 * @returns {Promise<Response>} - Responds with success status, or 404 if not found/unauthorized.
 * @throws {Error} - Responds with HTTP 500 if deletion fails.
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
 *
 * @param {import('express').Request} req - The Express request object.
 * @param {import('express').Response} res - The Express response object.
 * @returns {Promise<void>} - Responds with success status.
 * @throws {Error} - Responds with HTTP 500 if cleanup query fails.
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
