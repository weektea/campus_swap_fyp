import React, { useState } from 'react';
import { Bell, AlertTriangle, Send, CheckCircle2, RefreshCw } from 'lucide-react';
import api from '../services/api';

const Broadcast = () => {
    const [title, setTitle] = useState('');
    const [message, setMessage] = useState('');
    const [category, setCategory] = useState('ANNOUNCEMENT');
    const [loading, setLoading] = useState(false);
    const [result, setResult] = useState(null);
    const [error, setError] = useState(null);

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (!title.trim() || !message.trim()) {
            setError('Please provide both a title and announcement message.');
            return;
        }

        const confirmBroadcast = window.confirm(
            `CONFIRM BROADCAST\n\nAre you sure you want to send this broadcast notification to all active students on Campus Swap?\n\nCategory: ${category}\nTitle: "${title}"`
        );
        if (!confirmBroadcast) return;

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
            // Clear form
            setTitle('');
            setMessage('');
        } catch (err) {
            console.error('Failed to send broadcast announcement', err);
            setError(err.response?.data?.error || 'Failed to send broadcast notification.');
        } finally {
            setLoading(false);
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
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1.5fr 1fr', gap: '2rem' }}>
                {/* Broadcast Form Card */}
                <div className="broadcast-form-container">
                    <h3 style={{ margin: '0 0 1.5rem 0', fontSize: '1.1rem', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '8px', color: 'var(--primary)' }}>
                        Compose Announcement
                    </h3>

                    {result && (
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
                                <h4 style={{ margin: '0 0 4px 0', fontWeight: 'bold' }}>Failed to Send Broadcast</h4>
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
                            style={{ height: '44px' }}
                            disabled={loading}
                        >
                            {loading ? (
                                <>
                                    <RefreshCw size={16} className="spin-animation" />
                                    <span>Sending Broadcast...</span>
                                </>
                            ) : (
                                <>
                                    <Send size={16} />
                                    <span>Broadcast Announcement</span>
                                </>
                            )}
                        </button>
                    </form>
                </div>

                {/* Information Checklist Card */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                    <div className="card" style={{ background: '#f8fafc', borderColor: 'var(--border)' }}>
                        <h3 style={{ margin: '0 0 1rem 0', fontSize: '1rem', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '8px', color: 'var(--text-main)' }}>
                            <AlertTriangle size={18} color="var(--warning)" />
                            <span>Important Guidelines</span>
                        </h3>
                        <ul style={{ margin: 0, paddingLeft: '1.25rem', fontSize: '0.85rem', color: 'var(--text-muted)', lineHeight: '1.6', display: 'flex', flexDirection: 'column', gap: '8px' }}>
                            <li>This feature bulk inserts a notification record for <strong>every active student account</strong> on Campus Swap.</li>
                            <li>Please verify the content for spelling, grammar, and accuracy before dispatching, as broadcast announcements cannot be edited or unsent.</li>
                            <li>Do not send promotional campaigns using the <code>System Maintenance</code> category to preserve user notification trust.</li>
                            <li>The action is automatically recorded in the platform's security audit trail (Activity Log) for compliance tracking.</li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Broadcast;
