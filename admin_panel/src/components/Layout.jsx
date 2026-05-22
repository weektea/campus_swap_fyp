import React from 'react';
import { useNavigate, useLocation, Link } from 'react-router-dom';
import { 
    LayoutDashboard, 
    AlertTriangle, 
    ShieldAlert, 
    Users, 
    BarChart3, 
    DatabaseBackup, 
    Headset, 
    History,
    Search,
    Bell
} from 'lucide-react';

const Layout = ({ children }) => {
    const navigate = useNavigate();
    const location = useLocation();
    
    // In dev bypass, we might not have a full user object initially
    const userStr = localStorage.getItem('user');
    const user = userStr ? JSON.parse(userStr) : { role: 'admin' };
    
    const menuItems = [
        { path: '/dashboard', label: 'Dashboard', icon: <LayoutDashboard size={20} /> },
        { path: '/triage', label: 'Reports', icon: <AlertTriangle size={20} /> },
        { path: '/disputes', label: 'Disputes', icon: <ShieldAlert size={20} /> },
        { path: '/users', label: 'User Management', icon: <Users size={20} /> },
        { path: '/analytics', label: 'Analytics', icon: <BarChart3 size={20} /> },
        { path: '#', label: 'Backup & Restore', icon: <DatabaseBackup size={20} /> },
        { path: '#', label: 'Support Tickets', icon: <Headset size={20} /> },
        { path: '#', label: 'My History', icon: <History size={20} /> },
    ];

    const handleLogout = () => {
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        navigate('/login');
    };

    return (
        <div>
            {/* Sidebar */}
            <div className="sidebar">
                <div style={{ padding: '0 8px', marginBottom: '32px' }}>
                    <div className="flex items-center gap-4">
                        <div style={{ background: 'var(--primary)', padding: '8px', borderRadius: '8px', fontWeight: 'bold' }}>
                            CM
                        </div>
                        <div>
                            <div style={{ fontWeight: 'bold', fontSize: '1rem' }}>Campus Swap</div>
                            <div style={{ color: '#9ca3af', fontSize: '0.75rem' }}>
                                {user.role === 'admin' ? 'Administrator Portal' : 'Moderator Portal'}
                            </div>
                        </div>
                    </div>
                </div>

                <div className="flex-col">
                    {menuItems.map((item) => (
                        <Link 
                            key={item.label}
                            to={item.path} 
                            className={`nav-link ${location.pathname === item.path ? 'active' : ''}`}
                        >
                            {item.icon}
                            <span>{item.label}</span>
                        </Link>
                    ))}
                </div>
                
                <div style={{ position: 'absolute', bottom: '24px', left: '24px', right: '24px' }}>
                    <button 
                        onClick={handleLogout}
                        className="btn btn-outline" 
                        style={{ width: '100%', color: '#9ca3af', borderColor: '#374151' }}
                    >
                        Sign Out
                    </button>
                </div>
            </div>

            {/* Main Content */}
            <div className="main-content">
                <div className="topbar">
                    <div style={{ flex: 1, display: 'flex', alignItems: 'center' }}>
                        <div style={{ 
                            display: 'flex', alignItems: 'center', 
                            background: 'var(--bg-color)', 
                            border: '1px solid var(--border)',
                            borderRadius: '8px',
                            padding: '8px 16px',
                            width: '400px'
                        }}>
                            <Search size={18} color="var(--text-muted)" style={{ marginRight: '8px' }} />
                            <input 
                                type="text" 
                                placeholder="Search tickets, users, or listings..." 
                                style={{ border: 'none', background: 'transparent', outline: 'none', width: '100%' }}
                            />
                        </div>
                    </div>
                    
                    <div className="flex items-center gap-6">
                        <div style={{ position: 'relative' }}>
                            <Bell size={24} color="var(--text-muted)" />
                            <div style={{ 
                                position: 'absolute', top: 0, right: 0, 
                                width: '8px', height: '8px', 
                                background: 'var(--danger)', 
                                borderRadius: '50%' 
                            }} />
                        </div>
                        <div style={{ 
                            width: '32px', height: '32px', 
                            background: 'var(--primary)', 
                            color: 'white', 
                            borderRadius: '50%',
                            display: 'flex', alignItems: 'center', justifyContent: 'center',
                            fontWeight: 'bold', fontSize: '0.875rem'
                        }}>
                            {user.role === 'admin' ? 'AD' : 'MJ'}
                        </div>
                    </div>
                </div>

                <div className="page-container">
                    {children}
                </div>
            </div>
        </div>
    );
};

export default Layout;
