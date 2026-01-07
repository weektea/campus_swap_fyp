import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { User } from '../models/index.js';

export const register = async (req, res) => {
    try {
        const { email, password, full_name, university_id, phone_number } = req.body;

        // 1. Validation
        if (!email || !password || !full_name) {
            return res.status(400).json({ error: 'All fields are required' });
        }
        if (!email.endsWith('.edu.my')) {
            return res.status(400).json({ error: 'Must use a valid .edu.my student email' });
        }
        if (password.length < 8) {
            return res.status(400).json({ error: 'Password must be at least 8 characters long' });
        }

        // 2. Check existing
        const existingUser = await User.findOne({ where: { email } });
        if (existingUser) {
            return res.status(400).json({ error: 'Email already registered' });
        }

        // 3. Hash Password
        const hashedPassword = await bcrypt.hash(password, 10);

        // 4. Create User
        const user = await User.create({
            email,
            password_hash: hashedPassword, // Note: Model field is password_hash
            full_name,
            university_id,
            phone_number,
            role: 'student',
            is_verified: true, // Auto-verify for MVP for now
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
        const { email, password } = req.body;

        // 1. Check User
        const user = await User.findOne({ where: { email } });
        if (!user) {
            return res.status(400).json({ error: 'Invalid email or password' });
        }

        // 2. Check Password
        const isMatch = await bcrypt.compare(password, user.password_hash);
        if (!isMatch) {
            return res.status(400).json({ error: 'Invalid email or password' });
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
        if (updates.profile_picture) user.profile_picture = updates.profile_picture;
        if (updates.full_name) user.full_name = updates.full_name;
        if (updates.phone_number) user.phone_number = updates.phone_number;
        // Add more fields if needed

        await user.save();

        res.json({
            message: 'Profile updated',
            user: {
                id: user.id,
                email: user.email,
                full_name: user.full_name,
                profile_picture: user.profile_picture,
                phone: user.phone_number,
                role: user.role
            }
        });

    } catch (error) {
        console.error('Update Profile Error:', error);
        res.status(500).json({ error: 'Update failed' });
    }
};

export const deleteAccount = async (req, res) => {
    try {
        const userId = req.user.id; // From token
        const paramId = req.params.id;

        // Ensure user is deleting their own account (or check this in middleware)
        // Here we just double check logic
        if (userId !== paramId) {
            return res.status(403).json({ error: 'Cannot delete another user account.' });
        }

        const user = await User.findByPk(userId);
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        await user.destroy();
        res.json({ message: 'Account deleted successfully' });
    } catch (error) {
        console.error('Delete Account Error:', error);
        res.status(500).json({ error: 'Delete failed' });
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
