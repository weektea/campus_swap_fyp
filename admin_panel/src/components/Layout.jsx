import React, { useState, useEffect } from 'react';
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
    GraduationCap,
    MessageSquareWarning,
    Bell,
    Lock,
    Flag,
    Scale,
    HelpCircle,
    BrainCircuit,
    Settings,
    Menu,
    X,
    Flame
} from 'lucide-react';

import api from '../services/api';
import { useSocket } from '../context/SocketContext';

const Layout = ({ children }) => {
    const navigate = useNavigate();
    const userStr = localStorage.getItem('user');
    const user = userStr ? JSON.parse(userStr) : null;
    const [isLoggingOut, setIsLoggingOut] = useState(false);

    // Responsive Mobile Drawer State (< 1024px)
    const [isMobile, setIsMobile] = useState(() => window.innerWidth < 1024);
    const [isMobileDrawerOpen, setIsMobileDrawerOpen] = useState(false);

    // Window Resize Handler
    useEffect(() => {
        const handleResize = () => {
            const mobile = window.innerWidth < 1024;
            setIsMobile(mobile);
            if (!mobile) {
                setIsMobileDrawerOpen(false); // Close drawer when scaling up to desktop
            }
        };
        window.addEventListener('resize', handleResize);
        return () => window.removeEventListener('resize', handleResize);
    }, []);

    // Body Scroll Lock when Mobile Drawer is Open
    useEffect(() => {
        if (isMobile && isMobileDrawerOpen) {
            document.body.style.overflow = 'hidden';
        } else {
            document.body.style.overflow = '';
        }
        return () => {
            document.body.style.overflow = '';
        };
    }, [isMobile, isMobileDrawerOpen]);

    const handleNavClick = () => {
        if (isMobile) {
            setIsMobileDrawerOpen(false);
        }
    };

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
    const socket = useSocket();

    const fetchAlerts = async () => {
        try {
            const res = await api.get('/admin/alerts');
            setAlerts({ items: res.data.alerts, total: res.data.total });
        } catch (err) {
            console.error('Failed to fetch alerts', err);
        }
    };

    useEffect(() => {
        if (!user) return;
        fetchAlerts();
        const interval = setInterval(fetchAlerts, 60000); // Check every minute
        return () => clearInterval(interval);
    }, [user]);

    useEffect(() => {
        if (!socket) return;

        const handleNewAlert = () => {
            console.log('Layout: WebSocket event received. Refreshing alerts.');
            fetchAlerts();
        };

        socket.on('new_dispute_raised', handleNewAlert);
        socket.on('new_ticket_submitted', handleNewAlert);

        return () => {
            socket.off('new_dispute_raised', handleNewAlert);
            socket.off('new_ticket_submitted', handleNewAlert);
        };
    }, [socket]);

    // Close notification dropdown when clicking outside
    useEffect(() => {
        const handleClickOutside = (e) => {
            if (!e.target.closest('.notification-bell-container')) {
                setIsDropdownOpen(false);
            }
        };
        document.addEventListener('click', handleClickOutside);
        return () => document.removeEventListener('click', handleClickOutside);
    }, []);

    // Navigation Menu Component (Fixed Full View 250px)
    const renderNavContent = () => (
        <>
            {/* Header / Brand */}
            <div style={{ 
                padding: '0 0.5rem 1rem 0.5rem', 
                borderBottom: '1px solid rgba(255,255,255,0.1)', 
                display: 'flex', 
                alignItems: 'center', 
                gap: '12px', 
                marginBottom: '1rem' 
            }}>
                <div style={{ width: '32px', height: '32px', borderRadius: '8px', background: 'var(--primary)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                    <span style={{ color: 'white', fontWeight: 'bold', fontSize: '1.25rem' }}>C</span>
                </div>
                <h1 style={{ fontSize: '1.25rem', fontWeight: 'bold', margin: 0, color: 'white', whiteSpace: 'nowrap' }}>
                    {user?.role === 'moderator' ? 'Moderator' : 'Admin'}
                </h1>
            </div>

            {/* Nav Sections with Custom Sleek Scrollbar */}
            <div className="sidebar-nav-scroll" style={{ flex: 1, overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '1.25rem', padding: '0 0.25rem' }}>
                {/* OVERVIEW */}
                <div>
                    <div style={{ fontSize: '0.75rem', fontWeight: 'bold', color: '#6b7280', textTransform: 'uppercase', marginBottom: '8px', paddingLeft: '0.75rem' }}>Overview</div>
                    <nav style={{ display: 'flex', flexDirection: 'column' }}>
                        <NavLink to="/dashboard" onClick={handleNavClick} className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
                            <LayoutDashboard size={20} style={{ flexShrink: 0 }} />
                            <span>Dashboard</span>
                        </NavLink>
                        {user?.role === 'admin' && (
                            <NavLink to="/analytics" onClick={handleNavClick} className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
                                <BarChart3 size={20} style={{ flexShrink: 0 }} />
                                <span>Analytics Data</span>
                            </NavLink>
                        )}
                    </nav>
                </div>

                {/* CONTENT & OPERATIONS */}
                <div>
                    <div style={{ fontSize: '0.75rem', fontWeight: 'bold', color: '#6b7280', textTransform: 'uppercase', marginBottom: '8px', paddingLeft: '0.75rem' }}>Content & Ops</div>
                    <nav style={{ display: 'flex', flexDirection: 'column' }}>
                        <NavLink to="/listings" onClick={handleNavClick} className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
                            <Search size={20} style={{ flexShrink: 0 }} />
                            <span>All Listings</span>
                        </NavLink>
                        <NavLink to="/popular-listings" onClick={handleNavClick} className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
                            <Flame size={20} style={{ flexShrink: 0, color: '#f97316' }} />
                            <span>Popular Listings</span>
                        </NavLink>

                        <NavLink to="/transactions" onClick={handleNavClick} className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
                            <ShoppingCart size={20} style={{ flexShrink: 0 }} />
                            <span>Transactions</span>
                        </NavLink>
                        <NavLink to="/categories" onClick={handleNavClick} className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
                            <Tags size={20} style={{ flexShrink: 0 }} />
                            <span>Categories & Zones</span>
                        </NavLink>
                        <NavLink to="/faculties" onClick={handleNavClick} className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
                            <GraduationCap size={20} style={{ flexShrink: 0 }} />
                            <span>Campus Faculties</span>
                        </NavLink>
                        <NavLink to="/broadcast" onClick={handleNavClick} className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
                            <Bell size={20} style={{ flexShrink: 0 }} />
                            <span>Broadcast Announce</span>
                        </NavLink>
                    </nav>
                </div>

                {/* TRUST & SAFETY */}
                <div>
                    <div style={{ fontSize: '0.75rem', fontWeight: 'bold', color: '#6b7280', textTransform: 'uppercase', marginBottom: '8px', paddingLeft: '0.75rem' }}>Trust & Safety</div>
                    <nav style={{ display: 'flex', flexDirection: 'column' }}>
                        <NavLink to="/reports" onClick={handleNavClick} className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
                            <AlertTriangle size={20} style={{ flexShrink: 0 }} />
                            <span>Violations (Reports)</span>
                        </NavLink>
                        <NavLink to="/disputes" onClick={handleNavClick} className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
                            <ShieldAlert size={20} style={{ flexShrink: 0 }} />
                            <span>Trade Disputes</span>
                        </NavLink>
                        <NavLink to="/tickets" onClick={handleNavClick} className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
                            <Headset size={20} style={{ flexShrink: 0 }} />
                            <span>Support Tickets</span>
                        </NavLink>
                        <NavLink to="/reviews" onClick={handleNavClick} className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
                            <MessageSquareWarning size={20} style={{ flexShrink: 0 }} />
                            <span>User Reviews</span>
                        </NavLink>
                    </nav>
                </div>

                {/* SYSTEM (ADMIN ONLY) */}
                {user?.role === 'admin' && (
                    <div>
                        <div style={{ fontSize: '0.75rem', fontWeight: 'bold', color: '#6b7280', textTransform: 'uppercase', marginBottom: '8px', paddingLeft: '0.75rem' }}>System</div>
                        <nav style={{ display: 'flex', flexDirection: 'column' }}>
                            <NavLink to="/users" onClick={handleNavClick} className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
                                <Users size={20} style={{ flexShrink: 0 }} />
                                <span>User Management</span>
                            </NavLink>
                            <NavLink to="/students" onClick={handleNavClick} className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
                                <GraduationCap size={20} style={{ flexShrink: 0, color: '#10b981' }} />
                                <span>Student Directory</span>
                            </NavLink>
                            <NavLink to="/ml-models" onClick={handleNavClick} className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
                                <BrainCircuit size={20} style={{ flexShrink: 0 }} />
                                <span>ML Models</span>
                            </NavLink>
                            <NavLink to="/backup" onClick={handleNavClick} className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
                                <DatabaseBackup size={20} style={{ flexShrink: 0 }} />
                                <span>Backup & Restore</span>
                            </NavLink>
                            <NavLink to="/history" onClick={handleNavClick} className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
                                <HistoryIcon size={20} style={{ flexShrink: 0 }} />
                                <span>Activity Log</span>
                            </NavLink>
                            <NavLink to="/system" onClick={handleNavClick} className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
                                <Settings size={20} style={{ flexShrink: 0 }} />
                                <span>System Management</span>
                            </NavLink>
                        </nav>
                    </div>
                )}
            </div>

            {/* Footer Profile & Logout */}
            <div style={{ borderTop: '1px solid rgba(255,255,255,0.1)', paddingTop: '0.75rem', marginTop: '0.5rem' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px', padding: '0 0.5rem', marginBottom: '0.75rem' }}>
                    <div style={{ width: '32px', height: '32px', borderRadius: '50%', background: 'rgba(255,255,255,0.15)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white', fontWeight: 'bold', flexShrink: 0 }}>
                        {user?.full_name ? user.full_name.charAt(0).toUpperCase() : 'A'}
                    </div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                        <p style={{ margin: 0, fontSize: '0.85rem', fontWeight: 'bold', color: 'white', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{user?.full_name || 'Admin'}</p>
                        <p style={{ margin: 0, fontSize: '0.7rem', color: '#9ca3af', textTransform: 'capitalize' }}>{user?.role || 'administrator'}</p>
                    </div>
                </div>
                <button 
                    onClick={handleLogout}
                    disabled={isLoggingOut}
                    className="btn btn-danger w-full"
                    style={{ 
                        display: 'flex', 
                        alignItems: 'center', 
                        justifyContent: 'center', 
                        gap: '8px', 
                        padding: '0.5rem', 
                        background: 'transparent', 
                        border: '1px solid var(--danger)', 
                        color: 'var(--danger)' 
                    }}
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
        </>
    );

    return (
        <div>
            {/* Desktop Fixed Full View Sidebar (250px) */}
            <aside className="sidebar">
                {renderNavContent()}
            </aside>

            {/* Mobile Drawer Backdrop Overlay (Z-Index 1040) */}
            <div 
                className={`mobile-drawer-backdrop ${isMobileDrawerOpen ? 'open' : ''}`} 
                onClick={() => setIsMobileDrawerOpen(false)}
            />

            {/* Mobile Drawer (Z-Index 1050) */}
            <aside className={`mobile-drawer ${isMobileDrawerOpen ? 'open' : ''}`}>
                <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: '0.5rem' }}>
                    <button 
                        onClick={() => setIsMobileDrawerOpen(false)}
                        style={{ background: 'transparent', border: 'none', color: '#9ca3af', cursor: 'pointer', padding: '4px' }}
                    >
                        <X size={22} />
                    </button>
                </div>
                {renderNavContent()}
            </aside>

            {/* Main Content Area */}
            <main className="main-content">
                {/* Topbar Navigation Header */}
                <header className="topbar-header">
                    <div className="header-left">
                        {/* Mobile Hamburger Toggle Button */}
                        {isMobile && (
                            <button 
                                onClick={() => setIsMobileDrawerOpen(true)}
                                style={{
                                    background: '#f3f4f6',
                                    border: 'none',
                                    borderRadius: '8px',
                                    padding: '6px 10px',
                                    cursor: 'pointer',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    color: 'var(--text-main)',
                                    flexShrink: 0
                                }}
                                title="Open Navigation Menu"
                            >
                                <Menu size={22} />
                            </button>
                        )}
                        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', minWidth: 0, overflow: 'hidden' }}>
                            <div style={{ width: '24px', height: '24px', borderRadius: '6px', background: 'var(--primary)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                                <span style={{ color: 'white', fontWeight: 'bold', fontSize: '0.85rem' }}>C</span>
                            </div>
                            <span style={{ fontWeight: 'bold', fontSize: '1rem', color: 'var(--text-main)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                                Campus Swap <span style={{ fontWeight: 'normal', color: 'var(--text-muted)', fontSize: '0.85rem' }}>Portal</span>
                            </span>
                        </div>
                    </div>

                    {/* Protected Right-Side Action Icons (flexShrink: 0) */}
                    <div className="header-actions">
                        <div className="notification-bell-container" style={{ position: 'relative', flexShrink: 0 }}>
                            <button 
                                style={{ 
                                    background: 'transparent', 
                                    border: 'none', 
                                    cursor: 'pointer', 
                                    position: 'relative',
                                    padding: '8px',
                                    borderRadius: '50%',
                                    transition: 'background 0.2s',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center'
                                }}
                                onMouseEnter={e => e.currentTarget.style.background = '#f3f4f6'}
                                onMouseLeave={e => e.currentTarget.style.background = 'transparent'}
                                onClick={() => setIsDropdownOpen(!isDropdownOpen)}
                                title="Notifications"
                            >
                                <Bell size={22} color="#4b5563" />
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

                            {/* Actionable Alerts Dropdown Menu */}
                            {isDropdownOpen && (
                                <div style={{
                                    position: 'absolute',
                                    top: '100%',
                                    right: '0',
                                    marginTop: '8px',
                                    width: '320px',
                                    maxWidth: 'calc(100vw - 2rem)',
                                    background: 'white',
                                    borderRadius: '12px',
                                    boxShadow: '0 10px 25px -5px rgba(0,0,0,0.15), 0 8px 10px -6px rgba(0,0,0,0.1)',
                                    border: '1px solid #e5e7eb',
                                    zIndex: 1000,
                                    overflow: 'hidden'
                                }}>
                                    <div style={{ padding: '1rem', borderBottom: '1px solid #e5e7eb', background: '#f9fafb' }}>
                                        <h3 style={{ margin: 0, fontSize: '1rem', fontWeight: 'bold' }}>Actionable Alerts</h3>
                                    </div>
                                    <div style={{ maxHeight: '360px', overflowY: 'auto' }}>
                                        {alerts.items.length === 0 ? (
                                            <div style={{ padding: '2rem 1rem', textAlign: 'center', color: '#6b7280' }}>
                                                <Bell size={32} style={{ margin: '0 auto 8px auto', opacity: 0.2 }} />
                                                <p style={{ margin: 0 }}>You're all caught up!</p>
                                            </div>
                                        ) : (
                                            alerts.items.map((alertItem, i) => {
                                                const color = alertItem.badgeColor || '#ef4444';
                                                const getIcon = () => {
                                                    if (alertItem.icon === 'Lock') return <Lock size={18} color={color} />;
                                                    if (alertItem.icon === 'Flag') return <Flag size={18} color={color} />;
                                                    if (alertItem.icon === 'Scale') return <Scale size={18} color={color} />;
                                                    return <HelpCircle size={18} color={color} />;
                                                };
                                                return (
                                                    <div 
                                                        key={i} 
                                                        onClick={() => { setIsDropdownOpen(false); navigate(alertItem.link); }}
                                                        style={{ 
                                                            padding: '0.85rem 1rem', 
                                                            borderBottom: '1px solid #f3f4f6',
                                                            cursor: 'pointer',
                                                            transition: 'background 0.2s',
                                                            display: 'flex',
                                                            alignItems: 'flex-start',
                                                            gap: '12px'
                                                        }}
                                                        onMouseEnter={e => e.currentTarget.style.background = '#f9fafb'}
                                                        onMouseLeave={e => e.currentTarget.style.background = 'white'}
                                                    >
                                                        <div style={{ 
                                                            width: '32px', 
                                                            height: '32px', 
                                                            borderRadius: '8px', 
                                                            background: `${color}18`,
                                                            border: `1px solid ${color}40`,
                                                            display: 'flex',
                                                            alignItems: 'center',
                                                            justifyContent: 'center',
                                                            flexShrink: 0
                                                        }}>
                                                            {getIcon()}
                                                        </div>
                                                        <div style={{ flex: 1, minWidth: 0 }}>
                                                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2px' }}>
                                                                <span style={{ fontSize: '0.75rem', fontWeight: 'bold', color: color }}>
                                                                    {alertItem.title || alertItem.type}
                                                                </span>
                                                                <span style={{ fontSize: '0.7rem', fontWeight: 'bold', background: color, color: 'white', padding: '1px 6px', borderRadius: '10px' }}>
                                                                    {alertItem.count}
                                                                </span>
                                                            </div>
                                                            <p style={{ margin: 0, fontSize: '0.825rem', color: '#374151', lineHeight: '1.3' }}>
                                                                {alertItem.message}
                                                            </p>
                                                        </div>
                                                    </div>
                                                );
                                            })
                                        )}
                                    </div>
                                </div>
                            )}
                        </div>

                        {/* User Profile Avatar Badge */}
                        <div 
                            title={`${user?.full_name || 'Admin'} (${user?.role || 'administrator'})`}
                            style={{ 
                                display: 'flex', 
                                alignItems: 'center', 
                                gap: '8px', 
                                padding: '4px 10px 4px 6px', 
                                borderRadius: '20px', 
                                background: '#f3f4f6', 
                                border: '1px solid #e5e7eb',
                                cursor: 'default',
                                flexShrink: 0 
                            }}
                        >
                            <div style={{ width: '28px', height: '28px', borderRadius: '50%', background: 'var(--primary)', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 'bold', fontSize: '0.8rem', flexShrink: 0 }}>
                                {user?.full_name ? user.full_name.charAt(0).toUpperCase() : 'A'}
                            </div>
                            <span style={{ fontSize: '0.8rem', fontWeight: '600', color: 'var(--text-main)', maxWidth: '100px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                                {user?.full_name?.split(' ')[0] || 'Admin'}
                            </span>
                        </div>
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
