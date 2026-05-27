import React from 'react';
import { Navigate } from 'react-router-dom';

const PrivateRoute = ({ children }) => {
    const token = localStorage.getItem('token');
    const user = JSON.parse(localStorage.getItem('user') || '{}');

    if (!token || !['admin', 'moderator'].includes(user.role)) {
        return <Navigate to="/login" replace />;
    }

    return children;
};

export default PrivateRoute;
