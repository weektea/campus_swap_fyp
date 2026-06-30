import { Server } from 'socket.io';
import jwt from 'jsonwebtoken';

const userSockets = new Map(); // userId -> Set of socketId
let io;

export const initSocket = (httpServer) => {
    io = new Server(httpServer, {
        cors: {
            origin: "*",
            methods: ["GET", "POST"]
        }
    });

    // JWT verification handshake middleware
    io.use(async (socket, next) => {
        try {
            const token = socket.handshake.auth?.token || socket.handshake.query?.token;
            if (!token) {
                return next(new Error('Authentication error: No token provided'));
            }

            const decoded = jwt.verify(token, process.env.JWT_SECRET || 'secret_key_dev');

            // Verify active status
            const { User } = await import('../models/index.js');
            const user = await User.findByPk(decoded.id);
            if (!user || user.is_active === false) {
                return next(new Error('Authentication error: Account suspended or deactivated'));
            }

            socket.user = decoded;
            next();
        } catch (err) {
            return next(new Error('Authentication error: Invalid token'));
        }
    });

    io.on('connection', (socket) => {
        const userId = socket.user?.id;
        const role = socket.user?.role;

        if (userId) {
            const uIdStr = userId.toString();
            if (!userSockets.has(uIdStr)) {
                userSockets.set(uIdStr, new Set());
            }
            userSockets.get(uIdStr).add(socket.id);
            console.log(`Socket.io: Authenticated User ${uIdStr} connected on socket ${socket.id}`);
        }

        if (role === 'admin' || role === 'moderator') {
            socket.join('admins');
            console.log(`Socket.io: Staff user ${userId} joined admin room: ${socket.id}`);
            if (role === 'admin') {
                socket.join('strictly_admins');
                console.log(`Socket.io: Staff user ${userId} joined strictly_admins room: ${socket.id}`);
            }
        }

        socket.on('disconnect', () => {
            if (userId) {
                const uIdStr = userId.toString();
                if (userSockets.has(uIdStr)) {
                    userSockets.get(uIdStr).delete(socket.id);
                    if (userSockets.get(uIdStr).size === 0) {
                        userSockets.delete(uIdStr);
                    }
                }
            }
            console.log(`Socket.io: Socket ${socket.id} disconnected`);
        });
    });

    return io;
};

export const emitToUser = (userId, event, data) => {
    if (!io) return;
    const uIdStr = userId?.toString();
    if (uIdStr && userSockets.has(uIdStr)) {
        for (const socketId of userSockets.get(uIdStr)) {
            io.to(socketId).emit(event, data);
        }
    }
};

export const emitToAdmins = (event, data) => {
    if (!io) return;
    io.to('admins').emit(event, data);
};

export const emitToStrictlyAdmins = (event, data) => {
    if (!io) return;
    io.to('strictly_admins').emit(event, data);
};

export const getIo = () => io;
