import jwt from 'jsonwebtoken';

export const authenticateToken = async (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
        return res.status(401).json({ error: 'Access denied. No token provided.' });
    }

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'secret_key_dev');
        
        // Security check: Verify the user is still active in the database
        // This prevents users with valid JWTs from continuing to use the system if they get banned.
        const { User } = await import('../models/index.js');
        const user = await User.findByPk(decoded.id);
        if (!user || user.is_active === false) {
            return res.status(403).json({ error: 'Account suspended or deleted. Token revoked.' });
        }

        req.user = decoded;
        next();
    } catch (error) {
        return res.status(403).json({ error: 'Invalid token.' });
    }
};
