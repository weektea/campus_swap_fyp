import React, { useState, useEffect } from 'react';
import { AlertTriangle } from 'lucide-react';
import api from '../services/api';

const Reports = () => {
    const [reports, setReports] = useState([]);
    const [selectedReport, setSelectedReport] = useState(null);
    const [loading, setLoading] = useState(true);
    const [modNotes, setModNotes] = useState('');
    const [action, setAction] = useState('Dismissed'); // Dismissed, Uphold, Escalated
    const [currentUser, setCurrentUser] = useState(null);

    useEffect(() => {
        const userStr = localStorage.getItem('user');
        if (userStr) setCurrentUser(JSON.parse(userStr));
        fetchReports();
    }, []);

    const fetchReports = async () => {
        setLoading(true);
        try {
            const res = await api.get('/admin/reports');
            const data = res.data.map(r => ({
                id: `REP-${r.id}`,
                realId: r.id,
                target: r.product ? `Listing: ${r.product.title}` : 'General',
                content: r.reason,
                submittedAt: r.createdAt,
                status: r.status,
                raw: r
            }));

            // Filter for actionable ones
            const actionable = data.filter(t => !['Resolved', 'Dismissed'].includes(t.status));
            actionable.sort((a, b) => new Date(b.submittedAt) - new Date(a.submittedAt));
            
            setReports(actionable);
            if (actionable.length > 0 && !selectedReport) {
                setSelectedReport(actionable[0]);
            }
        } catch (err) {
            console.error('Failed to fetch reports', err);
        } finally {
            setLoading(false);
        }
    };

    const handleSubmitAction = async () => {
        if (!selectedReport) return;
        try {
            await api.put(`/admin/reports/${selectedReport.realId}`, {
                status: action,
                admin_notes: modNotes
            });
            alert('Action applied successfully!');
            setModNotes('');
            setSelectedReport(null);
            fetchReports();
        } catch (err) {
            alert(err.response?.data?.error || 'Failed to submit action');
        }
    };

    if (loading) return <div className="p-8 text-center text-gray-500">Loading reports...</div>;

    return (
        <div className="flex gap-6 h-full" style={{ minHeight: '80vh' }}>
            {/* Sidebar List */}
            <div className="card flex flex-col gap-2" style={{ width: '300px', padding: '1rem', overflowY: 'auto' }}>
                <h3 style={{ margin: '0 0 1rem 0' }}>Pending Reports ({reports.length})</h3>
                {reports.map(report => (
                    <div 
                        key={report.id}
                        onClick={() => { setSelectedReport(report); setModNotes(''); setAction('Dismissed'); }}
                        style={{ 
                            padding: '12px', 
                            borderRadius: '8px', 
                            border: '1px solid var(--border)',
                            background: selectedReport?.id === report.id ? '#eff6ff' : 'white',
                            borderColor: selectedReport?.id === report.id ? '#bfdbfe' : 'var(--border)',
                            cursor: 'pointer',
                            display: 'flex',
                            flexDirection: 'column',
                            gap: '4px'
                        }}
                    >
                        <div className="flex justify-between items-center">
                            <span style={{ fontWeight: 'bold', fontSize: '0.875rem' }}>{report.id}</span>
                            <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>{new Date(report.submittedAt).toLocaleDateString()}</span>
                        </div>
                        <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                            {report.target}
                        </div>
                        <div>
                            <span style={{ padding: '2px 6px', background: '#f3f4f6', borderRadius: '4px', fontSize: '0.7rem', fontWeight: 'bold' }}>
                                {report.status}
                            </span>
                        </div>
                    </div>
                ))}
                {reports.length === 0 && <div style={{ color: 'var(--text-muted)', textAlign: 'center', marginTop: '2rem' }}>No open reports.</div>}
            </div>

            {/* Main Content */}
            <div className="flex-1 flex flex-col gap-6">
                {!selectedReport ? (
                    <div className="card flex items-center justify-center h-full" style={{ color: 'var(--text-muted)' }}>
                        Select a report from the left to begin triage.
                    </div>
                ) : (
                    <div className="flex gap-6 items-start">
                        {/* Details */}
                        <div className="card" style={{ flex: 3, padding: 0, overflow: 'hidden' }}>
                            <div style={{ padding: '1.5rem', borderBottom: '1px solid var(--border)' }}>
                                <h2 style={{ margin: 0, fontSize: '1.25rem' }}>Report Details</h2>
                            </div>
                            <div style={{ padding: '1.5rem' }}>
                                {selectedReport.raw.product && (
                                    <div className="flex gap-6 mb-6">
                                        <div style={{ width: '120px', height: '120px', background: '#f3f4f6', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#9ca3af', overflow: 'hidden' }}>
                                            {selectedReport.raw.product.image_urls && selectedReport.raw.product.image_urls[0] ? (
                                                <img src={`http://localhost:3000${selectedReport.raw.product.image_urls[0]}`} alt="Product" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                                            ) : (
                                                'No Image'
                                            )}
                                        </div>
                                        <div>
                                            <h3 style={{ margin: '0 0 8px 0', fontSize: '1.25rem' }}>{selectedReport.raw.product.title}</h3>
                                            <div style={{ color: 'var(--text-muted)', marginBottom: '4px' }}>Price: RM {selectedReport.raw.product.price}</div>
                                            <div style={{ color: 'var(--text-muted)', marginBottom: '4px' }}>Condition: {selectedReport.raw.product.condition}</div>
                                            <div style={{ color: 'var(--text-muted)' }}>Seller ID: {selectedReport.raw.product.seller_id}</div>
                                        </div>
                                    </div>
                                )}
                                <div className="flex gap-4 items-start mb-4 bg-gray-50 p-4 rounded-lg">
                                    <AlertTriangle color="var(--danger)" />
                                    <div>
                                        <div style={{ fontWeight: 'bold', marginBottom: '8px' }}>Reporter's Claim: </div>
                                        <div style={{ lineHeight: 1.6 }}>{selectedReport.content}</div>
                                    </div>
                                </div>
                                {selectedReport.raw.reporter && (
                                    <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginTop: '1rem' }}>
                                        Reported by: {selectedReport.raw.reporter.email}
                                    </div>
                                )}
                            </div>
                        </div>

                        {/* Action Terminal */}
                        <div className="card" style={{ flex: 2 }}>
                            <h2 style={{ margin: '0 0 1.5rem 0', fontSize: '1.25rem' }}>Moderation Terminal</h2>
                            <div style={{ marginBottom: '1.5rem' }}>
                                <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-muted)', fontSize: '0.875rem' }}>Action Type</label>
                                <select className="input" value={action} onChange={(e) => setAction(e.target.value)} style={{ marginBottom: 0, appearance: 'auto', width: '100%' }}>
                                    <option value="Dismissed">Dismiss Report</option>
                                    <option value="Uphold">Uphold & Suspend Listing</option>
                                    <option value="Escalated">Escalate to Admin</option>
                                </select>
                            </div>
                            <div style={{ marginBottom: '2rem' }}>
                                <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-muted)', fontSize: '0.875rem' }}>Internal Mod Notes</label>
                                <textarea 
                                    className="input" 
                                    rows="6" 
                                    value={modNotes}
                                    onChange={(e) => setModNotes(e.target.value)}
                                    placeholder="Document your findings..."
                                    style={{ resize: 'vertical', width: '100%' }}
                                ></textarea>
                            </div>
                            <button 
                                className="btn" 
                                onClick={handleSubmitAction}
                                style={{ width: '100%', background: action === 'Uphold' ? 'var(--danger)' : 'var(--primary)' }}
                            >
                                Submit Action
                            </button>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
};

export default Reports;
