import React, { createContext, useContext, useEffect, useState } from 'react';
import { io } from 'socket.io-client';

const SocketContext = createContext(null);

export const SocketProvider = ({ children }) => {
    const [socket, setSocket] = useState(null);
    const userStr = localStorage.getItem('user');
    const token = localStorage.getItem('token');

    useEffect(() => {
        if (!token || !userStr) {
            if (socket) {
                socket.disconnect();
                setSocket(null);
            }
            return;
        }

        const user = JSON.parse(userStr);
        console.log('SocketContext: Initializing connection for role:', user.role);

        const socketInstance = io('http://localhost:3000', {
            transports: ['websocket'],
            auth: {
                token: token
            },
            query: {
                userId: user.id || '',
                role: user.role || ''
            }
        });

        socketInstance.on('connect', () => {
            console.log('SocketContext: Connected to WebSocket server');
        });

        socketInstance.on('disconnect', () => {
            console.log('SocketContext: Disconnected from WebSocket server');
        });

        setSocket(socketInstance);

        return () => {
            console.log('SocketContext: Cleaning up connection');
            socketInstance.disconnect();
        };
    }, [token, userStr]);

    return (
        <SocketContext.Provider value={socket}>
            {children}
        </SocketContext.Provider>
    );
};

export const useSocket = () => {
    return useContext(SocketContext);
};
