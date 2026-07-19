import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { User, Transaction, Dispute, Report, Product, ActivityLog, SupportTicket, Follow } from '../models/index.js';
import { Op } from 'sequelize';
import { emitToAdmins, emitToStrictlyAdmins } from '../config/socket.js';
import { sendMail } from '../utils/mailer.js';

export const validateUsernameFormat = (username) => {
    if (!username) {
        return { valid: false, error: 'Username is required' };
    }
    const normalized = username.toLowerCase().trim();
    if (normalized.length < 3 || normalized.length > 30) {
        return { valid: false, error: 'Username must be between 3 and 30 characters' };
    }
    const usernameRegex = /^[a-zA-Z0-9_]+$/;
    if (!usernameRegex.test(normalized)) {
        return { valid: false, error: 'Username can only contain letters, numbers, and underscores' };
    }
    const reserved = ['admin', 'system', 'moderator', 'support', 'root', 'campus_swap'];
    if (reserved.includes(normalized)) {
        return { valid: false, error: 'This username is reserved' };
    }
    return { valid: true, normalized };
};

export const register = async (req, res) => {
    try {
        const { email, password, university_id, phone_number, username, full_name } = req.body;

        // 1. Validation
        if (!email || !password || !university_id || !username || !full_name) {
            return res.status(400).json({ error: 'All fields are required' });
        }

        // Full Name Validation
        const cleanedFullName = full_name.trim();
        if (cleanedFullName.length < 2 || cleanedFullName.length > 50) {
            return res.status(400).json({ error: 'Full name must be between 2 and 50 characters' });
        }
        const fullNameRegex = /^[a-zA-Z\s.]+$/;
        if (!fullNameRegex.test(cleanedFullName)) {
            return res.status(400).json({ error: 'Full name can only contain letters, spaces, and periods.' });
        }

        // Username Format check
        const usernameVal = validateUsernameFormat(username);
        if (!usernameVal.valid) {
            return res.status(400).json({ error: usernameVal.error });
        }
        const normalizedUsername = usernameVal.normalized;

        // Email Validation - Check if strictly ends with .edu.my
        if (!email.trim().toLowerCase().endsWith('.edu.my')) {
            return res.status(400).json({ error: 'Only valid campus emails (.edu.my) are allowed.' });
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

        const existingUsername = await User.findOne({ where: { username: normalizedUsername } });
        if (existingUsername) {
            return res.status(400).json({ error: 'Username already registered' });
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

        // Generate secure 6-digit OTP
        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        const otpExpiry = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes from now

        // 4. Create User
        const user = await User.create({
            email,
            username: normalizedUsername,
            full_name: cleanedFullName,
            password_hash: hashedPassword,
            university_id: university_id.toUpperCase(), // Store uniform uppercase
            phone_number,
            role: 'student',
            is_verified: true,
            is_email_verified: false,
            otp,
            otp_expiry: otpExpiry,
        });

        // 5. Generate Token
        const token = jwt.sign(
            { id: user.id, email: user.email, role: user.role },
            process.env.JWT_SECRET || 'secret_key_dev',
            { expiresIn: '30d' }
        );

        // 6. Send Verification Email via Mailtrap
        try {
            // CRUCIAL DEV HACK
            console.log(`[DEV OTP HACK] OTP for ${email} is: ${otp}`);
            await sendMail({
                to: email,
                subject: 'Email Verification OTP - Campus Swap',
                text: `Welcome to Campus Swap! Your 6-digit verification OTP code is: ${otp}. It will expire in 10 minutes.`,
                html: `
                    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
                        <h2 style="color: #00695C; text-align: center;">Verify Your Campus Email</h2>
                        <p>Thank you for registering with Campus Swap. To complete your registration, please use the following One-Time Password (OTP):</p>
                        <div style="text-align: center; margin: 30px 0;">
                            <span style="font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #00695C; padding: 10px 20px; background-color: #e0f2f1; border-radius: 4px;">${otp}</span>
                        </div>
                        <p style="color: #666; font-size: 14px;">This OTP is valid for 10 minutes. If you did not register for a Campus Swap account, please ignore this email.</p>
                        <hr style="border: none; border-top: 1px solid #eee; margin-top: 30px;">
                        <p style="text-align: center; font-size: 12px; color: #999;">&copy; 2026 Campus Swap. All rights reserved.</p>
                    </div>
                `
            });
        } catch (emailErr) {
            console.error('Nodemailer Error:', emailErr.message);
        }

        // Notify admin real-time dashboard of registration event
        emitToAdmins('admin_metrics_update', { trigger: 'user_registration' });

        res.status(201).json({
            message: 'Registration successful. Verification email sent.',
            token,
            user: {
                id: user.id,
                email: user.email,
                username: user.username,
                full_name: user.full_name,
                profile_picture: user.profile_image_url,
                role: user.role,
                is_email_verified: false
            }
        });

    } catch (error) {
        console.error('Register Error:', error);
        res.status(500).json({ error: 'Registration failed' });
    }
};

export const verifyOtp = async (req, res) => {
    try {
        const { email, otp } = req.body;

        if (!email || !otp) {
            return res.status(400).json({ error: 'Email and OTP are required' });
        }

        const user = await User.findOne({ where: { email: email.trim().toLowerCase() } });
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        if (user.otp !== otp.trim()) {
            return res.status(400).json({ error: 'Invalid OTP' });
        }

        if (new Date() > new Date(user.otp_expiry)) {
            return res.status(400).json({ error: 'OTP has expired' });
        }

        user.is_email_verified = true;
        user.is_verified = true;
        user.otp = null;
        user.otp_expiry = null;
        await user.save();

        res.status(200).json({ message: 'Email verified successfully' });
    } catch (error) {
        console.error('Verify OTP Error:', error);
        res.status(500).json({ error: 'OTP verification failed' });
    }
};

export const login = async (req, res) => {
    try {
        const { email, student_id, password } = req.body;

        const identifier = email || student_id;

        // 1. Check User by email, university_id, or username
        let user = await User.findOne({ where: { email: identifier } });
        if (!user) {
            user = await User.findOne({ where: { university_id: identifier } });
        }
        if (!user && identifier) {
            user = await User.findOne({ where: { username: identifier.toLowerCase().trim() } });
        }

        if (!user) {
            return res.status(400).json({ error: 'Invalid ID/email/username or password' });
        }

        // 2. Check Password first (as per Self-Service Reactivation requirement)
        const isMatch = await bcrypt.compare(password, user.password_hash);
        if (!isMatch) {
            return res.status(400).json({ error: 'Invalid ID/email/username or password' });
        }

        // Check if email is verified (only for student users)
        if (user.role === 'student' && user.is_email_verified === false) {
            return res.status(403).json({
                errorCode: 'EMAIL_NOT_VERIFIED',
                error: 'Please verify your email before logging in.',
                email: user.email
            });
        }

        // 3. Check status if password matches
        if (user.status === 'deactivated' || user.is_active === false) {
            if (user.status === 'deactivated' || user.deactivation_reason === 'Deactivated by user') {
                // Generate a secure short-term token for reactivation
                const reactivationToken = jwt.sign(
                    { id: user.id, email: user.email, role: user.role },
                    process.env.JWT_SECRET || 'secret_key_dev',
                    { expiresIn: '1h' }
                );
                return res.status(403).json({
                    errorCode: 'ACCOUNT_DEACTIVATED',
                    message: 'Your account is deactivated.',
                    token: reactivationToken
                });
            } else {
                // Generate a secure short-term token for submitting appeals
                const appealToken = jwt.sign(
                    { id: user.id, email: user.email, role: user.role },
                    process.env.JWT_SECRET || 'secret_key_dev',
                    { expiresIn: '1h' }
                );
                return res.status(403).json({
                    errorCode: 'ACCOUNT_SUSPENDED',
                    error: 'Account Suspended',
                    message: 'Your account is suspended. Please contact support to file an appeal.',
                    token: appealToken,
                    reason: user.deactivation_reason || 'Violation of community guidelines',
                    unban_date: user.deactivated_until
                });
            }
        }

        // 4. Generate Long-term Token
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
                username: user.username,
                full_name: user.full_name,
                profile_picture: user.profile_image_url,
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

        // IDOR Prevention: Ensure requesting user matches target user ID, or is admin
        if (String(req.user.id) !== String(id) && req.user.role !== 'admin') {
            return res.status(403).json({ error: 'Access denied. You can only update your own profile.' });
        }

        const user = await User.findByPk(id);
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        // Username and Full Name immutability check
        if (updates.username !== undefined && updates.username !== user.username) {
            return res.status(400).json({ error: 'Username cannot be modified after registration' });
        }
        if (updates.full_name !== undefined && updates.full_name !== user.full_name) {
            return res.status(400).json({ error: 'Full name cannot be modified after registration' });
        }

        // Whitelist allowed updates
        if (updates.profile_picture !== undefined) user.profile_image_url = updates.profile_picture;
        if (updates.phone_number !== undefined) user.phone_number = updates.phone_number;
        if (updates.bio !== undefined) user.bio = updates.bio;
        if (updates.year_of_study !== undefined) user.year_of_study = updates.year_of_study;
        if (updates.privacy_setting !== undefined) user.privacy_setting = updates.privacy_setting;
        if (updates.show_full_name !== undefined) user.show_full_name = updates.show_full_name;
        if (updates.show_phone_number !== undefined) user.show_phone_number = updates.show_phone_number;

        await user.save();

        res.json({
            message: 'Profile updated',
            user: {
                id: user.id,
                email: user.email,
                username: user.username,
                full_name: user.full_name,
                profile_picture: user.profile_image_url,
                phone: user.phone_number,
                bio: user.bio,
                year_of_study: user.year_of_study,
                privacy_setting: user.privacy_setting,
                show_full_name: user.show_full_name,
                show_phone_number: user.show_phone_number,
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
                'id', 'username', 'email', 'full_name', 'profile_image_url', 'phone_number',
                'role', 'total_carbon_saved', 'carbon_saved_buyer', 'carbon_saved_seller',
                'items_reused', 'reputation_score', 'total_reviews', 'privacy_setting',
                'show_full_name', 'show_phone_number',
                'bio', 'year_of_study', 'createdAt', 'is_active', 'university_id',
                'accumulated_balance_due'
            ]
        });

        if (!user || (user.is_active === false && requesterRole !== 'admin' && requesterRole !== 'moderator')) {
            return res.status(404).json({ error: 'User not found or account is deactivated' });
        }

        // Privacy Redaction Logic (UC02, UC04)
        const isOwner = requesterId === user.id;
        const isAdminOrMod = requesterRole === 'admin' || requesterRole === 'moderator';

        // Granular toggles redactions
        if (!isOwner && !isAdminOrMod) {
            if (!user.show_full_name) {
                user.setDataValue('full_name', null);
            }
            if (!user.show_phone_number) {
                user.phone_number = null;
            }
        }

        // General profile privacy redactions (except email/year which are bound to general privacy setting)
        if (!isOwner && !isAdminOrMod && user.privacy_setting !== 'Public') {
            user.email = null;
            user.year_of_study = null;
            user.setDataValue('university_id', null);
        }

        // Aggregate successful sales (completed transactions as seller)
        const completedSales = await Transaction.count({
            where: {
                seller_id: id,
                status: 'Completed'
            }
        });

        // Dynamic badges logic
        const badges = [];
        if (completedSales >= 5) {
            badges.push('Fast Seller');
        }
        if (completedSales >= 3 && (user.reputation_score || 0) >= 4.8) {
            badges.push('Highly Rated');
        }

        const followerCount = await Follow.count({ where: { following_id: id } });
        const followingCount = await Follow.count({ where: { follower_id: id } });
        const isFollowing = await Follow.findOne({
            where: { follower_id: requesterId, following_id: id }
        }) ? true : false;

        const userJSON = user.toJSON();
        userJSON.badges = badges;
        userJSON.follower_count = followerCount;
        userJSON.following_count = followingCount;
        userJSON.is_following = isFollowing;

        // Calculate mock billing due date (last day of the current month)
        const now = new Date();
        userJSON.billing_due_date = new Date(now.getFullYear(), now.getMonth() + 1, 0).toISOString().split('T')[0];

        res.json({ user: userJSON });
    } catch (error) {
        console.error('Get User Profile Error:', error);
        res.status(500).json({ error: 'Failed to fetch user profile' });
    }
};

export const checkUsername = async (req, res) => {
    try {
        const { username } = req.query;
        if (!username) {
            return res.status(400).json({ available: false, error: 'Username query parameter is required' });
        }
        const val = validateUsernameFormat(username);
        if (!val.valid) {
            return res.status(200).json({ available: false, error: val.error });
        }
        const existing = await User.findOne({ where: { username: val.normalized } });
        if (existing) {
            return res.status(200).json({ available: false, error: 'Username is already taken' });
        }
        return res.json({ available: true });
    } catch (e) {
        console.error('Check Username Error:', e);
        res.status(500).json({ error: 'Failed to verify username availability' });
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

        // Generate Token -> Save to DB -> Send Email
        const resetToken = jwt.sign(
            { id: user.id, email: user.email },
            process.env.JWT_SECRET || 'secret_key_dev',
            { expiresIn: '1h' }
        );
        const resetLink = `http://localhost:3000/api/auth/reset-password?token=${resetToken}`;

        try {
            await sendMail({
                to: email,
                subject: 'Password Reset Request - Campus Swap',
                text: `You requested to reset your password. Click the link below to reset it: ${resetLink}`,
                html: `
                    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
                        <h2 style="color: #00695C; text-align: center;">Reset Your Password</h2>
                        <p>You are receiving this email because you (or someone else) requested a password reset for your account.</p>
                        <p>Please click the button below to complete the password reset process:</p>
                        <div style="text-align: center; margin: 30px 0;">
                            <a href="${resetLink}" style="background-color: #00695C; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; font-weight: bold; display: inline-block;">Reset Password</a>
                        </div>
                        <p style="color: #666; font-size: 14px;">This link will expire in 1 hour. If you did not request this, please ignore this email.</p>
                        <hr style="border: none; border-top: 1px solid #eee; margin-top: 30px;">
                        <p style="text-align: center; font-size: 12px; color: #999;">&copy; 2026 Campus Swap. All rights reserved.</p>
                    </div>
                `
            });
        } catch (emailErr) {
            console.error('Nodemailer Error in forgotPassword:', emailErr.message);
        }

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

export const reactivateUser = async (req, res) => {
    try {
        const authHeader = req.headers['authorization'];
        const token = authHeader && authHeader.split(' ')[1];
        if (!token) {
            return res.status(401).json({ error: 'Access denied. No token provided.' });
        }

        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'secret_key_dev');
        const user = await User.findByPk(decoded.id);

        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        if (user.is_active === true) {
            return res.status(400).json({ error: 'Account is already active' });
        }

        // Suggestion 1: Check admin deactivation reason to prevent self-reactivation if admin banned
        if (user.deactivation_reason !== 'Deactivated by user') {
            return res.status(403).json({
                error: 'Your account has been suspended by an administrator. Please contact support.'
            });
        }

        // 1. Reactivate user status
        user.is_active = true;
        user.deactivation_reason = null;
        await user.save();

        // 2. Cascade Reactivation: Restore listings that were suspended during deactivation
        await Product.update(
            { status: 'Available' },
            { where: { seller_id: user.id, status: 'Suspended' } }
        );

        // Suggestion 2: Audit Logging
        await ActivityLog.create({
            user_id: user.id,
            action: 'ACCOUNT_REACTIVATED'
        });

        // 3. Issue a standard long-term login token (30d)
        const userToken = jwt.sign(
            { id: user.id, email: user.email, role: user.role },
            process.env.JWT_SECRET || 'secret_key_dev',
            { expiresIn: '30d' }
        );

        res.json({
            message: 'Account reactivated successfully',
            token: userToken,
            user: {
                id: user.id,
                email: user.email,
                username: user.username,
                full_name: user.full_name,
                role: user.role
            }
        });
    } catch (error) {
        console.error('Reactivate User Error:', error);
        res.status(500).json({ error: 'Reactivation failed' });
    }
};

export const submitSuspensionAppeal = async (req, res) => {
    try {
        const authHeader = req.headers['authorization'];
        const token = authHeader && authHeader.split(' ')[1];
        if (!token) {
            return res.status(401).json({ error: 'Access denied. No token provided.' });
        }

        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'secret_key_dev');
        const user = await User.findByPk(decoded.id);

        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        if (user.status !== 'suspended' && user.is_active === true) {
            return res.status(400).json({ error: 'Your account is not suspended' });
        }

        const { description } = req.body;
        if (!description || description.trim() === '') {
            return res.status(400).json({ error: 'Appeal description/reason is required' });
        }

        // Create support ticket as suspension appeal
        const ticket = await SupportTicket.create({
            user_id: user.id,
            category: 'Account',
            subject: 'Suspended Account Reactivation Appeal',
            description: `Suspended Account Reactivation Appeal: ${description.trim()}`,
            status: 'Open',
            type: 'SUSPENSION_APPEAL'
        });

        // Emit new ticket event to strictly admins room
        emitToStrictlyAdmins('new_ticket_submitted', ticket);

        res.status(201).json({
            message: 'Appeal submitted successfully',
            ticket
        });
    } catch (error) {
        console.error('Submit Suspension Appeal Error:', error);
        res.status(500).json({ error: 'Failed to submit appeal' });
    }
};

export const submitPublicAppeal = async (req, res) => {
    try {
        const { student_id, description } = req.body;
        if (!student_id || !description || description.trim() === '') {
            return res.status(400).json({ error: 'Student ID and appeal reason are required' });
        }

        const user = await User.findOne({ where: { university_id: student_id.trim().toUpperCase() } });
        if (!user) {
            return res.status(404).json({ error: 'User not found with this Student ID' });
        }

        if (user.status !== 'suspended' && user.is_active === true) {
            return res.status(400).json({ error: 'This account is not suspended' });
        }

        // Create support ticket
        const ticket = await SupportTicket.create({
            user_id: user.id,
            category: 'Account',
            subject: 'Suspended Account Reactivation Appeal',
            description: `Suspended Account Reactivation Appeal: [Public Appeal from ${student_id.trim().toUpperCase()}] ${description.trim()}`,
            status: 'Open',
            type: 'SUSPENSION_APPEAL'
        });

        // Emit new ticket event to strictly admins room
        emitToStrictlyAdmins('new_ticket_submitted', ticket);

        res.status(201).json({
            message: 'Appeal submitted successfully',
            ticket
        });
    } catch (error) {
        console.error('Submit Public Appeal Error:', error);
        res.status(500).json({ error: 'Failed to submit appeal' });
    }
};

export const followUser = async (req, res) => {
    try {
        const { id } = req.params;
        const followerId = req.user.id;

        if (id === followerId) {
            return res.status(400).json({ error: 'You cannot follow yourself' });
        }

        const targetUser = await User.findByPk(id);
        if (!targetUser) {
            return res.status(404).json({ error: 'User not found' });
        }

        const [follow, created] = await Follow.findOrCreate({
            where: { follower_id: followerId, following_id: id }
        });

        res.status(201).json({ success: true, follow, created });
    } catch (error) {
        console.error('Follow User Error:', error);
        res.status(500).json({ error: 'Failed to follow user' });
    }
};

export const unfollowUser = async (req, res) => {
    try {
        const { id } = req.params;
        const followerId = req.user.id;

        const result = await Follow.destroy({
            where: { follower_id: followerId, following_id: id }
        });

        res.json({ success: true, unfollowed: result > 0 });
    } catch (error) {
        console.error('Unfollow User Error:', error);
        res.status(500).json({ error: 'Failed to unfollow user' });
    }
};

export const checkFollowStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const followerId = req.user.id;

        const follow = await Follow.findOne({
            where: { follower_id: followerId, following_id: id }
        });

        res.json({ is_following: !!follow });
    } catch (error) {
        console.error('Check Follow Status Error:', error);
        res.status(500).json({ error: 'Failed to check follow status' });
    }
};

export const resendOtp = async (req, res) => {
    try {
        const { email } = req.body;
        if (!email) {
            return res.status(400).json({ error: 'Email is required' });
        }

        const user = await User.findOne({ where: { email: email.trim().toLowerCase() } });
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        if (user.is_email_verified) {
            return res.status(400).json({ error: 'Email is already verified' });
        }

        // Generate new secure 6-digit OTP
        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        const otpExpiry = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

        user.otp = otp;
        user.otp_expiry = otpExpiry;
        await user.save();

        // Send Email via Mailtrap
        try {
            console.log(`[DEV OTP RESEND HACK] New OTP for ${user.email} is: ${otp}`);
            await sendMail({
                to: user.email,
                subject: 'Resend: Email Verification OTP - Campus Swap',
                text: `Welcome to Campus Swap! Your new 6-digit verification OTP code is: ${otp}. It will expire in 10 minutes.`,
                html: `
                    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
                        <h2 style="color: #00695C; text-align: center;">Verify Your Campus Email</h2>
                        <p>You requested to resend the verification code. Please use the following One-Time Password (OTP):</p>
                        <div style="text-align: center; margin: 30px 0;">
                            <span style="font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #00695C; padding: 10px 20px; background-color: #e0f2f1; border-radius: 4px;">${otp}</span>
                        </div>
                        <p style="color: #666; font-size: 14px;">This OTP is valid for 10 minutes. If you did not request this, please ignore this email.</p>
                    </div>
                `
            });
        } catch (emailErr) {
            console.error('Nodemailer Error:', emailErr.message);
        }

        res.status(200).json({ message: 'Verification email resent successfully.' });
    } catch (error) {
        console.error('Resend OTP Error:', error);
        res.status(500).json({ error: 'Failed to resend verification email' });
    }
};
