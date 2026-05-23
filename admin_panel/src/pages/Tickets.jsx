import React, { useState, useEffect } from 'react';
import { Lock, CheckCircle } from 'lucide-react';
import api from '../services/api';

const Tickets = () => {
    const [tickets, setTickets] = useState([]);
    const [selectedTicket, setSelectedTicket] = useState(null);
    const [loading, setLoading] = useState(true);
    const [replyContent, setReplyContent] = useState('');
    const [action, setAction] = useState('Resolved'); // Resolved, Escalated
    const [currentUser, setCurrentUser] = useState(null);

    useEffect(() => {
        const userStr = localStorage.getItem('user');
        if (userStr) setCurrentUser(JSON.parse(userStr));
        fetchTickets();
    }, []);

    const fetchTickets = async () => {
        setLoading(true);
        try {
            const res = await api.get('/admin/tickets');
            const data = res.data.map(t => ({
                id: `TKT-${t.id}`,
                realId: t.id,
                studentEmail: t.student?.email || 'Unknown',
                content: t.issue_description,
                submittedAt: t.createdAt,
                status: t.status,
                lockedBy: t.lockedByModeratorId,
                raw: t
            }));

            const actionable = data.filter(t => !['Resolved'].includes(t.status));
            actionable.sort((a, b) => new Date(b.submittedAt) - new Date(a.submittedAt));
            
            setTickets(actionable);
            if (actionable.length > 0 && !selectedTicket) {
                setSelectedTicket(actionable[0]);
            }
        } catch (err) {
            console.error('Failed to fetch tickets', err);
        } finally {
            setLoading(false);
        }
    };

    const handleLockTicket = async () => {
        if (!selectedTicket) return;
        try {
            await api.post(`/admin/tickets/${selectedTicket.realId}/lock`);
            fetchTickets();
            setSelectedTicket({ ...selectedTicket, lockedBy: currentUser?.id, status: 'In-Progress' });
        } catch (err) {
            alert(err.response?.data?.error || 'Failed to lock ticket');
        }
    };

    const handleSubmitAction = async () => {
        if (!selectedTicket) return;
        try {
            await api.put(`/admin/tickets/${selectedTicket.realId}`, {
                status: action,
                reply_content: replyContent
            });
            alert('Reply sent successfully!');
            setReplyContent('');
            setSelectedTicket(null);
            fetchTickets();
        } catch (err) {
            alert(err.response?.data?.error || 'Failed to submit action');
        }
    };

    if (loading) return <div className="p-8 text-center text-gray-500">Loading tickets...</div>;

    return (
        <div className="flex gap-6 h-full" style={{ minHeight: '80vh' }}>
            <div className="card flex flex-col gap-2" style={{ width: '300px', padding: '1rem', overflowY: 'auto' }}>
                <h3 style={{ margin: '0 0 1rem 0' }}>Open Tickets ({tickets.length})</h3>
                {tickets.map(ticket => (
                    <div 
                        key={ticket.id}
                        onClick={() => { setSelectedTicket(ticket); setReplyContent(''); setAction('Resolved'); }}
                        style={{ 
                            padding: '12px', 
                            borderRadius: '8px', 
                            border: '1px solid var(--border)',
                            background: selectedTicket?.id === ticket.id ? '#eff6ff' : 'white',
                            borderColor: selectedTicket?.id === ticket.id ? '#bfdbfe' : 'var(--border)',
                            cursor: 'pointer',
                            display: 'flex', flexDirection: 'column', gap: '4px'
                        }}
                    >
                        <div className="flex justify-between items-center">
                            <span style={{ fontWeight: 'bold', fontSize: '0.875rem' }}>{ticket.id}</span>
                            <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>{new Date(ticket.submittedAt).toLocaleDateString()}</span>
                        </div>
                        <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                            User: {ticket.studentEmail}
                        </div>
                        <div>
                            <span style={{ padding: '2px 6px', background: '#f3f4f6', borderRadius: '4px', fontSize: '0.7rem', fontWeight: 'bold' }}>
                                {ticket.status}
                            </span>
                        </div>
                    </div>
                ))}
                {tickets.length === 0 && <div style={{ color: 'var(--text-muted)', textAlign: 'center', marginTop: '2rem' }}>No open tickets.</div>}
            </div>

            <div className="flex-1 flex flex-col gap-6">
                {!selectedTicket ? (
                    <div className="card flex items-center justify-center h-full" style={{ color: 'var(--text-muted)' }}>
                        Select a ticket from the left to view details.
                    </div>
                ) : (
                    <>
                        {selectedTicket.lockedBy === currentUser?.id && (
                            <div style={{ background: '#e8f5e9', padding: '12px 32px', borderRadius: '8px', display: 'flex', alignItems: 'center', gap: '8px', color: '#2e7d32', fontWeight: 'bold' }}>
                                <Lock size={18} /><span>Ticket {selectedTicket.id} is currently locked by you.</span>
                            </div>
                        )}
                        {selectedTicket.lockedBy && selectedTicket.lockedBy !== currentUser?.id && (
                            <div style={{ background: '#fef2f2', padding: '12px 32px', borderRadius: '8px', display: 'flex', alignItems: 'center', gap: '8px', color: '#dc2626', fontWeight: 'bold' }}>
                                <Lock size={18} /><span>Ticket {selectedTicket.id} is locked by another moderator.</span>
                            </div>
                        )}

                        <div className="flex gap-6 items-start">
                            <div className="card" style={{ flex: 3, padding: 0, overflow: 'hidden' }}>
                                <div style={{ padding: '1.5rem', borderBottom: '1px solid var(--border)' }}>
                                    <h2 style={{ margin: 0, fontSize: '1.25rem' }}>Support Ticket Details</h2>
                                </div>
                                <div style={{ padding: '1.5rem' }}>
                                    <div style={{ fontWeight: 'bold', marginBottom: '8px' }}>User's Issue: </div>
                                    <div style={{ lineHeight: 1.6, background: '#f9fafb', padding: '1rem', borderRadius: '8px' }}>
                                        {selectedTicket.content}
                                    </div>
                                    <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginTop: '1rem' }}>
                                        Submitted by: {selectedTicket.studentEmail}
                                    </div>
                                </div>
                            </div>

                            <div className="card" style={{ flex: 2 }}>
                                <h2 style={{ margin: '0 0 1.5rem 0', fontSize: '1.25rem' }}>Helpdesk Terminal</h2>
                                
                                {!selectedTicket.lockedBy && (
                                    <button className="btn mb-4" style={{ width: '100%', background: '#f59e0b' }} onClick={handleLockTicket}>
                                        Lock & Investigate
                                    </button>
                                )}

                                <div style={{ opacity: (selectedTicket.lockedBy !== currentUser?.id && currentUser?.role !== 'admin') ? 0.5 : 1, pointerEvents: (selectedTicket.lockedBy !== currentUser?.id && currentUser?.role !== 'admin') ? 'none' : 'auto' }}>
                                    <div style={{ marginBottom: '1.5rem' }}>
                                        <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-muted)', fontSize: '0.875rem' }}>Status Update</label>
                                        <select className="input" value={action} onChange={(e) => setAction(e.target.value)} style={{ marginBottom: 0, appearance: 'auto', width: '100%' }}>
                                            <option value="Resolved">Resolve Ticket</option>
                                            <option value="Escalated">Escalate to Admin</option>
                                        </select>
                                    </div>
                                    <div style={{ marginBottom: '2rem' }}>
                                        <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-muted)', fontSize: '0.875rem' }}>Reply to User</label>
                                        <textarea 
                                            className="input" 
                                            rows="6" 
                                            value={replyContent}
                                            onChange={(e) => setReplyContent(e.target.value)}
                                            placeholder="Message to user..."
                                            style={{ resize: 'vertical', width: '100%' }}
                                        ></textarea>
                                    </div>
                                    <button className="btn" onClick={handleSubmitAction} style={{ width: '100%' }}>
                                        Submit Reply
                                    </button>
                                </div>
                            </div>
                        </div>
                    </>
                )}
            </div>
        </div>
    );
};

export default Tickets;
