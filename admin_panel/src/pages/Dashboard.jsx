import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { TrendingUp, Circle, Lock, Flag, Scale, HelpCircle, Users, ArrowRight, ChevronLeft, ChevronRight, Filter } from 'lucide-react';
import api from '../services/api';
import { useSocket } from '../context/SocketContext';

const Dashboard = () => {
    const navigate = useNavigate();
    const [metrics, setMetrics] = useState(null);
    const [tasks, setTasks] = useState([]);
    const [myLockedTasks, setMyLockedTasks] = useState(0);
    const [loading, setLoading] = useState(true);

    // Filters & Pagination State
    const [selectedCategoryFilter, setSelectedCategoryFilter] = useState('All');
    const [selectedStatusFilter, setSelectedStatusFilter] = useState('All');
    const [currentPage, setCurrentPage] = useState(1);
    const itemsPerPage = 10;

    const socket = useSocket();

    const fetchDashboardData = async () => {
        try {
            let metricsData = {}, ticketsData = [], reportsData = [], disputesData = [];
            
            try {
                const res = await api.get('/admin/metrics');
                metricsData = res.data;
            } catch (e) { console.error('Failed to fetch metrics', e); }

            try {
                const res = await api.get('/admin/tickets');
                ticketsData = Array.isArray(res.data) ? res.data : [];
            } catch (e) { console.error('Failed to fetch tickets', e); }

            try {
                const res = await api.get('/admin/reports');
                reportsData = Array.isArray(res.data) ? res.data : [];
            } catch (e) { console.error('Failed to fetch reports', e); }

            try {
                const res = await api.get('/admin/disputes');
                disputesData = Array.isArray(res.data) ? res.data : [];
            } catch (e) { console.error('Failed to fetch disputes', e); }
            
            setMetrics(metricsData);
            
            const user = JSON.parse(localStorage.getItem('user') || '{}');
            let lockedCount = 0;

            const combined = [
                // 1. Support & Appeal Tickets (Combined)
                ...ticketsData.map(t => {
                    if (t.lockedByModeratorId === user.id) lockedCount++;
                    const isAppeal = t.type === 'SUSPENSION_APPEAL' || (t.subject && t.subject.toLowerCase().includes('suspended'));
                    return {
                        id: `TKT-${t.id.substring(0, 8)}`,
                        rawId: t.id,
                        categoryKey: 'Support Ticket',
                        displayCategory: isAppeal ? 'Support Ticket (Appeal)' : 'Support Ticket',
                        title: t.subject || 'Support Ticket',
                        target: `User: ${t.student?.full_name || t.student?.email || 'Student User'}`,
                        submittedAt: t.createdAt,
                        status: t.status,
                        lockedBy: t.lockedByModeratorId,
                        link: '/tickets',
                        color: isAppeal ? '#ef4444' : '#3b82f6',
                        iconType: isAppeal ? 'Lock' : 'HelpCircle',
                        raw: t
                    };
                }),

                // 2. Listing Reports
                ...reportsData.map(r => ({
                    id: `REP-${r.id.substring(0, 8)}`,
                    rawId: r.id,
                    categoryKey: 'Listing Report',
                    displayCategory: 'Listing Report',
                    title: r.reason || 'Listing Violation Report',
                    target: r.product ? `Listing: ${r.product.title}` : (r.reported_user ? `User: ${r.reported_user.full_name || r.reported_user.username}` : 'Community Policy'),
                    submittedAt: r.createdAt,
                    status: r.status,
                    lockedBy: r.handler_id,
                    link: '/reports',
                    color: '#f59e0b',
                    iconType: 'Flag',
                    raw: r
                })),

                // 3. Trade Disputes
                ...disputesData.map(d => ({
                    id: `DSP-${d.id.substring(0, 8)}`,
                    rawId: d.id,
                    categoryKey: 'Trade Dispute',
                    displayCategory: 'Trade Dispute',
                    title: d.reason || 'Trade Order Dispute',
                    target: d.transaction?.product ? `Order: ${d.transaction.product.title}` : 'Trade Transaction',
                    submittedAt: d.createdAt,
                    status: d.status,
                    lockedBy: d.handler_id,
                    link: '/disputes',
                    color: '#8b5cf6',
                    iconType: 'Scale',
                    raw: d
                }))
            ];

            setMyLockedTasks(lockedCount);

            combined.sort((a, b) => new Date(b.submittedAt) - new Date(a.submittedAt));
            setTasks(combined);
            
            setLoading(false);
        } catch (err) {
            console.error('Failed to fetch dashboard data:', err);
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchDashboardData();
    }, []);

    useEffect(() => {
        if (!socket) return;

        const handleRealtimeUpdate = () => {
            console.log('Dashboard: WebSocket update event received. Refreshing metrics.');
            fetchDashboardData();
        };

        socket.on('new_dispute_raised', handleRealtimeUpdate);
        socket.on('new_ticket_submitted', handleRealtimeUpdate);

        return () => {
            socket.off('new_dispute_raised', handleRealtimeUpdate);
            socket.off('new_ticket_submitted', handleRealtimeUpdate);
        };
    }, [socket]);

    if (loading) return <div className="p-8 text-center text-gray-500">Loading dashboard overview...</div>;

    // Filter Logic (Category & Status)
    const filteredTasks = tasks.filter(t => {
        // 1. Category Filter
        let matchesCategory = true;
        if (selectedCategoryFilter !== 'All') {
            if (selectedCategoryFilter === 'Support Ticket') {
                matchesCategory = (t.categoryKey === 'Support Ticket' || t.categoryKey === 'Suspension Appeal' || t.link === '/tickets');
            } else {
                matchesCategory = (t.categoryKey === selectedCategoryFilter);
            }
        }

        // 2. Status Filter
        let matchesStatus = true;
        if (selectedStatusFilter !== 'All') {
            const taskStatus = (t.status || '').toLowerCase();
            if (selectedStatusFilter === 'Pending') {
                matchesStatus = (taskStatus === 'pending' || taskStatus === 'open' || taskStatus === 'new');
            } else if (selectedStatusFilter === 'In-Progress') {
                matchesStatus = (taskStatus === 'in-progress' || taskStatus === 'investigating' || taskStatus === 'escalated' || !!t.lockedBy);
            } else if (selectedStatusFilter === 'Resolved') {
                matchesStatus = (taskStatus === 'resolved' || taskStatus === 'closed');
            }
        }

        return matchesCategory && matchesStatus;
    });

    // Pagination Calculations
    const totalPages = Math.ceil(filteredTasks.length / itemsPerPage) || 1;
    const startIndex = (currentPage - 1) * itemsPerPage;
    const paginatedTasks = filteredTasks.slice(startIndex, startIndex + itemsPerPage);

    const handleCategoryChange = (categoryKey) => {
        setSelectedCategoryFilter(categoryKey);
        setCurrentPage(1);
    };

    const handleStatusChange = (statusVal) => {
        setSelectedStatusFilter(statusVal);
        setCurrentPage(1);
    };

    const getTaskIcon = (iconType, color) => {
        switch(iconType) {
            case 'Lock': return <Lock size={16} color={color} />;
            case 'Flag': return <Flag size={16} color={color} />;
            case 'Scale': return <Scale size={16} color={color} />;
            default: return <HelpCircle size={16} color={color} />;
        }
    };

    return (
        <div>
            <div className="flex justify-between items-center mb-6">
                <div>
                    <h1 style={{ fontSize: '1.5rem', margin: 0, fontWeight: '700' }}>Admin Dashboard Overview</h1>
                    <p style={{ margin: '4px 0 0 0', fontSize: '0.875rem', color: 'var(--text-muted)' }}>
                        Real-time tracking for Support Tickets & Appeals, Listing Violation Reports, and Trade Disputes.
                    </p>
                </div>
            </div>

            {/* Top Action Item Cards Grid */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '1.25rem', marginBottom: '2rem' }}>
                
                {/* 1. Support & Appeal Tickets */}
                <div 
                    className="card" 
                    style={{ cursor: 'pointer', borderLeft: '4px solid #3b82f6', transition: 'transform 0.2s, box-shadow 0.2s' }}
                    onClick={() => navigate('/tickets')}
                >
                    <div className="flex justify-between items-center mb-3">
                        <span style={{ fontSize: '0.85rem', fontWeight: 'bold', color: '#1d4ed8' }}>Support & Appeals</span>
                        <div style={{ padding: '6px', borderRadius: '8px', background: '#dbeafe' }}>
                            <HelpCircle size={18} color="#3b82f6" />
                        </div>
                    </div>
                    <div style={{ fontSize: '1.85rem', fontWeight: '700', color: '#111827' }}>
                        {metrics?.support_tickets_count ?? 0}
                    </div>
                    <div style={{ fontSize: '0.75rem', color: '#6b7280', marginTop: '6px', display: 'flex', itemsCenter: 'space-between' }}>
                        <span>User Tickets & Login Appeals</span>
                        <ArrowRight size={14} color="#3b82f6" />
                    </div>
                </div>

                {/* 2. Listing Violation Reports */}
                <div 
                    className="card" 
                    style={{ cursor: 'pointer', borderLeft: '4px solid #f59e0b', transition: 'transform 0.2s, box-shadow 0.2s' }}
                    onClick={() => navigate('/reports')}
                >
                    <div className="flex justify-between items-center mb-3">
                        <span style={{ fontSize: '0.85rem', fontWeight: 'bold', color: '#b45309' }}>Listing Reports</span>
                        <div style={{ padding: '6px', borderRadius: '8px', background: '#fef3c7' }}>
                            <Flag size={18} color="#f59e0b" />
                        </div>
                    </div>
                    <div style={{ fontSize: '1.85rem', fontWeight: '700', color: '#111827' }}>
                        {metrics?.listing_reports_count ?? 0}
                    </div>
                    <div style={{ fontSize: '0.75rem', color: '#6b7280', marginTop: '6px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                        <span>Policy Violations</span>
                        <ArrowRight size={14} color="#f59e0b" />
                    </div>
                </div>

                {/* 3. Trade Disputes */}
                <div 
                    className="card" 
                    style={{ cursor: 'pointer', borderLeft: '4px solid #8b5cf6', transition: 'transform 0.2s, box-shadow 0.2s' }}
                    onClick={() => navigate('/disputes')}
                >
                    <div className="flex justify-between items-center mb-3">
                        <span style={{ fontSize: '0.85rem', fontWeight: 'bold', color: '#6d28d9' }}>Trade Disputes</span>
                        <div style={{ padding: '6px', borderRadius: '8px', background: '#f3e8ff' }}>
                            <Scale size={18} color="#8b5cf6" />
                        </div>
                    </div>
                    <div style={{ fontSize: '1.85rem', fontWeight: '700', color: '#111827' }}>
                        {metrics?.trade_disputes_count ?? metrics?.active_disputes ?? 0}
                    </div>
                    <div style={{ fontSize: '0.75rem', color: '#6b7280', marginTop: '6px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                        <span>Buyer & Seller Conflicts</span>
                        <ArrowRight size={14} color="#8b5cf6" />
                    </div>
                </div>

                {/* 4. Total Users Metric */}
                <div className="card">
                    <div className="flex justify-between items-center mb-3">
                        <span style={{ fontSize: '0.85rem', fontWeight: 'bold', color: '#4b5563' }}>Total Users</span>
                        <div className="flex items-center gap-1" style={{ color: 'var(--success)', fontWeight: 'bold' }}>
                            <TrendingUp size={16} />
                        </div>
                    </div>
                    <div style={{ fontSize: '1.85rem', fontWeight: '700', color: '#111827' }}>
                        {metrics?.total_users || 0}
                    </div>
                    <div style={{ fontSize: '0.75rem', color: '#6b7280', marginTop: '6px' }}>
                        {metrics?.new_registrations || 0} registered in 30 days
                    </div>
                </div>

                {/* 5. My Locked Tasks */}
                <div className="card">
                    <div className="flex justify-between items-center mb-3">
                        <span style={{ fontSize: '0.85rem', fontWeight: 'bold', color: '#4b5563' }}>My Locked Tasks</span>
                        <Circle size={10} fill="var(--success)" color="var(--success)" />
                    </div>
                    <div style={{ fontSize: '1.85rem', fontWeight: '700', color: '#111827' }}>
                        {myLockedTasks}
                    </div>
                    <div style={{ fontSize: '0.75rem', color: '#6b7280', marginTop: '6px' }}>
                        Assigned to current session
                    </div>
                </div>

            </div>

            {/* Actionable Tasks List & Category/Status Filters */}
            <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
                <div style={{ padding: '1.25rem 1.5rem', borderBottom: '1px solid var(--border)', display: 'flex', flexWrap: 'wrap', justifyContent: 'space-between', alignItems: 'center', gap: '16px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <h2 style={{ margin: 0, fontSize: '1.15rem', fontWeight: '700' }}>Actionable Tasks Management</h2>
                        <span style={{ fontSize: '0.75rem', fontWeight: 'bold', background: '#f3f4f6', color: '#4b5563', padding: '2px 8px', borderRadius: '12px' }}>
                            Total: {filteredTasks.length}
                        </span>
                    </div>
                    
                    {/* Category & Status Filter Controls */}
                    <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap', alignItems: 'center' }}>
                        {/* Status Select Dropdown */}
                        <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                            <Filter size={14} color="#6b7280" />
                            <select
                                className="input"
                                value={selectedStatusFilter}
                                onChange={(e) => handleStatusChange(e.target.value)}
                                style={{ margin: 0, padding: '5px 10px', fontSize: '0.8rem', height: 'auto', borderRadius: '8px' }}
                            >
                                <option value="All">All Statuses</option>
                                <option value="Pending">Pending / Open</option>
                                <option value="In-Progress">In-Progress / Locked</option>
                                <option value="Resolved">Resolved / Closed</option>
                            </select>
                        </div>

                        {/* Category Filter Pills */}
                        <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' }}>
                            {[
                                { label: 'All Tasks', key: 'All' },
                                { label: '🎟️ Support Tickets', key: 'Support Ticket' },
                                { label: '🚩 Listing Reports', key: 'Listing Report' },
                                { label: '⚖️ Trade Disputes', key: 'Trade Dispute' }
                            ].map(f => (
                                <button
                                    key={f.key}
                                    onClick={() => handleCategoryChange(f.key)}
                                    style={{
                                        border: 'none',
                                        borderRadius: '20px',
                                        padding: '5px 12px',
                                        fontSize: '0.8rem',
                                        fontWeight: 'bold',
                                        cursor: 'pointer',
                                        transition: 'all 0.2s',
                                        background: selectedCategoryFilter === f.key ? 'var(--primary)' : '#f3f4f6',
                                        color: selectedCategoryFilter === f.key ? 'white' : '#4b5563'
                                    }}
                                >
                                    {f.label}
                                </button>
                            ))}
                        </div>
                    </div>
                </div>

                <table>
                    <thead>
                        <tr>
                            <th style={{ width: '50px', textAlign: 'center' }}>NO.</th>
                            <th style={{ width: '110px' }}>ID</th>
                            <th style={{ width: '200px' }}>CATEGORY</th>
                            <th>TARGET & REASON</th>
                            <th>SUBMITTED</th>
                            <th>STATUS</th>
                            <th style={{ width: '90px', textAlign: 'right' }}>ACTION</th>
                        </tr>
                    </thead>
                    <tbody>
                        {paginatedTasks.map((task, index) => (
                            <tr key={task.id}>
                                <td style={{ textAlign: 'center', fontWeight: 'bold', color: 'var(--text-muted)' }}>
                                    {startIndex + index + 1}
                                </td>
                                <td style={{ fontWeight: 'bold', color: '#4b5563', fontSize: '0.85rem' }}>{task.id}</td>
                                <td>
                                    <span style={{ 
                                        display: 'inline-flex',
                                        alignItems: 'center',
                                        gap: '6px',
                                        padding: '4px 10px', 
                                        background: `${task.color}15`, 
                                        border: `1px solid ${task.color}40`,
                                        borderRadius: '8px', 
                                        color: task.color, 
                                        fontSize: '0.75rem', 
                                        fontWeight: 'bold' 
                                    }}>
                                        {getTaskIcon(task.iconType, task.color)}
                                        {task.displayCategory || task.categoryKey}
                                    </span>
                                </td>
                                <td style={{ color: 'var(--text-main)', fontWeight: '500' }}>
                                    {task.target}
                                </td>
                                <td style={{ color: 'var(--text-muted)', fontSize: '0.85rem' }}>
                                    {new Date(task.submittedAt).toLocaleDateString(undefined, { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })}
                                </td>
                                <td>
                                    <span style={{ 
                                        padding: '4px 10px', 
                                        background: task.lockedBy ? '#eff6ff' : (task.status === 'Resolved' || task.status === 'Closed' ? '#f0fdf4' : '#f3f4f6'), 
                                        borderRadius: '12px', 
                                        color: task.lockedBy ? '#1d4ed8' : (task.status === 'Resolved' || task.status === 'Closed' ? '#166534' : 'var(--text-muted)'), 
                                        fontSize: '0.75rem', 
                                        fontWeight: 'bold' 
                                    }}>
                                        {task.lockedBy ? `Locked` : task.status}
                                    </span>
                                </td>
                                <td style={{ textAlign: 'right' }}>
                                    <button 
                                        className="btn" 
                                        style={{ padding: '6px 14px', fontSize: '0.8rem' }}
                                        onClick={() => {
                                            navigate(task.link, { state: { selectedId: task.rawId } });
                                        }}
                                    >
                                        View
                                    </button>
                                </td>
                            </tr>
                        ))}
                        {paginatedTasks.length === 0 && (
                            <tr>
                                <td colSpan="7" style={{ textAlign: 'center', padding: '3rem', color: 'var(--text-muted)' }}>
                                    No {selectedCategoryFilter !== 'All' ? selectedCategoryFilter : ''} {selectedStatusFilter !== 'All' ? selectedStatusFilter : ''} tasks found.
                                </td>
                            </tr>
                        )}
                    </tbody>
                </table>

                {/* Pagination Controls Bar */}
                <div style={{ padding: '1rem 1.5rem', borderTop: '1px solid var(--border)', display: 'flex', justifyContent: 'space-between', alignItems: 'center', background: '#f9fafb' }}>
                    <div style={{ fontSize: '0.85rem', color: '#6b7280' }}>
                        Showing <strong>{filteredTasks.length > 0 ? startIndex + 1 : 0}</strong> to <strong>{Math.min(startIndex + itemsPerPage, filteredTasks.length)}</strong> of <strong>{filteredTasks.length}</strong> tasks
                    </div>

                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <button
                            className="btn"
                            disabled={currentPage === 1}
                            onClick={() => setCurrentPage(prev => Math.max(prev - 1, 1))}
                            style={{ padding: '6px 12px', fontSize: '0.8rem', display: 'flex', alignItems: 'center', gap: '4px', opacity: currentPage === 1 ? 0.5 : 1, cursor: currentPage === 1 ? 'not-allowed' : 'pointer' }}
                        >
                            <ChevronLeft size={16} /> Previous
                        </button>

                        <span style={{ fontSize: '0.85rem', fontWeight: 'bold', color: '#374151', padding: '0 8px' }}>
                            Page {currentPage} of {totalPages}
                        </span>

                        <button
                            className="btn"
                            disabled={currentPage >= totalPages}
                            onClick={() => setCurrentPage(prev => Math.min(prev + 1, totalPages))}
                            style={{ padding: '6px 12px', fontSize: '0.8rem', display: 'flex', alignItems: 'center', gap: '4px', opacity: currentPage >= totalPages ? 0.5 : 1, cursor: currentPage >= totalPages ? 'not-allowed' : 'pointer' }}
                        >
                            Next <ChevronRight size={16} />
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Dashboard;

