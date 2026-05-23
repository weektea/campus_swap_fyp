import React, { useState } from 'react';
import { NavLink, useNavigate } from 'react-router-dom';
import { 
    LayoutDashboard, 
    LogOut, 
    AlertTriangle,
    Users,
    Search,
    BarChart3,
    DatabaseBackup,
    Headset,
    ShieldAlert,
    History as HistoryIcon,
    ShoppingCart,
    Tags,
    MessageSquareWarning,
    Bell
} from 'lucide-react';
import api from '../services/api';

const Layout = ({ children }) => {
    const navigate = useNavigate();
    const userStr = localStorage.getItem('user');
    const user = userStr ? JSON.parse(userStr) : null;
    const [isLoggingOut, setIsLoggingOut] = useState(false);

    const handleLogout = () => {
        setIsLoggingOut(true);
        setTimeout(() => {
            localStorage.removeItem('token');
            localStorage.removeItem('user');
            delete api.defaults.headers.common['Authorization'];
            navigate('/login');
        }, 800);
    };

    const [alerts, setAlerts] = useState({ items: [], total: 0 });
    const [isDropdownOpen, setIsDropdownOpen] = useState(false);

    React.useEffect(() => {
        if (!user) return;
        const fetchAlerts = async () => {
            try {
                const res = await api.get('/admin/alerts');
                setAlerts({ items: res.data.alerts, total: res.data.total });
            } catch (err) {
                console.error('Failed to fetch alerts', err);
            }
        };

        fetchAlerts();
        const interval = setInterval(fetchAlerts, 60000); // Check every minute
        return () => clearInterval(interval);
    }, [user]);

    // Close dropdown when clicking outside
    React.useEffect(() => {
        const handleClickOutside = (e) => {
            if (!e.target.closest('.notification-bell-container')) {
                setIsDropdownOpen(false);
            }
        };
        document.addEventListener('click', handleClickOutside);
        return () => document.removeEventListener('click', handleClickOutside);
    }, []);

    return (
        <div>
            {/* Sidebar */}
            <aside className="sidebar" style={{ display: 'flex', flexDirection: 'column', boxSizing: 'border-box' }}>
                <div style={{ padding: '0 1rem 1rem 1rem', borderBottom: '1px solid rgba(255,255,255,0.1)', display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '1rem' }}>
                    <div style={{ width: '32px', height: '32px', borderRadius: '8px', background: 'var(--primary)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        <span style={{ color: 'white', fontWeight: 'bold', fontSize: '1.25rem' }}>C</span>
                    </div>
                    <h1 style={{ fontSize: '1.25rem', fontWeight: 'bold', margin: 0, color: 'white' }}>Admin</h1>
                </div>

                <div style={{ flex: 1, overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '1.5rem', padding: '0 0.5rem' }}>
                    {/* OVERVIEW */}
                    <div>
                        <div style={{ fontSize: '0.75rem', fontWeight: 'bold', color: '#6b7280', textTransform: 'uppercase', marginBottom: '8px', paddingLeft: '1rem' }}>Overview</div>
                        <nav style={{ display: 'flex', flexDirection: 'column' }}>
                            <NavLink to="/dashboard" className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
                                <LayoutDashboard size={20} />
                                <span>Dashboard</span>
                            </NavLink>
                            <NavLink to="/analytics" className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
                                <BarChart3 size={20} />
                                <span>Analytics Data</span>
                            </NavLink>
                        </nav>
                    </div>

                    {/* CONTENT & OPERATIONS */}
                    <div>
                        <div style={{ fontSize: '0.75rem', fontWeight: 'bold', color: '#6b7280', textTransform: 'uppercase', marginBottom: '8px', paddingLeft: '1rem' }}>Content & Ops</div>
                        <nav style={{ display: 'flex', flexDirection: 'column' }}>
                            <NavLink to="/listings" className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
                                <Search size={20} />
                                <span>All Listings</span>
                            </NavLink>
                            <NavLink to="/transactions" className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
                                <ShoppingCart size={20} />
                                <span>Transactions</span>
                            </NavLink>
                            <NavLink to="/categories" className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
                                <Tags size={20} />
                                <span>Categories & Zones</span>
                            </NavLink>
                        </nav>
                    </div>

                    {/* TRUST & SAFETY */}
                    <div>
                        <div style={{ fontSize: '0.75rem', fontWeight: 'bold', color: '#6b7280', textTransform: 'uppercase', marginBottom: '8px', paddingLeft: '1rem' }}>Trust & Safety</div>
                        <nav style={{ display: 'flex', flexDirection: 'column' }}>
                            <NavLink to="/reports" className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
                                <AlertTriangle size={20} />
                                <span>Violations (Reports)</span>
                            </NavLink>
                            <NavLink to="/disputes" className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
                                <ShieldAlert size={20} />
                                <span>Trade Disputes</span>
                            </NavLink>
                            <NavLink to="/tickets" className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
                                <Headset size={20} />
                                <span>Support Tickets</span>
                            </NavLink>
                            <NavLink to="/reviews" className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
                                <MessageSquareWarning size={20} />
                                <span>User Reviews</span>
                            </NavLink>
                        </nav>
                    </div>

                    {/* SYSTEM (ADMIN ONLY) */}
                    {user?.role === 'admin' && (
                        <div>
                            <div style={{ fontSize: '0.75rem', fontWeight: 'bold', color: '#6b7280', textTransform: 'uppercase', marginBottom: '8px', paddingLeft: '1rem' }}>System</div>
                            <nav style={{ display: 'flex', flexDirection: 'column' }}>
                                <NavLink to="/users" className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
                                    <Users size={20} />
                                    <span>User Management</span>
                                </NavLink>
                                <NavLink to="/backup" className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
                                    <DatabaseBackup size={20} />
                                    <span>Backup & Restore</span>
                                </NavLink>
                                <NavLink to="/history" className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
                                    <HistoryIcon size={20} />
                                    <span>Activity Log</span>
                                </NavLink>
                            </nav>
                        </div>
                    )}
                </div>

                <div style={{ borderTop: '1px solid rgba(255,255,255,0.1)', paddingTop: '1rem', marginTop: '1rem' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px', padding: '0 1rem', marginBottom: '1rem' }}>
                        <div style={{ width: '32px', height: '32px', borderRadius: '50%', background: 'rgba(255,255,255,0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white', fontWeight: 'bold' }}>
                            {user?.full_name ? user.full_name.charAt(0).toUpperCase() : 'A'}
                        </div>
                        <div style={{ flex: 1, minWidth: 0 }}>
                            <p style={{ margin: 0, fontSize: '0.875rem', fontWeight: 'bold', color: 'white', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{user?.full_name || 'Admin'}</p>
                            <p style={{ margin: 0, fontSize: '0.75rem', color: '#9ca3af', textTransform: 'capitalize' }}>{user?.role || 'administrator'}</p>
                        </div>
                    </div>
                    <button 
                        onClick={handleLogout}
                        disabled={isLoggingOut}
                        className="btn btn-danger w-full"
                        style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px', padding: '0.5rem', background: 'transparent', border: '1px solid var(--danger)', color: 'var(--danger)' }}
                    >
                        {isLoggingOut ? (
                            <span>Logging out...</span>
                        ) : (
                            <>
                                <LogOut size={18} />
                                <span>Logout</span>
                            </>
                        )}
                    </button>
                </div>
            </aside>

            {/* Main Content */}
            <main className="main-content" style={{ display: 'flex', flexDirection: 'column' }}>
                {/* Topbar for Notifications */}
                <header style={{ 
                    height: '60px', 
                    background: 'white', 
                    borderBottom: '1px solid #e5e7eb', 
                    display: 'flex', 
                    alignItems: 'center', 
                    justifyContent: 'flex-end',
                    padding: '0 2rem'
                }}>
                    <div className="notification-bell-container" style={{ position: 'relative' }}>
                        <button 
                            style={{ 
                                background: 'transparent', 
                                border: 'none', 
                                cursor: 'pointer', 
                                position: 'relative',
                                padding: '8px',
                                borderRadius: '50%',
                                transition: 'background 0.2s'
                            }}
                            onMouseEnter={e => e.currentTarget.style.background = '#f3f4f6'}
                            onMouseLeave={e => e.currentTarget.style.background = 'transparent'}
                            onClick={() => setIsDropdownOpen(!isDropdownOpen)}
                        >
                            <Bell size={24} color="#4b5563" />
                            {alerts.total > 0 && (
                                <span style={{
                                    position: 'absolute',
                                    top: '2px',
                                    right: '2px',
                                    background: '#ef4444',
                                    color: 'white',
                                    fontSize: '0.65rem',
                                    fontWeight: 'bold',
                                    minWidth: '18px',
                                    height: '18px',
                                    borderRadius: '9px',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    border: '2px solid white'
                                }}>
                                    {alerts.total > 99 ? '99+' : alerts.total}
                                </span>
                            )}
                        </button>

                        {/* Dropdown Menu */}
                        {isDropdownOpen && (
                            <div style={{
                                position: 'absolute',
                                top: '100%',
                                right: '0',
                                marginTop: '8px',
                                width: '320px',
                                background: 'white',
                                borderRadius: '12px',
                                boxShadow: '0 10px 25px -5px rgba(0,0,0,0.1), 0 8px 10px -6px rgba(0,0,0,0.1)',
                                border: '1px solid #e5e7eb',
                                zIndex: 100,
                                overflow: 'hidden'
                            }}>
                                <div style={{ padding: '1rem', borderBottom: '1px solid #e5e7eb', background: '#f9fafb' }}>
                                    <h3 style={{ margin: 0, fontSize: '1rem', fontWeight: 'bold' }}>Actionable Alerts</h3>
                                </div>
                                <div style={{ maxHeight: '300px', overflowY: 'auto' }}>
                                    {alerts.items.length === 0 ? (
                                        <div style={{ padding: '2rem 1rem', textAlign: 'center', color: '#6b7280' }}>
                                            <Bell size={32} style={{ margin: '0 auto 8px auto', opacity: 0.2 }} />
                                            <p style={{ margin: 0 }}>You're all caught up!</p>
                                        </div>
                                    ) : (
                                        alerts.items.map((alert, i) => (
                                            <div 
                                                key={i} 
                                                onClick={() => { setIsDropdownOpen(false); navigate(alert.link); }}
                                                style={{ 
                                                    padding: '1rem', 
                                                    borderBottom: '1px solid #f3f4f6',
                                                    cursor: 'pointer',
                                                    transition: 'background 0.2s',
                                                    display: 'flex',
                                                    alignItems: 'center',
                                                    gap: '12px'
                                                }}
                                                onMouseEnter={e => e.currentTarget.style.background = '#f9fafb'}
                                                onMouseLeave={e => e.currentTarget.style.background = 'white'}
                                            >
                                                <div style={{ 
                                                    width: '8px', 
                                                    height: '8px', 
                                                    borderRadius: '50%', 
                                                    background: '#ef4444',
                                                    flexShrink: 0
                                                }}></div>
                                                <div style={{ flex: 1 }}>
                                                    <p style={{ margin: 0, fontSize: '0.875rem', fontWeight: '500', color: '#111827' }}>
                                                        {alert.message}
                                                    </p>
                                                    <span style={{ fontSize: '0.75rem', color: '#ef4444', fontWeight: 'bold' }}>Requires Action</span>
                                                </div>
                                            </div>
                                        ))
                                    )}
                                </div>
                            </div>
                        )}
                    </div>
                </header>

                <div className="page-container" style={{ flex: 1, overflowY: 'auto' }}>
                    <div style={{ animation: 'fadeIn 0.3s ease-in-out' }}>
                        {children}
                    </div>
                </div>
            </main>
        </div>
    );
};

export default Layout;
