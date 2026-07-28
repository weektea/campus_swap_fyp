import React, { useState, useEffect } from 'react';
import { Bell, AlertTriangle, Send, CheckCircle2, RefreshCw, Clock, ShieldCheck, XCircle, Check, X } from 'lucide-react';
import api from '../services/api';

const Broadcast = () => {
    const currentUser = JSON.parse(localStorage.getItem('user') || '{}');
    const isModerator = currentUser?.role === 'moderator';
    const isAdmin = currentUser?.role === 'admin';

    const [title, setTitle] = useState('');
    const [message, setMessage] = useState('');
    const [category, setCategory] = useState('ANNOUNCEMENT');
    const [loading, setLoading] = useState(false);
    const [result, setResult] = useState(null);
    const [error, setError] = useState(null);

    // Requests queue
    const [requests, setRequests] = useState([]);
    const [loadingRequests, setLoadingRequests] = useState(false);
    const [actionLoadingId, setActionLoadingId] = useState(null);

    const fetchRequests = async () => {
        setLoadingRequests(true);
        try {
            const res = await api.get('/admin/notifications/broadcast/requests');
            setRequests(res.data || []);
        } catch (err) {
            console.error('Failed to fetch broadcast requests:', err);
        } finally {
            setLoadingRequests(false);
        }
    };

    useEffect(() => {
        fetchRequests();
    }, []);

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (!title.trim() || !message.trim()) {
            setError('Please provide both a title and announcement message.');
            return;
        }

        const confirmMsg = isModerator
            ? `SUBMIT FOR ADMIN APPROVAL?\n\nAs a Moderator, your broadcast announcement will be submitted to the Administrator for approval before it can be sent to active students.\n\nTitle: "${title}"`
            : `CONFIRM BROADCAST DISPATCH\n\nAre you sure you want to send this broadcast notification to ALL active students on Campus Swap?\n\nCategory: ${category}\nTitle: "${title}"`;

        if (!window.confirm(confirmMsg)) return;

        setLoading(true);
        setError(null);
        setResult(null);

        try {
            const res = await api.post('/admin/notifications/broadcast', {
                title: title.trim(),
                message: message.trim(),
                category
            });
            setResult(res.data);
            setTitle('');
            setMessage('');
            fetchRequests(); // Refresh requests list
        } catch (err) {
            console.error('Failed to process broadcast announcement', err);
            setError(err.response?.data?.error || 'Failed to submit broadcast notification.');
        } finally {
            setLoading(false);
        }
    };

    const handleApprove = async (id, reqTitle) => {
        if (!window.confirm(`APPROVE & DISPATCH?\n\nAre you sure you want to approve and send "${reqTitle}" to ALL active students?`)) return;
        
        setActionLoadingId(id);
        try {
            const res = await api.post(`/admin/notifications/broadcast/requests/${id}/approve`);
            alert(res.data.message || 'Broadcast approved and dispatched!');
            fetchRequests();
        } catch (err) {
            alert(err.response?.data?.error || 'Failed to approve request.');
        } finally {
            setActionLoadingId(null);
        }
    };

    const handleReject = async (id) => {
        const reason = window.prompt('Please state the reason for rejection (Optional):', 'Content not suitable for general broadcast');
        if (reason === null) return; // User cancelled

        setActionLoadingId(id);
        try {
            await api.post(`/admin/notifications/broadcast/requests/${id}/reject`, { reason });
            fetchRequests();
        } catch (err) {
            alert(err.response?.data?.error || 'Failed to reject request.');
        } finally {
            setActionLoadingId(null);
        }
    };

    return (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
            <style dangerouslySetInnerHTML={{
                __html: `
                .broadcast-form-container {
                    background: var(--card-bg);
                    border: 1px solid var(--border);
                    border-radius: 16px;
                    padding: 2.5rem;
                    box-shadow: 0 1px 3px rgba(0,0,0,0.02);
                }
                .form-group {
                    display: flex;
                    flex-direction: column;
                    gap: 6px;
                    margin-bottom: 1.5rem;
                }
                .form-label {
                    font-size: 0.875rem;
                    font-weight: 700;
                    color: var(--text-main);
                }
                .form-select {
                    width: 100%;
                    padding: 0.75rem;
                    border-radius: 8px;
                    border: 1px solid var(--border);
                    background: white;
                    color: var(--text-main);
                    outline: none;
                    font-size: 0.9rem;
                    cursor: pointer;
                    height: 44px;
                }
                .form-select:focus {
                    outline: 2px solid var(--primary);
                }
                .form-textarea {
                    width: 100%;
                    padding: 0.75rem;
                    border-radius: 8px;
                    border: 1px solid var(--border);
                    background: white;
                    color: var(--text-main);
                    outline: none;
                    font-size: 0.9rem;
                    min-height: 150px;
                    resize: vertical;
                    font-family: inherit;
                    box-sizing: border-box;
                }
                .form-textarea:focus {
                    outline: 2px solid var(--primary);
                    border-color: transparent;
                }
                .banner-success {
                    background: #f0fdf4;
                    border: 1px solid #bbf7d0;
                    border-radius: 12px;
                    padding: 1.25rem;
                    display: flex;
                    align-items: flex-start;
                    gap: 12px;
                    color: #15803d;
                }
                .banner-info {
                    background: #eff6ff;
                    border: 1px solid #bfdbfe;
                    border-radius: 12px;
                    padding: 1.25rem;
                    display: flex;
                    align-items: flex-start;
                    gap: 12px;
                    color: #1d4ed8;
                }
                .banner-error {
                    background: #fef2f2;
                    border: 1px solid #fecaca;
                    border-radius: 12px;
                    padding: 1.25rem;
                    display: flex;
                    align-items: flex-start;
                    gap: 12px;
                    color: #b91c1c;
                }
                .role-policy-pill {
                    display: inline-flex;
                    align-items: center;
                    gap: 8px;
                    padding: 8px 14px;
                    border-radius: 20px;
                    font-size: 0.85rem;
                    font-weight: 600;
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
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid var(--border)', paddingBottom: '1.5rem' }}>
                <div>
                    <h1 style={{ fontSize: '1.75rem', margin: 0, fontWeight: 'bold', color: 'var(--primary)', display: 'flex', alignItems: 'center', gap: '10px' }}>
                        <Bell size={28} />
                        <span>System Broadcast Notification</span>
                    </h1>
                    <p style={{ margin: '4px 0 0 0', fontSize: '0.875rem', color: 'var(--text-muted)' }}>
                        Send platform-wide announcements, maintenance notices, or promotions to all registered student accounts.
                    </p>
                </div>

                <div>
                    {isModerator ? (
                        <div className="role-policy-pill" style={{ background: '#fef3c7', color: '#92400e', border: '1px solid #fde68a' }}>
                            <Clock size={16} />
                            <span>Moderator Mode: Requires Admin Approval</span>
                        </div>
                    ) : (
                        <div className="role-policy-pill" style={{ background: '#ecfdf5', color: '#065f46', border: '1px solid #a7f3d0' }}>
                            <ShieldCheck size={16} />
                            <span>Administrator Mode: Immediate Dispatch</span>
                        </div>
                    )}
                </div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1.4fr 1fr', gap: '2rem' }}>
                {/* Broadcast Form Card */}
                <div className="broadcast-form-container">
                    <h3 style={{ margin: '0 0 1.5rem 0', fontSize: '1.1rem', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '8px', color: 'var(--primary)' }}>
                        Compose Announcement
                    </h3>

                    {result && result.requires_approval && (
                        <div className="banner-info mb-6">
                            <Clock size={20} style={{ flexShrink: 0, marginTop: '2px' }} />
                            <div>
                                <h4 style={{ margin: '0 0 4px 0', fontWeight: 'bold' }}>Submitted for Administrator Approval</h4>
                                <p style={{ margin: 0, fontSize: '0.85rem' }}>
                                    Your announcement request has been placed in the approval queue. An Administrator will review and authorize dispatch.
                                </p>
                            </div>
                        </div>
                    )}

                    {result && !result.requires_approval && (
                        <div className="banner-success mb-6">
                            <CheckCircle2 size={20} style={{ flexShrink: 0, marginTop: '2px' }} />
                            <div>
                                <h4 style={{ margin: '0 0 4px 0', fontWeight: 'bold' }}>Broadcast Sent Successfully</h4>
                                <p style={{ margin: 0, fontSize: '0.85rem' }}>
                                    Broadcast sent to <strong>{result.total_notified}</strong> active students!
                                </p>
                            </div>
                        </div>
                    )}

                    {error && (
                        <div className="banner-error mb-6">
                            <AlertTriangle size={20} style={{ flexShrink: 0, marginTop: '2px' }} />
                            <div>
                                <h4 style={{ margin: '0 0 4px 0', fontWeight: 'bold' }}>Submission Error</h4>
                                <p style={{ margin: 0, fontSize: '0.85rem' }}>{error}</p>
                            </div>
                        </div>
                    )}

                    <form onSubmit={handleSubmit}>
                        <div className="form-group">
                            <label className="form-label">Announcement Category / Type</label>
                            <select 
                                className="form-select"
                                value={category}
                                onChange={(e) => setCategory(e.target.value)}
                            >
                                <option value="ANNOUNCEMENT">📢 General Announcement</option>
                                <option value="MAINTENANCE">🔧 System Maintenance</option>
                                <option value="PROMOTION">🎁 Promotional Campaign</option>
                            </select>
                        </div>

                        <div className="form-group">
                            <label className="form-label">Notification Title</label>
                            <input 
                                type="text"
                                className="input"
                                placeholder="Enter short, descriptive title..."
                                style={{ margin: 0 }}
                                value={title}
                                onChange={(e) => setTitle(e.target.value)}
                                maxLength={80}
                            />
                        </div>

                        <div className="form-group">
                            <label className="form-label">Announcement Content</label>
                            <textarea 
                                className="form-textarea"
                                placeholder="Write the complete announcement details here..."
                                value={message}
                                onChange={(e) => setMessage(e.target.value)}
                                maxLength={1000}
                            />
                        </div>

                        <button 
                            type="submit" 
                            className="btn flex items-center justify-center gap-2 w-full mt-4" 
                            style={{ 
                                height: '44px',
                                background: isModerator ? '#d97706' : 'var(--primary)',
                                borderColor: isModerator ? '#b45309' : 'var(--primary)'
                            }}
                            disabled={loading}
                        >
                            {loading ? (
                                <>
                                    <RefreshCw size={16} className="spin-animation" />
                                    <span>Processing...</span>
                                </>
                            ) : isModerator ? (
                                <>
                                    <Send size={16} />
                                    <span>Submit Request for Admin Approval</span>
                                </>
                            ) : (
                                <>
                                    <Send size={16} />
                                    <span>Broadcast Announcement (Immediate)</span>
                                </>
                            )}
                        </button>
                    </form>
                </div>

                {/* Guidelines Card */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                    <div className="card" style={{ background: '#f8fafc', borderColor: 'var(--border)' }}>
                        <h3 style={{ margin: '0 0 1rem 0', fontSize: '1rem', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '8px', color: 'var(--text-main)' }}>
                            <AlertTriangle size={18} color="var(--warning)" />
                            <span>Governance Guidelines</span>
                        </h3>
                        <ul style={{ margin: 0, paddingLeft: '1.25rem', fontSize: '0.85rem', color: 'var(--text-muted)', lineHeight: '1.6', display: 'flex', flexDirection: 'column', gap: '8px' }}>
                            {isModerator ? (
                                <>
                                    <li><strong>Admin Approval Required</strong>: Moderators may compose announcements, but they are held in a pending queue until approved by an Administrator.</li>
                                    <li>Ensure message content is clear, respectful, and free of typos before submitting for approval.</li>
                                    <li>The Administrator reserves the right to reject announcements that violate platform tone or policy.</li>
                                </>
                            ) : (
                                <>
                                    <li><strong>Administrator Authority</strong>: You can dispatch broadcasts immediately or review pending requests submitted by Moderators.</li>
                                    <li>Dispatched broadcasts send push notifications and database records to <strong>all active student accounts</strong>.</li>
                                    <li>All broadcasts and approval actions are audited in the Security Trail.</li>
                                </>
                            )}
                        </ul>
                    </div>
                </div>
            </div>

            {/* Broadcast Approval Queue / History Section */}
            <div className="card" style={{ padding: '2rem' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
                    <div>
                        <h2 style={{ fontSize: '1.2rem', margin: 0, fontWeight: 'bold', color: 'var(--primary)' }}>
                            Broadcast Requests & Approval Queue
                        </h2>
                        <p style={{ margin: '4px 0 0 0', fontSize: '0.85rem', color: 'var(--text-muted)' }}>
                            {isAdmin 
                                ? 'Review, approve, or reject broadcast announcement requests submitted by Moderators.' 
                                : 'Track the status of your submitted broadcast requests.'}
                        </p>
                    </div>

                    <button 
                        className="btn btn-secondary flex items-center gap-2" 
                        onClick={fetchRequests} 
                        disabled={loadingRequests}
                        style={{ fontSize: '0.85rem' }}
                    >
                        <RefreshCw size={14} className={loadingRequests ? 'spin-animation' : ''} />
                        <span>Refresh Queue</span>
                    </button>
                </div>

                {requests.length === 0 ? (
                    <div style={{ textAlign: 'center', padding: '3rem 1rem', color: 'var(--text-muted)', fontSize: '0.9rem' }}>
                        No broadcast requests found in history.
                    </div>
                ) : (
                    <div style={{ overflowX: 'auto' }}>
                        <table className="data-table" style={{ width: '100%', borderCollapse: 'collapse' }}>
                            <thead>
                                <tr style={{ borderBottom: '2px solid var(--border)', textAlign: 'left', fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                                    <th style={{ padding: '12px' }}>TITLE & CATEGORY</th>
                                    <th style={{ padding: '12px' }}>SUBMITTED BY</th>
                                    <th style={{ padding: '12px' }}>DATE</th>
                                    <th style={{ padding: '12px' }}>STATUS</th>
                                    <th style={{ padding: '12px', textAlign: 'right' }}>ACTIONS / REASON</th>
                                </tr>
                            </thead>
                            <tbody>
                                {requests.map((req) => (
                                    <tr key={req.id} style={{ borderBottom: '1px solid var(--border)', fontSize: '0.875rem' }}>
                                        <td style={{ padding: '14px 12px' }}>
                                            <div style={{ fontWeight: 'bold', color: 'var(--text-main)' }}>{req.title}</div>
                                            <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: '2px' }}>
                                                {req.category}
                                            </div>
                                            <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', marginTop: '6px', fontStyle: 'italic', maxWidth: '400px' }}>
                                                "{req.message.length > 100 ? req.message.substring(0, 97) + '...' : req.message}"
                                            </div>
                                        </td>
                                        <td style={{ padding: '14px 12px' }}>
                                            <div style={{ fontWeight: '600' }}>{req.requestedBy?.full_name || 'Staff User'}</div>
                                            <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                                                @{req.requestedBy?.username} ({req.requestedBy?.role})
                                            </div>
                                        </td>
                                        <td style={{ padding: '14px 12px', color: 'var(--text-muted)', fontSize: '0.8rem' }}>
                                            {req.createdAt ? new Date(req.createdAt).toLocaleString() : 'N/A'}
                                        </td>
                                        <td style={{ padding: '14px 12px' }}>
                                            {req.status === 'Pending' && (
                                                <span style={{ background: '#fef3c7', color: '#b45309', border: '1px solid #fde68a', padding: '4px 10px', borderRadius: '12px', fontSize: '0.75rem', fontWeight: 'bold', display: 'inline-flex', alignItems: 'center', gap: '4px' }}>
                                                    <Clock size={12} /> Pending Approval
                                                </span>
                                            )}
                                            {req.status === 'Approved' && (
                                                <span style={{ background: '#dcfce7', color: '#15803d', border: '1px solid #bbf7d0', padding: '4px 10px', borderRadius: '12px', fontSize: '0.75rem', fontWeight: 'bold', display: 'inline-flex', alignItems: 'center', gap: '4px' }}>
                                                    <CheckCircle2 size={12} /> Approved & Dispatched
                                                </span>
                                            )}
                                            {req.status === 'Rejected' && (
                                                <span style={{ background: '#fee2e2', color: '#b91c1c', border: '1px solid #fecaca', padding: '4px 10px', borderRadius: '12px', fontSize: '0.75rem', fontWeight: 'bold', display: 'inline-flex', alignItems: 'center', gap: '4px' }}>
                                                    <XCircle size={12} /> Rejected
                                                </span>
                                            )}
                                        </td>
                                        <td style={{ padding: '14px 12px', textAlign: 'right' }}>
                                            {req.status === 'Pending' && isAdmin && (
                                                <div style={{ display: 'flex', gap: '8px', justifyContent: 'flex-end' }}>
                                                    <button 
                                                        className="btn btn-primary"
                                                        style={{ background: '#16a34a', borderColor: '#15803d', padding: '6px 12px', fontSize: '0.8rem', display: 'flex', alignItems: 'center', gap: '4px' }}
                                                        onClick={() => handleApprove(req.id, req.title)}
                                                        disabled={actionLoadingId === req.id}
                                                    >
                                                        <Check size={14} /> Approve & Send
                                                    </button>
                                                    <button 
                                                        className="btn btn-secondary"
                                                        style={{ background: '#ef4444', color: 'white', borderColor: '#dc2626', padding: '6px 12px', fontSize: '0.8rem', display: 'flex', alignItems: 'center', gap: '4px' }}
                                                        onClick={() => handleReject(req.id)}
                                                        disabled={actionLoadingId === req.id}
                                                    >
                                                        <X size={14} /> Reject
                                                    </button>
                                                </div>
                                            )}
                                            {req.status === 'Pending' && !isAdmin && (
                                                <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontStyle: 'italic' }}>
                                                    Awaiting Admin Review
                                                </span>
                                            )}
                                            {req.status === 'Approved' && (
                                                <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                                                    Approved by Admin {req.reviewedBy?.full_name ? `@${req.reviewedBy.username}` : ''}
                                                </div>
                                            )}
                                            {req.status === 'Rejected' && (
                                                <div style={{ fontSize: '0.75rem', color: '#b91c1c' }}>
                                                    Reason: {req.rejection_reason || 'N/A'}
                                                </div>
                                            )}
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>
        </div>
    );
};

export default Broadcast;
