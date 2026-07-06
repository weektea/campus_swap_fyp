import React from 'react';
import { Navigate } from 'react-router-dom';

const PrivateRoute = ({ children }) => {
    const token = localStorage.getItem('token');
    let user = {};
    try {
        user = JSON.parse(localStorage.getItem('user') || '{}');
    } catch (e) {
        console.error('PrivateRoute: Failed to parse user JSON', e);
    }

    if (!token || !['admin', 'moderator'].includes(user.role)) {
        return <Navigate to="/login" replace />;
    }

    return children;
};

export default PrivateRoute;
