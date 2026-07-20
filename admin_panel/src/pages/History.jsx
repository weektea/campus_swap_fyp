import React, { useState, useEffect } from 'react';
import { Activity, Search, RefreshCw, ChevronLeft, ChevronRight, User, Clock } from 'lucide-react';
import api from '../services/api';

const History = () => {
    const [logs, setLogs] = useState([]);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState('');
    const [page, setPage] = useState(1);
    const [totalPages, setTotalPages] = useState(1);
    const [totalLogs, setTotalLogs] = useState(0);

    const fetchLogs = async (currentPage, searchQuery) => {
        setLoading(true);
        try {
            const res = await api.get(`/admin/logs?page=${currentPage}&limit=15&search=${searchQuery}`);
            setLogs(res.data.logs || []);
            setTotalPages(res.data.pagination.pages || 1);
            setTotalLogs(res.data.pagination.total || 0);
        } catch (e) {
            console.error('Failed to fetch activity logs', e);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchLogs(page, search);
    }, [page]);

    const handleSearchSubmit = (e) => {
        e.preventDefault();
        setPage(1);
        fetchLogs(1, search);
    };

    const handleRefresh = () => {
        fetchLogs(page, search);
    };

    const formatActionText = (action) => {
        return action.replace('ANOMALY: ', '').replace(/_/g, ' ');
    };

    const getActionBadgeStyle = (action) => {
        if (action.startsWith('ANOMALY:')) {
            return { background: '#fef2f2', color: '#dc2626', borderColor: '#fecaca' };
        }
        if (action.includes('TICKET')) {
            return { background: '#eff6ff', color: '#2563eb', borderColor: '#bfdbfe' };
        }
        if (action.startsWith('ITEM_')) {
            if (action.includes('BOUGHT') || action.includes('SOLD')) {
                return { background: '#f0fdf4', color: '#16a34a', borderColor: '#bbf7d0' };
            }
            return { background: '#faf5ff', color: '#8b5cf6', borderColor: '#e9d5ff' };
        }
        if (action === 'ACCOUNT_REACTIVATED') {
            return { background: '#fff7ed', color: '#ea580c', borderColor: '#ffedd5' };
        }
        return { background: '#f9fafb', color: '#4b5563', borderColor: '#e5e7eb' };
    };

    return (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
            {/* Custom Styles */}
            <style dangerouslySetInnerHTML={{
                __html: `
                .action-badge {
                    display: inline-block;
                    padding: 3px 10px;
                    border-radius: 6px;
                    font-size: 0.75rem;
                    font-weight: 700;
                    text-transform: uppercase;
                    border: 1px solid;
                }
                .log-table th {
                    padding: 12px 16px;
                    font-size: 0.75rem;
                    font-weight: 700;
                    text-transform: uppercase;
                    letter-spacing: 0.05em;
                }
                .log-table td {
                    padding: 14px 16px;
                    font-size: 0.85rem;
                }
                .log-table tr:hover {
                    background: #f9fafb;
                }
                .log-search-input {
                    border: 1px solid var(--border);
                    border-radius: 8px;
                    padding: 8px 12px;
                    font-size: 0.875rem;
                    outline: none;
                    width: 250px;
                    height: 38px;
                    box-sizing: border-box;
                }
                .log-search-input:focus {
                    border-color: var(--primary);
                }
                @keyframes spin {
                    from { transform: rotate(0deg); }
                    to { transform: rotate(360deg); }
                }
                .spin-animation {
                    animation: spin 1s linear infinite;
                }
            `}} />

            {/* Header Section */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem', borderBottom: '1px solid var(--border)', paddingBottom: '1.5rem' }}>
                <div>
                    <h1 style={{ fontSize: '1.75rem', margin: 0, fontWeight: 'bold', color: 'var(--primary)', display: 'flex', alignItems: 'center', gap: '10px' }}>
                        <Activity size={28} />
                        <span>Platform Audit Trails & Activity History</span>
                    </h1>
                    <p style={{ margin: '4px 0 0 0', fontSize: '0.875rem', color: 'var(--text-muted)' }}>
                        Monitor security anomalies, listing actions, transaction events, and moderator lockups.
                    </p>
                </div>

                <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                    <form onSubmit={handleSearchSubmit} style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <input
                            type="text"
                            placeholder="Search actions or logs..."
                            value={search}
                            onChange={(e) => setSearch(e.target.value)}
                            className="log-search-input"
                        />
                        <button type="submit" className="btn flex items-center justify-center" style={{ height: '38px', padding: '0 1rem' }}>
                            <Search size={16} />
                        </button>
                    </form>

                    <button className="btn btn-outline flex items-center gap-2" onClick={handleRefresh} style={{ height: '38px', padding: '0 1rem' }}>
                        <RefreshCw size={16} />
                        <span>Refresh</span>
                    </button>
                </div>
            </div>

            {/* Metrics Panel */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '1.5rem' }}>
                <div className="card">
                    <div style={{ color: 'var(--text-muted)', fontSize: '0.85rem', fontWeight: '500' }}>Total Audit Entries</div>
                    <div style={{ fontSize: '2rem', fontWeight: '800', color: 'var(--text-main)', marginTop: '4px' }}>{totalLogs}</div>
                </div>
                <div className="card">
                    <div style={{ color: 'var(--text-muted)', fontSize: '0.85rem', fontWeight: '500' }}>Current Viewing Page</div>
                    <div style={{ fontSize: '2rem', fontWeight: '800', color: 'var(--primary)', marginTop: '4px' }}>{page} / {totalPages}</div>
                </div>
            </div>

            {/* Audit Logs Table */}
            <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
                {loading ? (
                    <div style={{ padding: '4rem', textAlign: 'center', color: 'var(--text-muted)' }}>
                        <RefreshCw className="spin-animation" size={24} style={{ margin: '0 auto 1rem auto' }} />
                        <span>Loading audit logs...</span>
                    </div>
                ) : logs.length === 0 ? (
                    <div style={{ padding: '4rem', textAlign: 'center', color: 'var(--text-muted)' }}>
                        <span>No audit logs matching filters.</span>
                    </div>
                ) : (
                    <div style={{ overflowX: 'auto' }}>
                        <table className="log-table" style={{ width: '100%', borderCollapse: 'collapse' }}>
                            <thead>
                                <tr>
                                    <th>Timestamp</th>
                                    <th>User</th>
                                    <th>Email</th>
                                    <th>Action Logged</th>
                                </tr>
                            </thead>
                            <tbody>
                                {logs.map((log) => (
                                    <tr key={log.id}>
                                        <td style={{ color: 'var(--text-muted)', whiteSpace: 'nowrap' }}>
                                            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                                <Clock size={14} />
                                                <span>{new Date(log.timestamp).toLocaleString()}</span>
                                            </div>
                                        </td>
                                        <td style={{ fontWeight: '600', color: 'var(--text-main)' }}>
                                            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                                <User size={14} color="var(--text-muted)" />
                                                <span>{log.user.username}</span>
                                            </div>
                                        </td>
                                        <td style={{ color: 'var(--text-muted)' }}>{log.user.email}</td>
                                        <td>
                                            <span className="action-badge" style={getActionBadgeStyle(log.action)}>
                                                {formatActionText(log.action)}
                                            </span>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>

            {/* Pagination Panel */}
            {totalPages > 1 && (
                <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', gap: '1rem' }}>
                    <button
                        className="btn btn-outline flex items-center gap-1"
                        style={{ height: '38px', padding: '0 1rem' }}
                        disabled={page === 1}
                        onClick={() => setPage(prev => Math.max(prev - 1, 1))}
                    >
                        <ChevronLeft size={16} />
                        <span>Prev</span>
                    </button>
                    <span style={{ fontSize: '0.875rem', fontWeight: '600', color: 'var(--text-main)' }}>
                        Page {page} of {totalPages}
                    </span>
                    <button
                        className="btn btn-outline flex items-center gap-1"
                        style={{ height: '38px', padding: '0 1rem' }}
                        disabled={page === totalPages}
                        onClick={() => setPage(prev => Math.min(prev + 1, totalPages))}
                    >
                        <span>Next</span>
                        <ChevronRight size={16} />
                    </button>
                </div>
            )}
        </div>
    );
};

export default History;
