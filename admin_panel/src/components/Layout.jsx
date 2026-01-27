import React from 'react';
import { NavLink, useNavigate } from 'react-router-dom';
import { LayoutDashboard, Users, ShoppingBag, LogOut } from 'lucide-react';

const Layout = ({ children }) => {
    const navigate = useNavigate();
    const user = JSON.parse(localStorage.getItem('user') || '{}');

    const handleLogout = () => {
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        navigate('/login');
    };

    return (
        <div className="flex">
            <aside className="sidebar">
                <div style={{ padding: '0 0 2rem 0', display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                    <div style={{ width: '32px', height: '32px', background: 'linear-gradient(135deg, #3b82f6, #2563eb)', borderRadius: '8px' }}></div>
                    <h1 style={{ fontSize: '1.25rem', fontWeight: 'bold' }}>CampusSwap</h1>
                </div>

                <nav style={{ flex: 1 }}>
                    <NavLink to="/dashboard" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
                        <LayoutDashboard size={20} />
                        Dashboard
                    </NavLink>
                    <NavLink to="/users" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
                        <Users size={20} />
                        Users
                    </NavLink>
                    <NavLink to="/transactions" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
                        <ShoppingBag size={20} />
                        Transactions
                    </NavLink>
                </nav>

                <div style={{ borderTop: '1px solid var(--border)', paddingTop: '1rem', marginTop: 'auto' }}>
                    <div style={{ marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                        <div style={{ width: '32px', height: '32px', borderRadius: '50%', background: '#334155', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                            {user.email?.[0]?.toUpperCase()}
                        </div>
                        <div style={{ overflow: 'hidden' }}>
                            <div style={{ fontSize: '0.875rem', fontWeight: '500' }}>Admin</div>
                            <div style={{ fontSize: '0.75rem', color: '#94a3b8', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{user.email}</div>
                        </div>
                    </div>
                    <button onClick={handleLogout} className="nav-link" style={{ width: '100%', border: 'none', background: 'transparent', cursor: 'pointer' }}>
                        <LogOut size={20} />
                        Logout
                    </button>
                </div>
            </aside>

            <main className="main-content" style={{ width: '100%' }}>
                {children}
            </main>
        </div>
    );
};

export default Layout;
