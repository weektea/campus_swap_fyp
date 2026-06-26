import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { User, Transaction, Dispute, Report, Product } from '../models/index.js';
import { Op } from 'sequelize';

export const register = async (req, res) => {
    try {
        const { email, password, full_name, university_id, phone_number } = req.body;

        // 1. Validation
        if (!email || !password || !full_name || !university_id) {
            return res.status(400).json({ error: 'All fields are required' });
        }

        // Email Validation
        if (!email.endsWith('.edu.my')) {
            return res.status(400).json({ error: 'Must use a valid .edu.my student email' });
        }

        // University ID Validation (YYAAAXXXXX)
        // e.g., 24PMR01234
        const uniIdRegex = /^\d{2}[a-zA-Z]{3}\d{5}$/;
        if (!uniIdRegex.test(university_id)) {
            return res.status(400).json({
                error: 'Invalid University ID format. Example: 24PMR01234 (YYAAAXXXXX)'
            });
        }

        // Password Validation (Min 8, 1 Upper, 1 Lower, 1 Number, 1 Symbol)
        const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}$/;
        if (!passwordRegex.test(password)) {
            return res.status(400).json({
                error: 'Password must vary: Min 8 chars, incl. uppercase, lowercase, number & symbol.'
            });
        }

        // Phone Validation (e.g., +6016-1234567 or +6011-23456789)
        // Matches +60 followed by 2 digits, a dash, and 7-8 digits
        const phoneRegex = /^\+60\d{2}-\d{7,8}$/;
        if (phone_number && !phoneRegex.test(phone_number)) {
            return res.status(400).json({
                error: 'Invalid phone format. Use: +601x-xxxxxxx'
            });
        }

        // 2. Check existing
        const existingEmail = await User.findOne({ where: { email } });
        if (existingEmail) {
            return res.status(400).json({ error: 'Email already registered' });
        }

        const existingUniId = await User.findOne({ where: { university_id } });
        if (existingUniId) {
            return res.status(400).json({ error: 'University ID already registered' });
        }

        if (phone_number) {
            const existingPhone = await User.findOne({ where: { phone_number } });
            if (existingPhone) {
                return res.status(400).json({ error: 'Phone number already registered' });
            }
        }

        // 3. Hash Password
        const hashedPassword = await bcrypt.hash(password, 10);

        // 4. Create User
        const user = await User.create({
            email,
            password_hash: hashedPassword,
            full_name,
            university_id: university_id.toUpperCase(), // Store uniform uppercase
            phone_number,
            role: 'student',
            is_verified: true,
        });

        // 5. Generate Token
        const token = jwt.sign(
            { id: user.id, email: user.email, role: user.role },
            process.env.JWT_SECRET || 'secret_key_dev',
            { expiresIn: '30d' }
        );

        res.status(201).json({
            message: 'Registration successful',
            token,
            user: {
                id: user.id,
                email: user.email,
                full_name: user.full_name,
                role: user.role
            }
        });

    } catch (error) {
        console.error('Register Error:', error);
        res.status(500).json({ error: 'Registration failed' });
    }
};

export const login = async (req, res) => {
    try {
        const { email, student_id, password } = req.body;
        
        const identifier = email || student_id;

        // 1. Check User by email or university_id
        let user = await User.findOne({ where: { email: identifier } });
        if (!user) {
            user = await User.findOne({ where: { university_id: identifier } });
        }
        
        if (!user) {
            return res.status(400).json({ error: 'Invalid ID/email or password' });
        }

        // Security check: Is user banned?
        if (user.is_active === false) {
            return res.status(403).json({ 
                error: 'Account Suspended', 
                reason: user.deactivation_reason || 'Violation of community guidelines',
                unban_date: user.deactivated_until 
            });
        }

        // 2. Check Password
        const isMatch = await bcrypt.compare(password, user.password_hash);
        if (!isMatch) {
            return res.status(400).json({ error: 'Invalid ID/email or password' });
        }

        // 3. Generate Token
        const token = jwt.sign(
            { id: user.id, email: user.email, role: user.role },
            process.env.JWT_SECRET || 'secret_key_dev',
            { expiresIn: '30d' }
        );

        res.json({
            message: 'Login successful',
            token,
            user: {
                id: user.id,
                email: user.email,
                full_name: user.full_name,
                role: user.role
            }
        });

    } catch (error) {
        console.error('Login Error:', error);
        res.status(500).json({ error: 'Login failed' });
    }
};

export const updateProfile = async (req, res) => {
    try {
        const { id } = req.params;
        const updates = req.body; // e.g. { profile_picture: '...' }

        const user = await User.findByPk(id);
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        // Whitelist allowed updates
        if (updates.profile_picture !== undefined) user.profile_image_url = updates.profile_picture;
        if (updates.full_name !== undefined) user.full_name = updates.full_name;
        if (updates.phone_number !== undefined) user.phone_number = updates.phone_number;
        if (updates.bio !== undefined) user.bio = updates.bio;
        if (updates.faculty !== undefined) user.faculty = updates.faculty;
        if (updates.year_of_study !== undefined) user.year_of_study = updates.year_of_study;
        if (updates.privacy_setting !== undefined) user.privacy_setting = updates.privacy_setting;

        await user.save();

        res.json({
            message: 'Profile updated',
            user: {
                id: user.id,
                email: user.email,
                full_name: user.full_name,
                profile_picture: user.profile_image_url,
                phone: user.phone_number,
                bio: user.bio,
                faculty: user.faculty,
                year_of_study: user.year_of_study,
                privacy_setting: user.privacy_setting,
                role: user.role
            }
        });

    } catch (error) {
        console.error('Update Profile Error:', error);
        res.status(500).json({ error: 'Update failed' });
    }
};

export const getUserProfile = async (req, res) => {
    try {
        const { id } = req.params;
        const requesterId = req.user.id;
        const requesterRole = req.user.role;

        const user = await User.findByPk(id, {
            attributes: [
                'id', 'email', 'full_name', 'profile_image_url', 'phone_number', 
                'role', 'total_carbon_saved', 'carbon_saved_buyer', 'carbon_saved_seller', 
                'items_reused', 'reputation_score', 'total_reviews', 'privacy_setting', 
                'bio', 'faculty', 'year_of_study', 'createdAt', 'is_active'
            ]
        });
        
        if (!user || (user.is_active === false && requesterRole !== 'admin' && requesterRole !== 'moderator')) {
            return res.status(404).json({ error: 'User not found or account is deactivated' });
        }

        // Privacy Redaction Logic (UC02, UC04)
        // Redact contact info if setting is Private or Friends Only, UNLESS requester is the owner or an admin
        const isOwner = requesterId === user.id;
        const isAdminOrMod = requesterRole === 'admin' || requesterRole === 'moderator';
        
        if (!isOwner && !isAdminOrMod && user.privacy_setting !== 'Public') {
            user.email = null;
            user.phone_number = null;
            user.faculty = null;
            user.year_of_study = null;
        }
        
        res.json({ user });
    } catch (error) {
        console.error('Get User Profile Error:', error);
        res.status(500).json({ error: 'Failed to fetch user profile' });
    }
};

export const deleteAccount = async (req, res) => {
    try {
        const userId = req.user.id; // From token
        const paramId = req.params.id;

        // Ensure user is deleting their own account (or check this in middleware)
        // Here we just double check logic
        if (userId !== paramId) {
            return res.status(403).json({ error: 'Cannot deactivate another user account.' });
        }

        const user = await User.findByPk(userId);
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        // UC05: Prevent Deactivation if user has active orders or disputes
        const activeOrders = await Transaction.count({
            where: {
                [Op.or]: [{ buyer_id: userId }, { seller_id: userId }],
                status: ['Pending', 'Scheduled', 'To Confirm']
            }
        });

        const activeDisputes = await Dispute.count({
            where: {
                complainant_id: userId,
                status: ['New', 'Investigating', 'Escalated']
            }
        });

        if (activeOrders > 0 || activeDisputes > 0) {
            return res.status(403).json({ error: 'Cannot deactivate: You have active orders or disputes' });
        }

        // Soft delete / Deactivate instead of hard destroy
        user.is_active = false;
        user.deactivation_reason = 'Deactivated by user';
        await user.save();

        // Cascade Updates: Suspend all active listings
        await Product.update(
            { status: 'Suspended' },
            { where: { seller_id: userId, status: 'Available' } }
        );

        res.json({ message: 'Account deactivated successfully' });
    } catch (error) {
        console.error('Deactivate Account Error:', error);
        res.status(500).json({ error: 'Deactivation failed' });
    }
};

export const changePassword = async (req, res) => {
    try {
        const { old_password, new_password } = req.body;
        const userId = req.user.id;

        if (new_password.length < 8) {
            return res.status(400).json({ error: 'New password must be at least 8 characters' });
        }

        const user = await User.findByPk(userId);
        if (!user) return res.status(404).json({ error: 'User not found' });

        const isMatch = await bcrypt.compare(old_password, user.password_hash);
        if (!isMatch) return res.status(400).json({ error: 'Incorrect old password' });

        user.password_hash = await bcrypt.hash(new_password, 10);
        await user.save();

        res.json({ message: 'Password updated successfully' });
    } catch (e) {
        console.error("Change Password Error:", e);
        res.status(500).json({ error: "Failed to change password" });
    }
};

export const forgotPassword = async (req, res) => {
    try {
        const { email } = req.body;
        // Check if user exists
        const user = await User.findOne({ where: { email } });
        if (!user) {
            // Security: Don't reveal if user exists. Fake success.
            return res.json({ message: 'If that email exists, a reset link has been sent.' });
        }

        // In a real app: Generate Token -> Save to DB -> Send Email
        // For MVP/Demo: Just return success message, or maybe a mock token in console log
        console.log(`[MOCK EMAIL SERVICE] Password reset requested for ${email}. Token: MOCK-RESET-TOKEN-123`);

        res.json({ message: 'If that email exists, a reset link has been sent.' });
    } catch (e) {
        console.error("Forgot Password Error:", e);
        res.status(500).json({ error: "Request failed" });
    }
};

export const reportUser = async (req, res) => {
    try {
        const { id } = req.params;
        const { violation_type, description, evidence_urls } = req.body;
        const reporter_id = req.user.id;

        const targetUser = await User.findByPk(id);
        if (!targetUser) return res.status(404).json({ error: 'User not found' });

        // Intercept self-report
        if (targetUser.id === reporter_id) {
            return res.status(400).json({ error: 'You cannot report yourself' });
        }

        // UC11 Constraint: Max 3 reports per 10 mins spam limit
        const tenMinsAgo = new Date(Date.now() - 10 * 60 * 1000);
        const recentReports = await Report.count({
            where: {
                reporter_id,
                createdAt: { [Op.gte]: tenMinsAgo }
            }
        });

        if (recentReports >= 3) {
            return res.status(429).json({ error: 'You are submitting reports too quickly' });
        }

        const newReport = await Report.create({
            reporter_id,
            reported_user_id: targetUser.id,
            product_id: null,
            violation_type: violation_type || 'Other',
            description,
            evidence_urls: evidence_urls || [],
            status: 'Pending'
        });

        res.status(201).json({ message: 'User reported successfully.', report: newReport });
    } catch (error) {
        console.error('Report User Error:', error);
        res.status(500).json({ error: 'Failed to report user' });
    }
};
