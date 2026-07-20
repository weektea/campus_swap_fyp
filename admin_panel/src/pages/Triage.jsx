import React, { useState, useEffect } from 'react';
import { Lock, AlertTriangle, CheckCircle, ChevronRight } from 'lucide-react';
import api, { IMAGE_BASE_URL } from '../services/api';

const Triage = () => {
    const [tasks, setTasks] = useState([]);
    const [selectedTask, setSelectedTask] = useState(null);
    const [loading, setLoading] = useState(true);
    const [modNotes, setModNotes] = useState('');
    const [action, setAction] = useState('Dismiss'); // Dismiss, Uphold, Escalate
    const [currentUser, setCurrentUser] = useState(null);
    const [privateTranscript, setPrivateTranscript] = useState(null);
    const [loadingTranscript, setLoadingTranscript] = useState(false);
    const [showTranscriptModal, setShowTranscriptModal] = useState(false);

    const fetchPrivateTranscript = async () => {
        const reporterId = selectedTask?.raw?.reporter_id;
        const reportedUserId = selectedTask?.raw?.reported_user_id;
        if (!reporterId || !reportedUserId) {
            alert('Cannot view transcript: Report is not a direct user report or is missing reporter/reported user information.');
            return;
        }
        setLoadingTranscript(true);
        try {
            const res = await api.get(`/admin/chats/transcript/${reporterId}/${reportedUserId}`);
            setPrivateTranscript(res.data);
            setShowTranscriptModal(true);
        } catch (err) {
            alert(err.response?.data?.error || 'Access Denied: Chat safety snooping is restricted.');
        } finally {
            setLoadingTranscript(false);
        }
    };

    useEffect(() => {
        const userStr = localStorage.getItem('user');
        if (userStr) setCurrentUser(JSON.parse(userStr));
        fetchTasks();
    }, []);

    const fetchTasks = async () => {
        setLoading(true);
        try {
            const [ticketsRes, reportsRes] = await Promise.all([
                api.get('/admin/tickets'),
                api.get('/admin/reports')
            ]);
            
            const combined = [
                ...ticketsRes.data.map(t => ({
                    id: `TKT-${t.id}`,
                    realId: t.id,
                    type: 'ticket',
                    target: `User: ${t.student?.email || 'Unknown'}`,
                    content: t.issue_description,
                    submittedAt: t.createdAt,
                    status: t.status,
                    lockedBy: t.lockedByModeratorId,
                    raw: t
                })),
                ...reportsRes.data.map(r => ({
                    id: `REP-${r.id}`,
                    realId: r.id,
                    type: 'report',
                    target: r.product ? `Listing: ${r.product.title}` : 'General',
                    content: r.reason,
                    submittedAt: r.createdAt,
                    status: r.status,
                    lockedBy: null,
                    raw: r
                }))
            ];

            // Filter for only actionable ones (e.g. not Resolved)
            const actionable = combined.filter(t => !['Resolved', 'Dismissed'].includes(t.status));
            actionable.sort((a, b) => new Date(b.submittedAt) - new Date(a.submittedAt));
            
            setTasks(actionable);
            if (actionable.length > 0 && !selectedTask) {
                setSelectedTask(actionable[0]);
            }
        } catch (err) {
            console.error('Failed to fetch triage tasks', err);
        } finally {
            setLoading(false);
        }
    };

    const handleLockTicket = async () => {
        if (selectedTask?.type !== 'ticket') return;
        try {
            await api.post(`/admin/tickets/${selectedTask.realId}/lock`);
            fetchTasks(); // Refresh to show we locked it
            // Update selected task locally to prevent UI flicker
            setSelectedTask({ ...selectedTask, lockedBy: currentUser?.id, status: 'In-Progress' });
        } catch (err) {
            alert(err.response?.data?.error || 'Failed to lock ticket');
        }
    };

    const handleSubmitAction = async () => {
        if (!selectedTask) return;
        
        try {
            if (selectedTask.type === 'report') {
                await api.put(`/admin/reports/${selectedTask.realId}`, {
                    status: action, // Uphold, Dismissed, Escalated
                    admin_notes: modNotes
                });
            } else if (selectedTask.type === 'ticket') {
                await api.put(`/admin/tickets/${selectedTask.realId}`, {
                    status: action, // Resolved, Escalated
                    reply_content: modNotes
                });
            }
            alert('Action applied successfully!');
            setModNotes('');
            setSelectedTask(null);
            fetchTasks();
        } catch (err) {
            alert(err.response?.data?.error || 'Failed to submit action');
        }
    };

    if (loading) return <div className="p-8 text-center text-gray-500">Loading tasks...</div>;

    return (
        <div className="flex gap-6 h-full" style={{ minHeight: '80vh' }}>
            {/* Sidebar List */}
            <div className="card flex flex-col gap-2" style={{ width: '300px', padding: '1rem', overflowY: 'auto' }}>
                <h3 style={{ margin: '0 0 1rem 0' }}>Actionable Tasks ({tasks.length})</h3>
                {tasks.map(task => (
                    <div 
                        key={task.id}
                        onClick={() => { setSelectedTask(task); setModNotes(''); setAction(task.type === 'report' ? 'Dismiss' : 'Resolved'); }}
                        style={{ 
                            padding: '12px', 
                            borderRadius: '8px', 
                            border: '1px solid var(--border)',
                            background: selectedTask?.id === task.id ? '#eff6ff' : 'white',
                            borderColor: selectedTask?.id === task.id ? '#bfdbfe' : 'var(--border)',
                            cursor: 'pointer',
                            display: 'flex',
                            flexDirection: 'column',
                            gap: '4px'
                        }}
                    >
                        <div className="flex justify-between items-center">
                            <span style={{ fontWeight: 'bold', fontSize: '0.875rem' }}>{task.id}</span>
                            <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>{new Date(task.submittedAt).toLocaleDateString()}</span>
                        </div>
                        <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                            {task.target}
                        </div>
                        <div>
                            <span style={{ padding: '2px 6px', background: '#f3f4f6', borderRadius: '4px', fontSize: '0.7rem', fontWeight: 'bold' }}>
                                {task.status}
                            </span>
                        </div>
                    </div>
                ))}
                {tasks.length === 0 && <div style={{ color: 'var(--text-muted)', textAlign: 'center', marginTop: '2rem' }}>No open tasks.</div>}
            </div>

            {/* Main Content */}
            <div className="flex-1 flex flex-col gap-6">
                {!selectedTask ? (
                    <div className="card flex items-center justify-center h-full" style={{ color: 'var(--text-muted)' }}>
                        Select a task from the left to begin triage.
                    </div>
                ) : (
                    <>
                        {selectedTask.type === 'ticket' && selectedTask.lockedBy === currentUser?.id && (
                            <div style={{ background: '#e8f5e9', padding: '12px 32px', borderRadius: '8px', display: 'flex', alignItems: 'center', gap: '8px', color: '#2e7d32', fontWeight: 'bold' }}>
                                <Lock size={18} />
                                <span>Ticket {selectedTask.id} is currently locked by you.</span>
                            </div>
                        )}
                        {selectedTask.type === 'ticket' && selectedTask.lockedBy && selectedTask.lockedBy !== currentUser?.id && (
                            <div style={{ background: '#fef2f2', padding: '12px 32px', borderRadius: '8px', display: 'flex', alignItems: 'center', gap: '8px', color: '#dc2626', fontWeight: 'bold' }}>
                                <Lock size={18} />
                                <span>Ticket {selectedTask.id} is locked by another moderator.</span>
                            </div>
                        )}

                        <div className="flex gap-6 items-start">
                            {/* Left Column: Details */}
                            <div className="card" style={{ flex: 3, padding: 0, overflow: 'hidden' }}>
                                <div style={{ padding: '1.5rem', borderBottom: '1px solid var(--border)' }}>
                                    <h2 style={{ margin: 0, fontSize: '1.25rem' }}>{selectedTask.type === 'report' ? 'Report Details' : 'Support Ticket Details'}</h2>
                                </div>
                                
                                <div style={{ padding: '1.5rem' }}>
                                    {selectedTask.type === 'report' && selectedTask.raw.product && (
                                        <div className="flex gap-6 mb-6">
                                            <div style={{ width: '120px', height: '120px', background: '#f3f4f6', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#9ca3af', overflow: 'hidden' }}>
                                                {selectedTask.raw.product.image_urls && selectedTask.raw.product.image_urls[0] ? (
                                                    <img src={`${IMAGE_BASE_URL}${selectedTask.raw.product.image_urls[0]}`} alt="Product" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                                                ) : (
                                                    'No Image'
                                                )}
                                            </div>
                                            <div>
                                                <h3 style={{ margin: '0 0 8px 0', fontSize: '1.25rem' }}>{selectedTask.raw.product.title}</h3>
                                                <div style={{ color: 'var(--text-muted)', marginBottom: '4px' }}>Price: RM {selectedTask.raw.product.price}</div>
                                                <div style={{ color: 'var(--text-muted)', marginBottom: '4px' }}>Condition: {selectedTask.raw.product.condition}</div>
                                                <div style={{ color: 'var(--text-muted)' }}>Seller ID: {selectedTask.raw.product.seller_id}</div>
                                            </div>
                                        </div>
                                    )}

                                    <div className="flex gap-4 items-start mb-4 bg-gray-50 p-4 rounded-lg">
                                        <AlertTriangle color="var(--danger)" />
                                        <div>
                                            <div style={{ fontWeight: 'bold', marginBottom: '8px' }}>User's Claim / Issue: </div>
                                            <div style={{ lineHeight: 1.6 }}>{selectedTask.content}</div>
                                        </div>
                                    </div>
                                    
                                    {selectedTask.raw.reporter && (
                                        <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginTop: '1rem' }}>
                                            Reported by: {selectedTask.raw.reporter.email}
                                        </div>
                                    )}
                                    {selectedTask.type === 'report' && selectedTask.raw.reporter_id && selectedTask.raw.reported_user_id && (
                                        <button 
                                            className="btn btn-outline" 
                                            style={{ marginTop: '1rem', width: '200px', fontSize: '0.85rem', padding: '6px', height: 'auto', display: 'flex', alignItems: 'center', gap: '6px' }}
                                            onClick={fetchPrivateTranscript}
                                            disabled={loadingTranscript}
                                        >
                                            {loadingTranscript ? 'Loading...' : '🔒 Audit Private Chats'}
                                        </button>
                                    )}
                                </div>
                            </div>

                            {/* Right Column: Terminal */}
                            <div className="card" style={{ flex: 2 }}>
                                <h2 style={{ margin: '0 0 1.5rem 0', fontSize: '1.25rem' }}>Moderation Terminal</h2>
                                
                                {selectedTask.type === 'ticket' && !selectedTask.lockedBy && (
                                    <button className="btn mb-4" style={{ width: '100%', background: '#f59e0b' }} onClick={handleLockTicket}>
                                        Lock & Investigate
                                    </button>
                                )}

                                <div style={{ marginBottom: '1.5rem', opacity: (selectedTask.type === 'ticket' && selectedTask.lockedBy !== currentUser?.id && currentUser?.role !== 'admin') ? 0.5 : 1, pointerEvents: (selectedTask.type === 'ticket' && selectedTask.lockedBy !== currentUser?.id && currentUser?.role !== 'admin') ? 'none' : 'auto' }}>
                                    <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-muted)', fontSize: '0.875rem' }}>Action Type</label>
                                    <select className="input" value={action} onChange={(e) => setAction(e.target.value)} style={{ marginBottom: 0, appearance: 'auto', width: '100%' }}>
                                        {selectedTask.type === 'report' ? (
                                            <>
                                                <option value="Dismissed">Dismiss Report</option>
                                                <option value="Uphold">Uphold & Suspend Listing</option>
                                                <option value="Escalated">Escalate to Admin</option>
                                            </>
                                        ) : (
                                            <>
                                                <option value="Resolved">Resolve Ticket</option>
                                                <option value="Escalated">Escalate to Admin</option>
                                            </>
                                        )}
                                    </select>
                                </div>

                                <div style={{ marginBottom: '2rem', opacity: (selectedTask.type === 'ticket' && selectedTask.lockedBy !== currentUser?.id && currentUser?.role !== 'admin') ? 0.5 : 1, pointerEvents: (selectedTask.type === 'ticket' && selectedTask.lockedBy !== currentUser?.id && currentUser?.role !== 'admin') ? 'none' : 'auto' }}>
                                    <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-muted)', fontSize: '0.875rem' }}>
                                        {selectedTask.type === 'ticket' ? 'Reply to User' : 'Internal Mod Notes'}
                                    </label>
                                    <textarea 
                                        className="input" 
                                        rows="6" 
                                        value={modNotes}
                                        onChange={(e) => setModNotes(e.target.value)}
                                        placeholder={selectedTask.type === 'ticket' ? "Message to user..." : "Document your findings..."}
                                        style={{ resize: 'vertical', width: '100%' }}
                                    ></textarea>
                                </div>

                                <button 
                                    className="btn" 
                                    onClick={handleSubmitAction}
                                    disabled={selectedTask.type === 'ticket' && selectedTask.lockedBy !== currentUser?.id && currentUser?.role !== 'admin'}
                                    style={{ 
                                        width: '100%', 
                                        background: action === 'Uphold' ? 'var(--danger)' : 'var(--primary)',
                                        opacity: (selectedTask.type === 'ticket' && selectedTask.lockedBy !== currentUser?.id && currentUser?.role !== 'admin') ? 0.5 : 1
                                    }}
                                >
                                    Submit Action
                                </button>
                            </div>
                        </div>
                    </>
                )}
            {/* Private Chat Audit Modal */}
            {showTranscriptModal && (
                <div 
                    style={{
                        position: 'fixed',
                        top: 0,
                        left: 0,
                        width: '100vw',
                        height: '100vh',
                        backgroundColor: 'rgba(15, 23, 42, 0.7)',
                        backdropFilter: 'blur(4px)',
                        zIndex: 9998,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center'
                    }}
                >
                    <div className="card" style={{ width: '600px', maxHeight: '80vh', display: 'flex', flexDirection: 'column', padding: '1.5rem', background: 'white' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid var(--border)', paddingBottom: '0.75rem', marginBottom: '1rem' }}>
                            <h3 style={{ margin: 0 }}>🔒 Private Chat Audit Transcript</h3>
                            <button 
                                className="btn btn-outline" 
                                style={{ padding: '4px 8px', height: 'auto', fontSize: '0.85rem' }} 
                                onClick={() => setShowTranscriptModal(false)}
                            >
                                Close
                            </button>
                        </div>
                        <div style={{ flex: 1, overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '0.75rem', background: '#f8fafc', padding: '1rem', borderRadius: '8px' }}>
                            {privateTranscript?.length === 0 ? (
                                <div style={{ color: 'var(--text-muted)', textAlign: 'center', margin: '2rem 0' }}>No messages exchanged between these users.</div>
                            ) : (
                                privateTranscript?.map(msg => {
                                    const isReporter = msg.sender_id === selectedTask.raw.reporter_id;
                                    return (
                                        <div 
                                            key={msg.id} 
                                            style={{ 
                                                alignSelf: isReporter ? 'flex-start' : 'flex-end',
                                                maxWidth: '80%',
                                                background: isReporter ? '#f1f5f9' : '#dcfce7',
                                                color: '#1e293b',
                                                padding: '8px 12px',
                                                borderRadius: '8px'
                                            }}
                                        >
                                            <div style={{ fontSize: '0.7rem', color: 'var(--text-muted)', marginBottom: '2px', fontWeight: 'bold' }}>
                                                {isReporter ? `Reporter (${selectedTask.raw.reporter?.username || 'Reporter'})` : `Reported User (${selectedTask.raw.reported_user?.username || 'Reported'})`}
                                            </div>
                                            <div style={{ fontSize: '0.9rem' }}>{msg.content}</div>
                                            <div style={{ fontSize: '0.65rem', color: 'var(--text-muted)', textAlign: 'right', marginTop: '2px' }}>
                                                {new Date(msg.createdAt).toLocaleTimeString()}
                                            </div>
                                        </div>
                                    );
                                })
                            )}
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default Triage;
