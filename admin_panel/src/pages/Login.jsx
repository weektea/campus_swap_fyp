import React, { useState } from 'react';
import api from '../services/api';
import { useNavigate } from 'react-router-dom';
import { Lock, User } from 'lucide-react';

const Login = () => {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const navigate = useNavigate();

    const handleLogin = async (e) => {
        e.preventDefault();
        try {
            const response = await api.post('/auth/login', { email, password });

            // Store token and user info
            localStorage.setItem('token', response.data.token);
            localStorage.setItem('user', JSON.stringify(response.data.user));

            // Check if user is admin
            if (response.data.user.role !== 'admin') {
                setError('Access denied. Admin privileges required.');
                localStorage.removeItem('token');
                return;
            }

            navigate('/dashboard');
        } catch (err) {
            setError(err.response?.data?.error || 'Login failed');
        }
    };

    return (
        <div className="flex justify-center items-center" style={{ height: '100vh', background: 'radial-gradient(circle at center, #1e293b 0%, #0f172a 100%)' }}>
            <div className="card" style={{ width: '400px', backdropFilter: 'blur(10px)', background: 'rgba(30, 41, 59, 0.7)' }}>
                <h2 className="text-xl" style={{ textAlign: 'center', marginBottom: '2rem' }}>Admin Portal</h2>

                {error && (
                    <div style={{ background: 'rgba(239, 68, 68, 0.1)', color: '#ef4444', padding: '0.75rem', borderRadius: '8px', marginBottom: '1rem', fontSize: '0.875rem' }}>
                        {error}
                    </div>
                )}

                <form onSubmit={handleLogin}>
                    <div style={{ position: 'relative', marginBottom: '1rem' }}>
                        <User size={18} style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: '#94a3b8' }} />
                        <input
                            type="email"
                            className="input"
                            style={{ paddingLeft: '40px' }}
                            placeholder="Admin Email"
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            required
                        />
                    </div>

                    <div style={{ position: 'relative', marginBottom: '2rem' }}>
                        <Lock size={18} style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: '#94a3b8' }} />
                        <input
                            type="password"
                            className="input"
                            style={{ paddingLeft: '40px' }}
                            placeholder="Password"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            required
                        />
                    </div>

                    <button type="submit" className="btn" style={{ width: '100%' }}>
                        Sign In
                    </button>
                </form>
            </div>
        </div>
    );
};

export default Login;
