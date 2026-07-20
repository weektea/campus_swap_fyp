import { Message, User, ActivityLog } from '../models/index.js';
import { Op } from 'sequelize';
import { emitToUser } from '../config/socket.js';

// Send Message
export const sendMessage = async (req, res) => {
    try {
        const sender_id = req.user.id;
        const { receiver_id, content, mapped_zone_id } = req.body;

        if (!receiver_id || !content) {
            return res.status(400).json({ error: 'Missing details' });
        }

        // Sensitive / Profane Word Filtering
        const sensitiveWords = [
            'whatsapp me off platform',
            'bank transfer outside app',
            'outside app',
            'pay directly to my bank',
            'direct bank transfer',
            'fuck', 'shit', 'bitch', 'asshole'
        ];

        let filteredContent = content;
        let hasScamPattern = false;

        sensitiveWords.forEach(word => {
            const regex = new RegExp(word.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&'), 'gi');
            if (regex.test(filteredContent)) {
                filteredContent = filteredContent.replace(regex, '***');
                if (word.includes('outside') || word.includes('platform') || word.includes('bank') || word.includes('transfer') || word.includes('whatsapp')) {
                    hasScamPattern = true;
                }
            }
        });

        // Trigger an auto-log warning if a scam/high-risk word is detected
        if (hasScamPattern) {
            try {
                await ActivityLog.create({
                    user_id: sender_id,
                    action: `ANOMALY: Chat Safety Warning - User [${sender_id}]: Sensitive scam pattern detected in chat.`
                });
            } catch (err) {
                console.error('Failed to log chat anomaly:', err);
            }
        }

        const msg = await Message.create({ 
            sender_id, 
            receiver_id, 
            content: filteredContent,
            mapped_zone_id: mapped_zone_id || null // UC25: Safe Campus Zone Sharing
        });

        // Fetch msg with sender details
        const msgWithSender = await Message.findByPk(msg.id, {
            include: [{ model: User, as: 'sender', attributes: ['id', 'username', 'full_name'] }]
        });

        // Emit message to receiver socket
        emitToUser(receiver_id, 'receive_new_message', msgWithSender || msg);

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
                { model: User, as: 'sender', attributes: ['id', 'username', 'full_name', 'profile_image_url'] },
                { model: User, as: 'receiver', attributes: ['id', 'username', 'full_name', 'profile_image_url'] }
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
                    name: partner.username,
                    username: partner.username,
                    full_name: partner.full_name,
                    profile_image_url: partner.profile_image_url,
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
