import jwt from 'jsonwebtoken';

/**
 * Middleware to authenticate requests using JWT.
 * Verifies that a valid token is provided in the Authorization header,
 * decodes the token, and ensures the user account is active.
 *
 * @param {import('express').Request} req - The Express request object.
 * @param {import('express').Response} res - The Express response object.
 * @param {import('express').NextFunction} next - The Express next middleware function.
 * @returns {Promise<void|Response>} - Calls next() on success, or returns an error response.
 * @throws {Error} - If database access or token validation fails.
 */
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

export const authenticateTokenOptional = async (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
        return next();
    }

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'secret_key_dev');
        const { User } = await import('../models/index.js');
        const user = await User.findByPk(decoded.id);
        if (user && user.is_active !== false) {
            req.user = decoded;
        }
        next();
    } catch (error) {
        next();
    }
};

/**
 * Utility function to send JSON formatted error responses.
 *
 * @param {import('express').Response} res - The Express response object.
 * @param {number} statusCode - The HTTP status code to return.
 * @param {string} message - The detailed error message.
 * @returns {import('express').Response} - The Express JSON response.
 */
export const sendError = (res, statusCode, message) => {
    return res.status(statusCode).json({
        status: 'error',
        message: message
    });
};

/**
 * Checks if a user has staff privileges (admin or moderator).
 *
 * @param {Object} user - The user object to evaluate.
 * @param {string} user.role - The role of the user.
 * @returns {boolean} - True if the user role is admin or moderator, False otherwise.
 */
export const isStaff = (user) => {
    return user && (user.role === 'admin' || user.role === 'moderator');
};
