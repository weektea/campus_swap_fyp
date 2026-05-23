import React, { useState, useEffect } from 'react';
import { TrendingUp, Circle, Clock } from 'lucide-react';
import api from '../services/api';

const Dashboard = () => {
    const [metrics, setMetrics] = useState(null);
    const [tasks, setTasks] = useState([]);
    const [myLockedTasks, setMyLockedTasks] = useState(0);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchDashboardData = async () => {
            try {
                // Catch errors for each request so one failure doesn't kill the dashboard
                let metricsData = {}, ticketsData = [], reportsData = [];
                try {
                    const res = await api.get('/admin/metrics');
                    metricsData = res.data;
                } catch (e) { console.error(e); }

                try {
                    const res = await api.get('/admin/tickets');
                    ticketsData = res.data;
                } catch (e) { console.error(e); }

                try {
                    const res = await api.get('/admin/reports');
                    reportsData = res.data;
                } catch (e) { console.error(e); }
                
                setMetrics(metricsData);
                
                const user = JSON.parse(localStorage.getItem('user') || '{}');
                let lockedCount = 0;

                const combined = [
                    ...ticketsData.map(t => {
                        if (t.lockedByModeratorId === user.id) lockedCount++;
                        return {
                            id: `TKT-${t.id}`,
                            type: 'Support Ticket',
                            target: `User: ${t.student?.email || 'Unknown'}`,
                            submittedAt: t.createdAt,
                            status: t.status,
                            lockedBy: t.lockedByModeratorId,
                            raw: t
                        };
                    }),
                    ...reportsData.map(r => ({
                        id: `REP-${r.id}`,
                        type: 'Report',
                        target: r.product ? `Listing: ${r.product.title}` : 'General',
                        submittedAt: r.createdAt,
                        status: r.status,
                        lockedBy: null,
                        raw: r
                    }))
                ];

                setMyLockedTasks(lockedCount);

                combined.sort((a, b) => new Date(b.submittedAt) - new Date(a.submittedAt));
                setTasks(combined.slice(0, 5));
                
                setLoading(false);
            } catch (err) {
                console.error('Failed to fetch dashboard data:', err);
                setLoading(false);
            }
        };

        fetchDashboardData();
    }, []);

    if (loading) return <div className="p-8 text-center text-gray-500">Loading metrics...</div>;

    return (
        <div>
            {/* Stat Cards */}
            <div className="flex gap-6 mb-8">
                <div className="card flex-1">
                    <div className="flex justify-between items-center mb-4">
                        <span style={{ color: 'var(--text-muted)' }}>Total Users</span>
                        <div className="flex items-center gap-2" style={{ color: 'var(--success)', fontWeight: 'bold' }}>
                            <TrendingUp size={16} />
                        </div>
                    </div>
                    <div style={{ fontSize: '2rem', fontWeight: 300 }}>{metrics?.total_users || 0}</div>
                </div>
                
                <div className="card flex-1">
                    <div className="flex justify-between items-center mb-4">
                        <span style={{ color: 'var(--text-muted)' }}>Active Disputes</span>
                    </div>
                    <div style={{ fontSize: '2rem', fontWeight: 300, color: 'var(--danger)' }}>{metrics?.active_disputes || 0}</div>
                </div>

                <div className="card flex-1">
                    <div className="flex justify-between items-center mb-4">
                        <span style={{ color: 'var(--text-muted)' }}>My Locked Tasks</span>
                        <Circle size={12} fill="var(--success)" color="var(--success)" />
                    </div>
                    <div style={{ fontSize: '2rem', fontWeight: 300 }}>{myLockedTasks}</div>
                </div>
            </div>

            {/* Recent Open Tasks Table */}
            <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
                <div style={{ padding: '1.5rem', borderBottom: '1px solid var(--border)' }}>
                    <h2 style={{ margin: 0, fontSize: '1.25rem' }}>Recent Open Tasks</h2>
                </div>
                <table>
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>TYPE</th>
                            <th>TARGET</th>
                            <th>SUBMITTED</th>
                            <th>STATUS</th>
                            <th>ACTION</th>
                        </tr>
                    </thead>
                    <tbody>
                        {tasks.map(task => (
                            <tr key={task.id}>
                                <td style={{ color: 'var(--text-muted)' }}>{task.id}</td>
                                <td style={{ color: 'var(--text-muted)' }}>{task.type}</td>
                                <td style={{ color: 'var(--text-muted)' }}>{task.target}</td>
                                <td style={{ color: 'var(--text-muted)' }}>{new Date(task.submittedAt).toLocaleDateString()}</td>
                                <td>
                                    <span style={{ 
                                        padding: '4px 12px', 
                                        background: task.lockedBy ? '#eff6ff' : '#f3f4f6', 
                                        borderRadius: '12px', 
                                        color: task.lockedBy ? '#1d4ed8' : 'var(--text-muted)', 
                                        fontSize: '0.75rem', 
                                        fontWeight: 'bold' 
                                    }}>
                                        {task.lockedBy ? `Locked` : task.status}
                                    </span>
                                </td>
                                <td>
                                    <button className="btn" style={{ padding: '8px 16px', fontSize: '0.875rem' }}>View</button>
                                </td>
                            </tr>
                        ))}
                        {tasks.length === 0 && (
                            <tr>
                                <td colSpan="6" style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>No recent tasks found.</td>
                            </tr>
                        )}
                    </tbody>
                </table>
            </div>
        </div>
    );
};

export default Dashboard;
