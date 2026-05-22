import { Message, User } from '../models/index.js';
import { Op } from 'sequelize';

// Send Message
export const sendMessage = async (req, res) => {
    try {
        const sender_id = req.user.id;
        const { receiver_id, content, mapped_zone_id } = req.body;

        if (!receiver_id || !content) {
            return res.status(400).json({ error: 'Missing details' });
        }

        const msg = await Message.create({ 
            sender_id, 
            receiver_id, 
            content,
            mapped_zone_id: mapped_zone_id || null // UC25: Safe Campus Zone Sharing
        });
        res.status(201).json(msg);
    } catch (error) {
        console.error('Send Msg Error:', error);
        res.status(500).json({ error: 'Failed to send' });
    }
};

// Get Conversation with specific user
export const getConversation = async (req, res) => {
    try {
        const userId = req.user.id;
        const { otherId } = req.params;

        const messages = await Message.findAll({
            where: {
                [Op.or]: [
                    { sender_id: userId, receiver_id: otherId },
                    { sender_id: otherId, receiver_id: userId }
                ]
            },
            order: [['createdAt', 'ASC']]
        });

        res.json(messages);
    } catch (error) {
        console.error('Get Conv Error:', error);
        res.status(500).json({ error: 'Failed to fetch conversation' });
    }
};

// Get list of users the current user has chatted with
export const getChatList = async (req, res) => {
    try {
        const userId = req.user.id;

        // Find all messages involving user
        // This is a naive implementation. For scale, use a separate 'Conversation' model.
        const messages = await Message.findAll({
            where: {
                [Op.or]: [
                    { sender_id: userId },
                    { receiver_id: userId }
                ]
            },
            include: [
                { model: User, as: 'sender', attributes: ['id', 'full_name'] },
                { model: User, as: 'receiver', attributes: ['id', 'full_name'] }
            ],
            order: [['createdAt', 'DESC']]
        });

        // Extract unique partners
        const partners = new Map();
        const userIdStr = String(userId);

        for (const msg of messages) {
            const isSender = String(msg.sender_id) === userIdStr;
            const partner = isSender ? msg.receiver : msg.sender;

            // Skip if partner is null (e.g. deleted user)
            if (!partner) continue;

            if (!partners.has(partner.id)) {
                partners.set(partner.id, {
                    id: partner.id,
                    name: partner.full_name,
                    lastMessage: msg.content,
                    time: msg.createdAt,
                    unread: 0 // logic to be added
                });
            }
        }

        res.json(Array.from(partners.values()));
    } catch (error) {
        console.error('Get Chat List Error:', error);
        res.status(500).json({ error: 'Failed to fetch chat list' });
    }
};
