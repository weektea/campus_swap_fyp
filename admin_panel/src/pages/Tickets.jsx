import React, { useState, useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import { Lock, CheckCircle, ShieldCheck, AlertOctagon, Download } from 'lucide-react';
import api, { IMAGE_BASE_URL } from '../services/api';
import { useSocket } from '../context/SocketContext';

const getStatusBadgeStyle = (status) => {
    switch (status) {
        case 'Resolved':
            return { padding: '2px 6px', background: '#d1fae5', color: '#065f46', borderRadius: '4px', fontSize: '0.7rem', fontWeight: 'bold' };
        case 'Awaiting Reply':
            return { padding: '2px 6px', background: '#ffedd5', color: '#c2410c', borderRadius: '4px', fontSize: '0.7rem', fontWeight: 'bold', border: '1px solid #fed7aa' };
        case 'In-Progress':
            return { padding: '2px 6px', background: '#dbeafe', color: '#1e40af', borderRadius: '4px', fontSize: '0.7rem', fontWeight: 'bold' };
        case 'Escalated':
            return { padding: '2px 6px', background: '#fef3c7', color: '#92400e', borderRadius: '4px', fontSize: '0.7rem', fontWeight: 'bold' };
        default:
            return { padding: '2px 6px', background: '#f3f4f6', color: '#1f2937', borderRadius: '4px', fontSize: '0.7rem', fontWeight: 'bold' };
    }
};

const Tickets = () => {
    const location = useLocation();
    const [allTickets, setAllTickets] = useState([]);
    const [activeTab, setActiveTab] = useState('Pending'); // Pending | History
    const [ticketTypeFilter, setTicketTypeFilter] = useState('All'); // All | Appeals | General
    const [selectedTicket, setSelectedTicket] = useState(null);
    const [messages, setMessages] = useState([]);
    const [chatInput, setChatInput] = useState('');
    const [loading, setLoading] = useState(true);
    const [replyContent, setReplyContent] = useState('');
    const [action, setAction] = useState('Resolved'); // Resolved, Escalated
    const [currentUser, setCurrentUser] = useState(null);
    const [isReactivating, setIsReactivating] = useState(false);
    const socket = useSocket();

    const getImageUrl = (url) => {
        if (!url) return '';
        if (url.startsWith('http://') || url.startsWith('https://')) return url;
        return `${IMAGE_BASE_URL}${url.startsWith('/') ? '' : '/'}${url}`;
    };

    const handleExportTicketsCSV = () => {
        if (!allTickets || allTickets.length === 0) {
            alert('No ticket data to export.');
            return;
        }
        const csvRows = [
            ['Reference ID', 'Type', 'Student Name', 'Student Email', 'Subject', 'Priority', 'Status', 'Locked Handler', 'Created At']
        ];
        allTickets.forEach(ticket => {
            csvRows.push([
                ticket.reference_id || `TCK-${ticket.id}`,
                ticket.type === 'SUSPENSION_APPEAL' ? 'Account Appeal' : 'Support Ticket',
                ticket.student?.full_name || '',
                ticket.student?.email || '',
                ticket.subject || '',
                ticket.priority || 'Normal',
                ticket.status || '',
                ticket.handler?.full_name || ticket.locked_by || 'Unassigned',
                ticket.createdAt ? new Date(ticket.createdAt).toLocaleString() : ''
            ]);
        });
        const csvContent = csvRows.map(row => row.map(val => `"${String(val).replace(/"/g, '""')}"`).join(',')).join('\n');
        const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `Campus_Swap_Support_Tickets_Report_${new Date().toISOString().slice(0, 10)}.csv`;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        URL.revokeObjectURL(url);
    };

    const formatChatTimestamp = (createdAtStr) => {
        if (!createdAtStr) return '';
        const date = new Date(createdAtStr);
        const now = new Date();
        const isPreviousDay = date.getDate() !== now.getDate() ||
                              date.getMonth() !== now.getMonth() ||
                              date.getFullYear() !== now.getFullYear();
        const timeStr = date.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' });
        if (isPreviousDay) {
            const dateStr = date.toLocaleDateString([], { month: 'short', day: 'numeric' });
            return `${timeStr}, ${dateStr}`;
        }
        return timeStr;
    };

    useEffect(() => {
        const userStr = localStorage.getItem('user');
        if (userStr) setCurrentUser(JSON.parse(userStr));
        fetchTickets();
    }, [location]);

    useEffect(() => {
        if (selectedTicket) {
            fetchMessages(selectedTicket.realId);
            const interval = setInterval(() => fetchMessages(selectedTicket.realId), 3000);
            return () => clearInterval(interval);
        }
    }, [selectedTicket]);

    useEffect(() => {
        if (!socket) return;

        const handleNewMessage = (data) => {
            if (selectedTicket && data && data.reference_id === selectedTicket.realId.toString()) {
                setMessages(prev => {
                    if (prev.some(m => m.id === data.id)) return prev;
                    return [...prev, data];
                });
            }
        };

        const handleNewTicket = () => {
            console.log('Tickets: WebSocket new ticket event. Reloading list.');
            fetchTickets();
        };

        socket.on('receive_new_message', handleNewMessage);
        socket.on('new_ticket_submitted', handleNewTicket);

        return () => {
            socket.off('receive_new_message', handleNewMessage);
            socket.off('new_ticket_submitted', handleNewTicket);
        };
    }, [socket, selectedTicket]);

    const fetchTickets = async () => {
        setLoading(true);
        try {
            const res = await api.get('/admin/tickets');
            const data = res.data.map(t => {
                const isAppeal = t.type === 'SUSPENSION_APPEAL' || (t.subject && t.subject.toLowerCase().includes('suspended'));
                return {
                    id: `TKT-${t.id.substring(0, 8)}`,
                    realId: t.id,
                    isAppeal,
                    studentEmail: t.student?.email || 'Unknown',
                    studentName: t.student?.full_name || t.student?.username || 'User',
                    studentId: t.student?.id || t.user_id,
                    studentStatus: t.student?.status,
                    studentIsActive: t.student?.is_active,
                    subject: t.subject || 'Support Ticket',
                    content: t.issue_description || t.description || 'No description',
                    submittedAt: t.createdAt,
                    status: t.status,
                    lockedBy: t.lockedByModeratorId,
                    raw: t
                };
            });

            data.sort((a, b) => new Date(b.submittedAt) - new Date(a.submittedAt));
            setAllTickets(data);

            const targetId = location.state?.selectedId;
            if (targetId) {
                const found = data.find(t => t.realId === targetId || t.id === targetId);
                if (found) {
                    setSelectedTicket(found);
                    setReplyContent(found.raw.reply_content || '');
                    if (found.status === 'Resolved') {
                        setActiveTab('History');
                    } else {
                        setActiveTab('Pending');
                    }
                } else {
                    const pending = data.filter(t => t.status !== 'Resolved');
                    if (pending.length > 0) {
                        setSelectedTicket(pending[0]);
                        setActiveTab('Pending');
                    }
                }
            } else {
                const pending = data.filter(t => t.status !== 'Resolved');
                if (pending.length > 0 && !selectedTicket) {
                    setSelectedTicket(pending[0]);
                    setActiveTab('Pending');
                }
            }
        } catch (err) {
            console.error('Failed to fetch tickets', err);
        } finally {
            setLoading(false);
        }
    };

    const fetchMessages = async (referenceId) => {
        try {
            const res = await api.get(`/tickets/thread/${referenceId}`);
            setMessages(res.data);
        } catch (err) {
            console.error('Failed to fetch thread messages', err);
        }
    };

    const handleSendChatMessage = async (e) => {
        e.preventDefault();
        if (!chatInput.trim() || !selectedTicket) return;
        try {
            const res = await api.post(`/tickets/thread/${selectedTicket.realId}`, {
                reference_type: 'SupportTicket',
                content: chatInput.trim()
            });
            setMessages(prev => [...prev, {
                ...res.data,
                sender: currentUser
            }]);
            setChatInput('');
        } catch (err) {
            alert('Failed to send message: ' + (err.response?.data?.error || err.message));
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

    const handleReactivateUser = async () => {
        if (!selectedTicket?.studentId) return;
        if (!window.confirm(`Reactivate account for user ${selectedTicket.studentName}?`)) return;

        setIsReactivating(true);
        try {
            await api.post(`/admin/users/${selectedTicket.studentId}/suspend`, { is_active: true });
            alert(`User ${selectedTicket.studentName} has been successfully reactivated!`);
            fetchTickets();
        } catch (err) {
            alert(err.response?.data?.error || 'Failed to reactivate user');
        } finally {
            setIsReactivating(false);
        }
    };

    const handleSubmitAction = async () => {
        if (!selectedTicket) return;
        try {
            await api.put(`/admin/tickets/${selectedTicket.realId}`, {
                status: action,
                reply_content: replyContent
            });
            alert('Reply submitted successfully!');
            setReplyContent('');
            setSelectedTicket(null);
            fetchTickets();
        } catch (err) {
            alert(err.response?.data?.error || 'Failed to submit action');
        }
    };

    // Filter tickets by Tab (Pending/History) and Filter Type (All/Appeals/General)
    const baseTickets = activeTab === 'Pending' 
        ? allTickets.filter(t => t.status !== 'Resolved') 
        : allTickets.filter(t => t.status === 'Resolved');

    const displayedTickets = baseTickets.filter(t => {
        if (ticketTypeFilter === 'Appeals') return t.isAppeal;
        if (ticketTypeFilter === 'General') return !t.isAppeal;
        return true;
    });

    const isModerator = currentUser?.role === 'moderator';
    const appealsCount = baseTickets.filter(t => t.isAppeal).length;

    if (loading) return <div className="p-8 text-center text-gray-500">Loading tickets...</div>;

    return (
        <div className="flex gap-6 h-full" style={{ minHeight: '80vh' }}>
            {/* Sidebar List */}
            <div className="card flex flex-col gap-2" style={{ width: '320px', padding: '1rem', overflowY: 'auto' }}>
                {/* Header Stats */}
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
                    <span style={{ fontSize: '0.85rem', fontWeight: 'bold', color: 'var(--text-main)' }}>Tickets Console ({allTickets.length})</span>
                    <button
                        className="btn"
                        onClick={handleExportTicketsCSV}
                        style={{ padding: '4px 8px', fontSize: '0.75rem', background: '#0d503c', color: 'white', border: 'none', display: 'flex', alignItems: 'center', gap: '4px', borderRadius: '6px' }}
                        title="Export Tickets CSV"
                    >
                        <Download size={13} /> Export CSV
                    </button>
                </div>

                {/* Status Tab Switcher (Pending vs History) */}
                <div style={{ display: 'flex', borderBottom: '1px solid var(--border)', marginBottom: '8px' }}>
                    <button
                        onClick={() => { setActiveTab('Pending'); setSelectedTicket(null); }}
                        style={{
                            flex: 1,
                            padding: '8px',
                            fontWeight: 'bold',
                            border: 'none',
                            background: 'transparent',
                            borderBottom: activeTab === 'Pending' ? '2px solid var(--primary)' : 'none',
                            color: activeTab === 'Pending' ? 'var(--primary)' : 'var(--text-muted)',
                            cursor: 'pointer',
                            fontSize: '0.85rem'
                        }}
                    >
                        Pending ({allTickets.filter(t => t.status !== 'Resolved').length})
                    </button>
                    <button
                        onClick={() => { setActiveTab('History'); setSelectedTicket(null); }}
                        style={{
                            flex: 1,
                            padding: '8px',
                            fontWeight: 'bold',
                            border: 'none',
                            background: 'transparent',
                            borderBottom: activeTab === 'History' ? '2px solid var(--primary)' : 'none',
                            color: activeTab === 'History' ? 'var(--primary)' : 'var(--text-muted)',
                            cursor: 'pointer',
                            fontSize: '0.85rem'
                        }}
                    >
                        History ({allTickets.filter(t => t.status === 'Resolved').length})
                    </button>
                </div>

                {/* Sub-Filter Pills (All | Appeals | General) */}
                <div style={{ display: 'flex', gap: '4px', marginBottom: '12px' }}>
                    {[
                        { label: 'All', key: 'All' },
                        { label: `🔒 Appeals (${appealsCount})`, key: 'Appeals' },
                        { label: '💬 General', key: 'General' }
                    ].map(f => (
                        <button
                            key={f.key}
                            onClick={() => setTicketTypeFilter(f.key)}
                            style={{
                                flex: 1,
                                border: 'none',
                                borderRadius: '12px',
                                padding: '4px 6px',
                                fontSize: '0.72rem',
                                fontWeight: 'bold',
                                cursor: 'pointer',
                                transition: 'all 0.2s',
                                background: ticketTypeFilter === f.key ? (f.key === 'Appeals' ? '#ef4444' : 'var(--primary)') : '#f3f4f6',
                                color: ticketTypeFilter === f.key ? 'white' : '#4b5563'
                            }}
                        >
                            {f.label}
                        </button>
                    ))}
                </div>

                {/* Ticket Items List */}
                {displayedTickets.map(ticket => (
                    <div 
                        key={ticket.id}
                        onClick={async () => {
                            setSelectedTicket(ticket);
                            setReplyContent(ticket.raw.reply_content || '');
                            setAction('Resolved');
                            if (activeTab === 'Pending' && !ticket.lockedBy) {
                                try {
                                    await api.post(`/admin/tickets/${ticket.realId}/lock`);
                                    fetchTickets();
                                } catch (err) {
                                    console.error('Auto lock ticket failed:', err);
                                }
                            }
                        }}
                        style={{ 
                            padding: '12px', 
                            borderRadius: '8px', 
                            border: '1px solid var(--border)',
                            background: selectedTicket?.id === ticket.id ? (ticket.isAppeal ? '#fef2f2' : '#eff6ff') : 'white',
                            borderColor: selectedTicket?.id === ticket.id ? (ticket.isAppeal ? '#fca5a5' : '#bfdbfe') : (ticket.isAppeal ? '#fee2e2' : 'var(--border)'),
                            cursor: 'pointer',
                            display: 'flex', flexDirection: 'column', gap: '6px'
                        }}
                    >
                        <div className="flex justify-between items-center">
                            <span style={{ fontWeight: 'bold', fontSize: '0.85rem' }}>{ticket.id}</span>
                            <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>{new Date(ticket.submittedAt).toLocaleDateString()}</span>
                        </div>
                        
                        {/* Appeal Badge Indicator */}
                        {ticket.isAppeal ? (
                            <span style={{ fontSize: '0.7rem', color: '#dc2626', fontWeight: 'bold', background: '#fee2e2', padding: '2px 8px', borderRadius: '6px', width: 'fit-content', border: '1px solid #fca5a5' }}>
                                🔒 Account Appeal
                            </span>
                        ) : (
                            <span style={{ fontSize: '0.7rem', color: '#2563eb', fontWeight: 'bold', background: '#eff6ff', padding: '2px 8px', borderRadius: '6px', width: 'fit-content' }}>
                                💬 Support Inquiry
                            </span>
                        )}

                        <div style={{ fontSize: '0.8rem', color: '#374151', fontWeight: '500', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                            {ticket.subject}
                        </div>
                        <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                            User: {ticket.studentName} ({ticket.studentEmail})
                        </div>
                        <div>
                            <span style={getStatusBadgeStyle(ticket.status)}>
                                {ticket.status}
                            </span>
                        </div>
                    </div>
                ))}
                {displayedTickets.length === 0 && <div style={{ color: 'var(--text-muted)', textAlign: 'center', marginTop: '2rem', fontSize: '0.85rem' }}>No {activeTab.toLowerCase()} tickets found.</div>}
            </div>

            {/* Ticket Workspace Details */}
            <div className="flex-1 flex flex-col gap-6">
                {!selectedTicket ? (
                    <div className="card flex items-center justify-center h-full" style={{ color: 'var(--text-muted)' }}>
                        Select a ticket from the left to view thread and respond.
                    </div>
                ) : (
                    <>
                        {/* Account Appeal Special Banner */}
                        {selectedTicket.isAppeal && (
                            <div style={{ background: '#fef2f2', border: '1px solid #fca5a5', padding: '12px 20px', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', color: '#991b1b' }}>
                                <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                                    <AlertOctagon size={22} color="#dc2626" />
                                    <div>
                                        <strong style={{ fontSize: '0.95rem' }}>Suspended Account Reactivation Appeal</strong>
                                        <p style={{ margin: 0, fontSize: '0.8rem', color: '#7f1d1d' }}>
                                            Submitted by suspended user: <strong>{selectedTicket.studentName}</strong> ({selectedTicket.studentEmail})
                                        </p>
                                    </div>
                                </div>
                                <button 
                                    className="btn" 
                                    style={{ background: '#dc2626', color: 'white', fontSize: '0.8rem', padding: '6px 14px', borderRadius: '8px', display: 'flex', alignItems: 'center', gap: '6px' }}
                                    onClick={handleReactivateUser}
                                    disabled={isReactivating}
                                >
                                    <ShieldCheck size={16} />
                                    {isReactivating ? 'Reactivating...' : 'Reactivate Account'}
                                </button>
                            </div>
                        )}

                        {selectedTicket.status !== 'Resolved' && selectedTicket.lockedBy === currentUser?.id && (
                            <div style={{ background: '#e8f5e9', padding: '10px 20px', borderRadius: '8px', display: 'flex', alignItems: 'center', gap: '8px', color: '#2e7d32', fontWeight: 'bold', fontSize: '0.85rem' }}>
                                <Lock size={16} /><span>Ticket {selectedTicket.id} is currently locked by you.</span>
                            </div>
                        )}
                        {selectedTicket.status !== 'Resolved' && selectedTicket.lockedBy && selectedTicket.lockedBy !== currentUser?.id && (
                            <div style={{ background: '#fff7ed', padding: '10px 20px', borderRadius: '8px', display: 'flex', alignItems: 'center', gap: '8px', color: '#c2410c', fontWeight: 'bold', fontSize: '0.85rem' }}>
                                <Lock size={16} /><span>Ticket {selectedTicket.id} is locked by another staff member.</span>
                            </div>
                        )}

                        <div className="flex gap-6 items-start">
                             <div style={{ flex: 3 }} className="flex flex-col gap-6">
                                 {/* Ticket Description Card */}
                                 <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
                                     <div style={{ padding: '1.25rem 1.5rem', borderBottom: '1px solid var(--border)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                         <h2 style={{ margin: 0, fontSize: '1.15rem', fontWeight: 'bold' }}>{selectedTicket.subject}</h2>
                                         <span style={getStatusBadgeStyle(selectedTicket.status)}>{selectedTicket.status}</span>
                                     </div>
                                     <div style={{ padding: '1.5rem' }}>
                                         <div style={{ fontWeight: '600', marginBottom: '8px', fontSize: '0.85rem', color: '#4b5563' }}>Issue Description / Reason:</div>
                                         <div style={{ lineHeight: 1.6, background: '#f9fafb', padding: '1rem', borderRadius: '8px', border: '1px solid #f3f4f6', fontSize: '0.9rem' }}>
                                             {selectedTicket.content}
                                         </div>
                                         <div style={{ color: 'var(--text-muted)', fontSize: '0.8rem', marginTop: '1rem' }}>
                                             Submitted by: <strong>{selectedTicket.studentName}</strong> ({selectedTicket.studentEmail})
                                         </div>
                                     </div>
                                 </div>

                                 {/* Support Chat Thread */}
                                 <div className="card" style={{ display: 'flex', flexDirection: 'column', height: '400px' }}>
                                     <h3 style={{ margin: '0 0 1rem 0', fontSize: '1.1rem' }}>Support Chat Thread</h3>
                                     <div style={{ flex: 1, overflowY: 'auto', padding: '1rem', background: '#f8fafc', borderRadius: '12px', marginBottom: '1rem', display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                                         {messages.length === 0 ? (
                                             <div style={{ color: 'var(--text-muted)', textAlign: 'center', marginTop: '2rem', fontSize: '0.9rem' }}>No messages in thread yet. Start the conversation!</div>
                                         ) : (
                                             messages.map(msg => {
                                                 const isMe = msg.sender_id === currentUser?.id;
                                                 const isStaff = msg.sender?.role === 'admin' || msg.sender?.role === 'moderator';
                                                 
                                                 return (
                                                     <div 
                                                         key={msg.id} 
                                                         style={{ 
                                                             alignSelf: isMe ? 'flex-end' : 'flex-start',
                                                             maxWidth: '75%',
                                                             display: 'flex',
                                                             flexDirection: 'column',
                                                             alignItems: isMe ? 'flex-end' : 'flex-start'
                                                         }}
                                                     >
                                                         <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginBottom: '2px', fontWeight: '500' }}>
                                                             {isMe ? 'You' : (isStaff ? 'Staff Support' : (msg.sender?.full_name || msg.sender?.email || 'User'))}
                                                         </span>
                                                         <div style={{
                                                             padding: '10px 16px',
                                                             borderRadius: '16px',
                                                             borderBottomRightRadius: isMe ? '2px' : '16px',
                                                             borderBottomLeftRadius: isMe ? '16px' : '2px',
                                                             background: isMe ? 'var(--primary)' : '#e2e8f0',
                                                             color: isMe ? 'white' : 'var(--text-main)',
                                                             fontSize: '0.9rem',
                                                             lineHeight: 1.4,
                                                             boxShadow: '0 1px 2px rgba(0,0,0,0.05)'
                                                         }}>
                                                             <div>{msg.content}</div>
                                                             {msg.attachment_url && (
                                                                 <div style={{ marginTop: '8px', maxWidth: '240px', maxHeight: '180px', overflow: 'hidden', borderRadius: '8px', border: '1px solid rgba(0,0,0,0.1)' }}>
                                                                     <img 
                                                                         src={getImageUrl(msg.attachment_url)} 
                                                                         alt="Attachment" 
                                                                         style={{ width: '100%', height: '100%', objectFit: 'cover', cursor: 'pointer' }}
                                                                         onClick={() => window.open(getImageUrl(msg.attachment_url), '_blank')}
                                                                     />
                                                                 </div>
                                                             )}
                                                         </div>
                                                         <span style={{ fontSize: '0.65rem', color: '#94a3b8', marginTop: '2px' }}>
                                                             {formatChatTimestamp(msg.createdAt)}
                                                         </span>
                                                     </div>
                                                 );
                                             })
                                         )}
                                     </div>
                                     {selectedTicket.status === 'Resolved' || selectedTicket.status === 'Closed' ? (
                                         <div style={{ textAlign: 'center', padding: '12px', background: '#f1f5f9', borderRadius: '8px', color: '#64748b', fontWeight: '500', fontSize: '0.9rem' }}>
                                             🔒 This ticket is resolved and closed.
                                         </div>
                                     ) : (selectedTicket.status === 'Escalated' && isModerator) ? (
                                         <div style={{ textAlign: 'center', padding: '12px', background: '#fff7ed', borderRadius: '8px', color: '#ea580c', fontWeight: '500', fontSize: '0.9rem' }}>
                                             🔒 Escalated to Administrator. Chat is locked for Moderators.
                                         </div>
                                     ) : (selectedTicket.lockedBy && selectedTicket.lockedBy !== currentUser?.id && isModerator) ? (
                                         <div style={{ textAlign: 'center', padding: '12px', background: '#fef2f2', borderRadius: '8px', color: '#dc2626', fontWeight: '500', fontSize: '0.9rem' }}>
                                             🔒 Ticket is locked by another moderator. Chat is view-only.
                                         </div>
                                     ) : (
                                         <form onSubmit={handleSendChatMessage} className="flex gap-2">
                                             <input 
                                                 type="text" 
                                                 className="input" 
                                                 value={chatInput} 
                                                 onChange={e => setChatInput(e.target.value)} 
                                                 placeholder="Type a reply to the user..."
                                                 style={{ margin: 0, flex: 1 }}
                                             />
                                             <button type="submit" className="btn" style={{ padding: '0 1.5rem' }}>Send</button>
                                         </form>
                                     )}
                                 </div>
                             </div>

                            {/* Action & Resolution Terminal */}
                            <div className="card" style={{ flex: 2 }}>
                                <h2 style={{ margin: '0 0 1.5rem 0', fontSize: '1.25rem' }}>Helpdesk Terminal</h2>
                                
                                {selectedTicket.status === 'Resolved' ? (
                                    <div style={{ padding: '16px', background: '#f8fafc', borderRadius: '12px', border: '1px solid var(--border)' }}>
                                        <div style={{ display: 'flex', gap: '8px', alignItems: 'center', marginBottom: '12px' }}>
                                            <CheckCircle size={18} color="var(--success)" />
                                            <strong style={{ fontSize: '1rem', color: 'var(--text-main)' }}>Ticket Resolved</strong>
                                        </div>
                                        {selectedTicket.raw.handler && (
                                            <div style={{ fontSize: '0.9rem', marginBottom: '8px' }}>
                                                <strong>Resolved By:</strong> <span style={{ color: 'var(--text-main)', fontWeight: 'bold' }}>{selectedTicket.raw.handler.full_name} ({selectedTicket.raw.handler.role})</span>
                                            </div>
                                        )}
                                        <div style={{ fontSize: '0.9rem', color: 'var(--text-muted)', lineHeight: '1.5' }}>
                                            <strong>Resolution Reply:</strong>
                                            <p style={{ marginTop: '4px', fontStyle: 'italic', background: 'white', padding: '8px 12px', borderRadius: '6px', border: '1px solid #e2e8f0', color: 'var(--text-main)' }}>
                                                {selectedTicket.raw.reply_content || 'No reply content saved.'}
                                            </p>
                                        </div>
                                    </div>
                                ) : (selectedTicket.status === 'Escalated' && isModerator) ? (
                                    <div style={{ padding: '16px', background: '#f8fafc', borderRadius: '12px', border: '1px solid var(--border)' }}>
                                        <div style={{ display: 'flex', gap: '8px', alignItems: 'center', marginBottom: '12px' }}>
                                            <Lock size={18} color="#ea580c" />
                                            <strong style={{ fontSize: '1rem', color: 'var(--text-main)' }}>Escalated to Admin</strong>
                                        </div>
                                        {selectedTicket.raw.handler && (
                                            <div style={{ fontSize: '0.9rem', marginBottom: '8px' }}>
                                                <strong>Escalated By:</strong> <span style={{ color: 'var(--text-main)', fontWeight: 'bold' }}>{selectedTicket.raw.handler.full_name} ({selectedTicket.raw.handler.role})</span>
                                            </div>
                                        )}
                                        <div style={{ fontSize: '0.9rem', color: 'var(--text-muted)', lineHeight: '1.5' }}>
                                            <strong>Internal Notes:</strong>
                                            <p style={{ marginTop: '4px', fontStyle: 'italic', background: 'white', padding: '8px 12px', borderRadius: '6px', border: '1px solid #e2e8f0', color: 'var(--text-main)' }}>
                                                {selectedTicket.raw.reply_content || 'No notes provided.'}
                                            </p>
                                        </div>
                                    </div>
                                ) : (
                                    <>
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
                                                    {currentUser?.role !== 'admin' && selectedTicket.status !== 'Escalated' && (
                                                        <option value="Escalated">Escalate to Admin</option>
                                                    )}
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
                                    </>
                                )}
                            </div>
                        </div>
                    </>
                )}
            </div>
        </div>
    );
};

export default Tickets;
