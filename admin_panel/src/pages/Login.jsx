import React, { useState } from 'react';
import api from '../services/api';
import { useNavigate } from 'react-router-dom';
import { Lock, User } from 'lucide-react';

const Login = () => {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const [loginRole, setLoginRole] = useState('admin'); // 'admin' or 'moderator'
    const navigate = useNavigate();

    const handleLogin = async (e) => {
        e.preventDefault();

        try {
            const response = await api.post('/auth/login', { email, password });

            // Store token and user info
            localStorage.setItem('token', response.data.token);
            localStorage.setItem('user', JSON.stringify(response.data.user));

            // Check role based on selected tab
            const userRole = response.data.user.role;
            if (loginRole === 'admin' && userRole !== 'admin') {
                setError('Access denied. Admin privileges required.');
                localStorage.removeItem('token');
                return;
            }
            if (loginRole === 'moderator' && !['admin', 'moderator'].includes(userRole)) {
                setError('Access denied. Moderator privileges required.');
                localStorage.removeItem('token');
                return;
            }

            navigate('/dashboard');
        } catch (err) {
            setError(err.response?.data?.error || 'Login failed');
        }
    };

    return (
        <div className="flex justify-center items-center dark-bg" style={{ height: '100vh' }}>
            <div className="card dark-card" style={{ width: '400px' }}>
                <h2 className="text-xl" style={{ textAlign: 'center', marginBottom: '2rem' }}>
                    {loginRole === 'admin' ? 'Admin Portal' : 'Moderator Portal'}
                </h2>

                <div style={{ display: 'flex', gap: '8px', marginBottom: '24px' }}>
                    <button 
                        type="button"
                        onClick={() => setLoginRole('admin')}
                        style={{ flex: 1, padding: '12px', borderRadius: '8px', transition: 'all 0.2s', background: loginRole === 'admin' ? '#3b82f6' : 'transparent', color: loginRole === 'admin' ? 'white' : '#94a3b8', border: loginRole === 'admin' ? '1px solid #3b82f6' : '1px solid #334155', cursor: 'pointer' }}
                    >
                        Administrator
                    </button>
                    <button 
                        type="button"
                        onClick={() => setLoginRole('moderator')}
                        style={{ flex: 1, padding: '12px', borderRadius: '8px', transition: 'all 0.2s', background: loginRole === 'moderator' ? '#10b981' : 'transparent', color: loginRole === 'moderator' ? 'white' : '#94a3b8', border: loginRole === 'moderator' ? '1px solid #10b981' : '1px solid #334155', cursor: 'pointer' }}
                    >
                        Moderator
                    </button>
                </div>

                {error && (
                    <div style={{ background: 'rgba(239, 68, 68, 0.1)', color: '#ef4444', padding: '0.75rem', borderRadius: '8px', marginBottom: '1rem', fontSize: '0.875rem' }}>
                        {error}
                    </div>
                )}

                <form onSubmit={handleLogin}>
                    <div style={{ position: 'relative', marginBottom: '1rem' }}>
                        <User size={18} style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: '#94a3b8' }} />
                        <input
                            type="text"
                            className="input dark-input"
                            style={{ paddingLeft: '40px' }}
                            placeholder={loginRole === 'admin' ? "Admin Email" : "Moderator Email"}
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            required
                        />
                    </div>

                    <div style={{ position: 'relative', marginBottom: '2rem' }}>
                        <Lock size={18} style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: '#94a3b8' }} />
                        <input
                            type="password"
                            className="input dark-input"
                            style={{ paddingLeft: '40px' }}
                            placeholder="Password"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            required
                        />
                    </div>

                    <button type="submit" className="btn" style={{ width: '100%', background: loginRole === 'admin' ? '#3b82f6' : '#10b981' }}>
                        Sign In as {loginRole === 'admin' ? 'Admin' : 'Moderator'}
                    </button>
                </form>
            </div>
        </div>
    );
};

export default Login;
