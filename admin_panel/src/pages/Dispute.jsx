import React, { useState, useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import { Flame, Info, CheckCircle } from 'lucide-react';
import api from '../services/api';

const getStatusBadgeStyle = (status) => {
    switch (status) {
        case 'Resolved':
            return { padding: '2px 6px', background: '#dcfce7', color: '#15803d', borderRadius: '4px', fontSize: '0.7rem', fontWeight: 'bold' };
        case 'Awaiting Reply':
            return { padding: '2px 6px', background: '#ffedd5', color: '#c2410c', borderRadius: '4px', fontSize: '0.7rem', fontWeight: 'bold', border: '1px solid #fed7aa' };
        case 'Investigating':
            return { padding: '2px 6px', background: '#dbeafe', color: '#1e40af', borderRadius: '4px', fontSize: '0.7rem', fontWeight: 'bold' };
        case 'Escalated':
        case 'Escalated to Admin':
        case 'Escalated to Administrator':
            return { padding: '2px 6px', background: '#fee2e2', color: '#991b1b', borderRadius: '4px', fontSize: '0.7rem', fontWeight: 'bold' };
        default:
            return { padding: '2px 6px', background: '#fef3c7', color: '#92400e', borderRadius: '4px', fontSize: '0.7rem', fontWeight: 'bold' };
    }
};

const Dispute = () => {
    const location = useLocation();
    const [allDisputes, setAllDisputes] = useState([]);
    const [activeTab, setActiveTab] = useState('Pending'); // Pending | History
    const [selectedDispute, setSelectedDispute] = useState(null);
    const [messages, setMessages] = useState([]);
    const [chatInput, setChatInput] = useState('');
    const [lightboxImage, setLightboxImage] = useState(null);
    const [loading, setLoading] = useState(true);
    const [notes, setNotes] = useState('');
    const [modAction, setModAction] = useState('Investigate'); // Dismiss, Investigate, Escalate
    const [actionOnLoser, setActionOnLoser] = useState('none'); // none, warn, ban
    
    const [currentUser, setCurrentUser] = useState(null);

    useEffect(() => {
        const userStr = localStorage.getItem('user');
        if (userStr) setCurrentUser(JSON.parse(userStr));
        fetchDisputes();
    }, [location]);

    useEffect(() => {
        if (selectedDispute) {
            fetchMessages(selectedDispute.id);
            const interval = setInterval(() => fetchMessages(selectedDispute.id), 5000);
            return () => clearInterval(interval);
        }
    }, [selectedDispute]);

    const pendingDisputes = allDisputes.filter(d => d.status !== 'Resolved' && d.status !== 'Dismissed');
    const historyDisputes = allDisputes.filter(d => d.status === 'Resolved' || d.status === 'Dismissed');
    const displayedDisputes = activeTab === 'Pending' ? pendingDisputes : historyDisputes;
    const isModerator = currentUser?.role === 'moderator';

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
        if (!chatInput.trim() || !selectedDispute) return;
        try {
            const res = await api.post(`/tickets/thread/${selectedDispute.id}`, {
                reference_type: 'Dispute',
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

    const fetchDisputes = async () => {
        setLoading(true);
        try {
            const res = await api.get('/admin/disputes');
            const data = res.data;
            data.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
            setAllDisputes(data);

            // Pre-select if navigated from dashboard or specific alert link
            const targetId = location.state?.selectedId;
            if (targetId) {
                const found = data.find(d => d.id === targetId);
                if (found) {
                    setSelectedDispute(found);
                    setNotes(found.admin_notes || '');
                    if (found.status === 'Resolved' || found.status === 'Dismissed') {
                        setActiveTab('History');
                    } else {
                        setActiveTab('Pending');
                    }
                } else {
                    const pending = data.filter(d => d.status !== 'Resolved' && d.status !== 'Dismissed');
                    if (pending.length > 0) {
                        setSelectedDispute(pending[0]);
                        setActiveTab('Pending');
                    }
                }
            } else {
                const pending = data.filter(d => d.status !== 'Resolved' && d.status !== 'Dismissed');
                if (pending.length > 0 && !selectedDispute) {
                    setSelectedDispute(pending[0]);
                    setActiveTab('Pending');
                }
            }
        } catch (err) {
            console.error('Failed to fetch disputes', err);
        } finally {
            setLoading(false);
        }
    };

    const handleModTriage = async () => {
        if (!selectedDispute) return;
        try {
            await api.put(`/disputes/${selectedDispute.id}/triage`, {
                action: modAction,
                mod_notes: notes
            });
            alert('Triage action submitted!');
            setNotes('');
            setSelectedDispute(null);
            fetchDisputes();
        } catch (err) {
            alert(err.response?.data?.error || 'Failed to triage dispute');
        }
    };

    const handleAdminArbitrate = async (winner) => {
        if (!selectedDispute) return;
        if (!['Escalated', 'Escalated to Admin'].includes(selectedDispute.status)) {
            alert('Only escalated disputes can be arbitrated by an Admin.');
            return;
        }
        try {
            await api.put(`/disputes/${selectedDispute.id}/arbitrate`, {
                winning_party: winner,
                admin_notes: notes,
                action_on_loser: actionOnLoser
            });
            alert(`Dispute resolved in favor of ${winner}!`);
            setNotes('');
            setActionOnLoser('none');
            setSelectedDispute(null);
            fetchDisputes();
        } catch (err) {
            alert(err.response?.data?.error || 'Failed to arbitrate dispute');
        }
    };

    if (loading) return <div className="p-8 text-center text-gray-500">Loading disputes...</div>;

    return (
        <div className="flex gap-6 h-full" style={{ minHeight: '80vh' }}>
            {/* Sidebar List */}
            <div className="card flex flex-col gap-2" style={{ width: '300px', padding: '1rem', overflowY: 'auto' }}>
                {/* Tab Switcher */}
                <div style={{ display: 'flex', borderBottom: '1px solid var(--border)', marginBottom: '12px' }}>
                    <button
                        onClick={() => { setActiveTab('Pending'); setSelectedDispute(pendingDisputes[0] || null); }}
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
                        Pending ({pendingDisputes.length})
                    </button>
                    <button
                        onClick={() => { setActiveTab('History'); setSelectedDispute(historyDisputes[0] || null); }}
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
                        History ({historyDisputes.length})
                    </button>
                </div>

                {displayedDisputes.map(dispute => (
                    <div 
                        key={dispute.id}
                        onClick={() => { setSelectedDispute(dispute); setNotes(dispute.admin_notes || ''); }}
                        style={{ 
                            padding: '12px', 
                            borderRadius: '8px', 
                            border: '1px solid var(--border)',
                            background: selectedDispute?.id === dispute.id ? '#fff7ed' : 'white',
                            borderColor: selectedDispute?.id === dispute.id ? '#fed7aa' : 'var(--border)',
                            cursor: 'pointer',
                            display: 'flex',
                            flexDirection: 'column',
                            gap: '4px'
                        }}
                    >
                        <div className="flex justify-between items-center">
                            <span style={{ fontWeight: 'bold', fontSize: '0.875rem' }}>DSP-{dispute.id.substring(0, 8).toUpperCase()}</span>
                            <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>{new Date(dispute.createdAt).toLocaleDateString()}</span>
                        </div>
                        <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                            Transaction: TRX-{dispute.transaction_id.substring(0, 8).toUpperCase()}
                        </div>
                        <div>
                            <span style={getStatusBadgeStyle(dispute.status)}>
                                {dispute.status}
                            </span>
                        </div>
                    </div>
                ))}
                {displayedDisputes.length === 0 && <div style={{ color: 'var(--text-muted)', textAlign: 'center', marginTop: '2rem' }}>No {activeTab.toLowerCase()} disputes.</div>}
            </div>

            {/* Main Content */}
            <div className="flex-1 flex flex-col gap-6">
                {!selectedDispute ? (
                    <div className="card flex items-center justify-center h-full" style={{ color: 'var(--text-muted)' }}>
                        Select a dispute from the left to review.
                    </div>
                ) : (
                    <>
                        {selectedDispute.status === 'Escalated' && (
                            <div style={{ background: '#fff7ed', padding: '16px 32px', borderRadius: '8px', display: 'flex', alignItems: 'center', gap: '12px', color: '#ea580c', fontWeight: 'bold' }}>
                                <Flame size={20} />
                                <span>ESCALATED DISPUTE: Requires Admin Final Arbitration</span>
                            </div>
                        )}

                        <div className="flex gap-8 items-start">
                             <div style={{ flex: 3 }} className="flex flex-col gap-6">
                                 {/* Dispute Notes / Content */}
                                 <div style={{ background: '#f8fafc', padding: '1.5rem', borderRadius: '16px' }}>
                                     <div style={{ fontSize: '0.75rem', fontWeight: 'bold', color: '#64748b', letterSpacing: '1px', marginBottom: '1rem' }}>
                                         DISPUTE REASON
                                     </div>
                                     <h3 style={{ margin: '0 0 8px 0', color: 'var(--danger)' }}>{selectedDispute.reason}</h3>
                                     <p style={{ margin: 0, lineHeight: 1.6 }}>
                                         {selectedDispute.description}
                                     </p>
                                     
                                     {selectedDispute.admin_notes && (selectedDispute.status === 'Resolved' || selectedDispute.status === 'Dismissed') && (
                                         <div style={{ marginTop: '1rem', paddingTop: '1rem', borderTop: '1px solid #e2e8f0' }}>
                                             <span style={{ fontWeight: 'bold', fontSize: '0.8rem', color: '#64748b' }}>RESOLUTION NOTES: </span>
                                             <span style={{ fontSize: '0.9rem' }}>{selectedDispute.admin_notes}</span>
                                         </div>
                                     )}

                                     {selectedDispute.admin_notes && selectedDispute.status !== 'Resolved' && selectedDispute.status !== 'Dismissed' && (
                                         <div style={{ marginTop: '1rem', paddingTop: '1rem', borderTop: '1px solid #e2e8f0' }}>
                                             <span style={{ fontWeight: 'bold', fontSize: '0.8rem', color: '#64748b' }}>MODERATOR NOTES: </span>
                                             <span style={{ fontSize: '0.9rem' }}>{selectedDispute.admin_notes}</span>
                                         </div>
                                     )}

                                     {selectedDispute.evidence_urls && selectedDispute.evidence_urls.length > 0 && (
                                         <div style={{ marginTop: '1.5rem', paddingTop: '1.5rem', borderTop: '1px solid #e2e8f0' }}>
                                             <span style={{ fontWeight: 'bold', fontSize: '0.8rem', color: '#64748b', display: 'block', marginBottom: '8px' }}>EVIDENCE ATTACHMENTS</span>
                                             <div className="flex gap-4" style={{ flexWrap: 'wrap' }}>
                                                 {selectedDispute.evidence_urls.map((url, i) => (
                                                     <div 
                                                         key={i} 
                                                         style={{ width: '80px', height: '80px', borderRadius: '8px', overflow: 'hidden', border: '1px solid var(--border)', cursor: 'zoom-in', transition: 'transform 0.2s' }}
                                                         onClick={() => setLightboxImage(`http://localhost:3000${url}`)}
                                                         onMouseEnter={e => e.currentTarget.style.transform = 'scale(1.05)'}
                                                         onMouseLeave={e => e.currentTarget.style.transform = 'scale(1)'}
                                                     >
                                                         <img src={`http://localhost:3000${url}`} alt={`Evidence ${i+1}`} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                                                     </div>
                                                 ))}
                                             </div>
                                         </div>
                                     )}
                                 </div>
                                 
                                  <div className="card" style={{ padding: '1.5rem' }}>
                                      <h3 style={{ margin: '0 0 1.25rem 0', borderBottom: '1px solid var(--border)', paddingBottom: '0.5rem' }}>Transaction & Listing Details</h3>
                                      
                                      {/* Product Detail Header */}
                                      {selectedDispute.transaction?.product && (
                                          <div style={{ display: 'flex', gap: '1rem', alignItems: 'center', marginBottom: '1.5rem', background: '#f8fafc', padding: '12px', borderRadius: '12px' }}>
                                              {selectedDispute.transaction.product.image_urls && selectedDispute.transaction.product.image_urls.length > 0 ? (
                                                  <img 
                                                      src={`http://localhost:3000${selectedDispute.transaction.product.image_urls[0]}`} 
                                                      alt="Product" 
                                                      style={{ width: '64px', height: '64px', objectFit: 'cover', borderRadius: '8px', border: '1px solid var(--border)' }} 
                                                  />
                                              ) : (
                                                  <div style={{ width: '64px', height: '64px', background: '#e2e8f0', borderRadius: '8px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#64748b' }}>No Img</div>
                                              )}
                                              <div>
                                                  <h4 style={{ margin: '0 0 4px 0', fontSize: '1rem', fontWeight: 'bold' }}>{selectedDispute.transaction.product.title}</h4>
                                                  <div style={{ display: 'flex', gap: '12px', fontSize: '0.85rem' }}>
                                                      <span style={{ color: 'var(--text-muted)' }}>Condition: <strong style={{ color: 'var(--text)' }}>{selectedDispute.transaction.product.condition}</strong></span>
                                                      <span style={{ color: 'var(--text-muted)' }}>Price: <strong style={{ color: 'var(--success)', fontWeight: 'bold' }}>RM {selectedDispute.transaction.product.price}</strong></span>
                                                  </div>
                                              </div>
                                          </div>
                                      )}

                                      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '1.5rem' }}>
                                          {/* Deal Details */}
                                          <div>
                                              <span style={{ fontWeight: 'bold', fontSize: '0.75rem', color: '#64748b', display: 'block', textTransform: 'uppercase', marginBottom: '6px' }}>Deal Details</span>
                                              <div style={{ display: 'flex', flexDirection: 'column', gap: '4px', fontSize: '0.9rem' }}>
                                                  <div><strong>Transaction ID:</strong> TRX-{selectedDispute.transaction_id.substring(0, 8).toUpperCase()}</div>
                                                  <div><strong>Amount Paid:</strong> RM {selectedDispute.transaction?.amount}</div>
                                                  {selectedDispute.transaction?.meetup_location && (
                                                      <div><strong>Meetup Location:</strong> {selectedDispute.transaction.meetup_location}</div>
                                                  )}
                                                  {selectedDispute.transaction?.scheduled_at && (
                                                      <div><strong>Meetup Date/Time:</strong> {new Date(selectedDispute.transaction.scheduled_at).toLocaleString()}</div>
                                                  )}
                                                  {selectedDispute.transaction?.rental_start_date && (
                                                      <div><strong>Rental Period:</strong> {new Date(selectedDispute.transaction.rental_start_date).toLocaleDateString()} - {new Date(selectedDispute.transaction.rental_end_date).toLocaleDateString()}</div>
                                                  )}
                                              </div>
                                          </div>

                                          {/* Parties Details */}
                                          <div>
                                              <span style={{ fontWeight: 'bold', fontSize: '0.75rem', color: '#64748b', display: 'block', textTransform: 'uppercase', marginBottom: '6px' }}>Parties Involved</span>
                                              <div style={{ display: 'flex', flexDirection: 'column', gap: '4px', fontSize: '0.9rem' }}>
                                                  <div>
                                                      <strong>Buyer:</strong> {selectedDispute.transaction?.buyer?.full_name || 'N/A'} 
                                                      <span style={{ color: 'var(--text-muted)', fontSize: '0.8rem', display: 'block' }}>({selectedDispute.transaction?.buyer?.email || 'N/A'})</span>
                                                  </div>
                                                  <div style={{ marginTop: '4px' }}>
                                                      <strong>Seller:</strong> {selectedDispute.transaction?.seller?.full_name || 'N/A'} 
                                                      <span style={{ color: 'var(--text-muted)', fontSize: '0.8rem', display: 'block' }}>({selectedDispute.transaction?.seller?.email || 'N/A'})</span>
                                                  </div>
                                                  <div style={{ marginTop: '4px', fontSize: '0.85rem' }}>
                                                      <strong>Complainant:</strong> <span style={{ color: 'var(--danger)', fontWeight: 'bold' }}>
                                                          {selectedDispute.complainant?.id === selectedDispute.transaction?.buyer_id ? 'Buyer' : 'Seller'}
                                                      </span>
                                                  </div>
                                              </div>
                                          </div>
                                      </div>
                                  </div>

                                 {/* Chat Thread */}
                                 <div className="card" style={{ display: 'flex', flexDirection: 'column', height: '400px' }}>
                                     <h3 style={{ margin: '0 0 1rem 0', fontSize: '1.1rem' }}>Dispute Chat Thread</h3>
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
                                                             {msg.content}
                                                         </div>
                                                         <span style={{ fontSize: '0.65rem', color: '#94a3b8', marginTop: '2px' }}>
                                                             {new Date(msg.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                                                         </span>
                                                     </div>
                                                 );
                                             })
                                         )}
                                     </div>
                                      {selectedDispute.status === 'Resolved' || selectedDispute.status === 'Dismissed' ? (
                                           <div style={{ textAlign: 'center', padding: '12px', background: '#f1f5f9', borderRadius: '8px', color: '#64748b', fontWeight: '500', fontSize: '0.9rem' }}>
                                               🔒 This dispute is resolved and closed.
                                           </div>
                                      ) : (['Escalated', 'Escalated to Admin'].includes(selectedDispute.status) && isModerator) ? (
                                           <div style={{ textAlign: 'center', padding: '12px', background: '#fff7ed', borderRadius: '8px', color: '#ea580c', fontWeight: '500', fontSize: '0.9rem' }}>
                                               🔒 Escalated to Administrator. Chat is locked for Moderators.
                                           </div>
                                      ) : (
                                           <form onSubmit={handleSendChatMessage} className="flex gap-2">
                                               <input 
                                                   type="text" 
                                                   className="input" 
                                                   value={chatInput} 
                                                   onChange={e => setChatInput(e.target.value)} 
                                                   placeholder="Type a message to participants..."
                                                   style={{ margin: 0, flex: 1 }}
                                               />
                                               <button type="submit" className="btn" style={{ padding: '0 1.5rem' }}>Send</button>
                                           </form>
                                      )}
                                 </div>
                             </div>

                             {/* Actions Column */}
                             <div style={{ flex: 2 }} className="flex-col gap-6">
                                 <div className="card">
                                     <h3 style={{ margin: '0 0 1rem 0', fontSize: '1.2rem' }}>Actions</h3>
                                     
                                     {selectedDispute.status === 'Resolved' || selectedDispute.status === 'Dismissed' ? (
                                         <div style={{ padding: '16px', background: '#f8fafc', borderRadius: '12px', border: '1px solid var(--border)' }}>
                                             <div style={{ display: 'flex', gap: '8px', alignItems: 'center', marginBottom: '12px' }}>
                                                 <CheckCircle size={18} color="var(--success)" />
                                                 <strong style={{ fontSize: '1rem', color: 'var(--text-main)' }}>Dispute Resolved</strong>
                                             </div>
                                             {selectedDispute.handler && (
                                                 <div style={{ fontSize: '0.9rem', marginBottom: '8px' }}>
                                                     <strong>Processed By:</strong> <span style={{ color: 'var(--text-main)', fontWeight: 'bold' }}>{selectedDispute.handler.full_name} ({selectedDispute.handler.role})</span>
                                                 </div>
                                             )}
                                             <div style={{ fontSize: '0.9rem', color: 'var(--text-muted)', lineHeight: '1.5' }}>
                                                 <strong>Resolution Details:</strong>
                                                 <p style={{ marginTop: '4px', fontStyle: 'italic', background: 'white', padding: '8px 12px', borderRadius: '6px', border: '1px solid #e2e8f0', color: 'var(--text-main)' }}>
                                                     {selectedDispute.admin_notes || 'No resolution notes provided.'}
                                                 </p>
                                             </div>
                                         </div>
                                     ) : (['Escalated', 'Escalated to Admin'].includes(selectedDispute.status) && isModerator) ? (
                                          <div style={{ padding: '16px', background: '#f8fafc', borderRadius: '12px', border: '1px solid var(--border)' }}>
                                              <div style={{ display: 'flex', gap: '8px', alignItems: 'center', marginBottom: '12px' }}>
                                                  <Flame size={18} color="#ea580c" />
                                                  <strong style={{ fontSize: '1rem', color: 'var(--text-main)' }}>Escalated to Admin</strong>
                                              </div>
                                              {selectedDispute.handler && (
                                                  <div style={{ fontSize: '0.9rem', marginBottom: '8px' }}>
                                                      <strong>Escalated By:</strong> <span style={{ color: 'var(--text-main)', fontWeight: 'bold' }}>{selectedDispute.handler.full_name} ({selectedDispute.handler.role})</span>
                                                  </div>
                                              )}
                                              <div style={{ fontSize: '0.9rem', color: 'var(--text-muted)', lineHeight: '1.5' }}>
                                                  <strong>Moderator Notes:</strong>
                                                  <p style={{ marginTop: '4px', fontStyle: 'italic', background: 'white', padding: '8px 12px', borderRadius: '6px', border: '1px solid #e2e8f0', color: 'var(--text-main)' }}>
                                                      {selectedDispute.admin_notes || 'No notes provided.'}
                                                  </p>
                                              </div>
                                          </div>
                                     ) : (
                                         <>
                                              <div style={{ marginBottom: '1.5rem' }}>
                                                  <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-muted)', fontSize: '0.875rem' }}>Notes</label>
                                                  <textarea 
                                                      className="input" 
                                                      rows="4" 
                                                      value={notes}
                                                      onChange={(e) => setNotes(e.target.value)}
                                                      placeholder="Document findings or reasoning..."
                                                      style={{ resize: 'vertical', width: '100%' }}
                                                  ></textarea>
                                              </div>
 
                                              {/* Moderator Triage (Hide if already escalated) */}
                                              {!['Escalated', 'Escalated to Admin'].includes(selectedDispute.status) && (
                                                  <div style={{ marginBottom: '2rem', paddingBottom: '1.5rem', borderBottom: '1px solid var(--border)' }}>
                                                      <h4 style={{ margin: '0 0 12px 0', color: 'var(--text-muted)' }}>Moderator Triage</h4>
                                                      <select className="input" value={modAction} onChange={(e) => setModAction(e.target.value)} style={{ width: '100%', marginBottom: '12px' }}>
                                                          <option value="Investigate">Keep Investigating</option>
                                                          {currentUser?.role !== 'admin' && (
                                                              <option value="Escalate">Escalate to Admin</option>
                                                          )}
                                                          <option value="Dismiss">Dismiss (Invalid)</option>
                                                      </select>
                                                      <button className="btn btn-outline" style={{ width: '100%' }} onClick={handleModTriage}>
                                                          Apply Triage Action
                                                      </button>
                                                  </div>
                                              )}
 
                                              {/* Admin Actions */}
                                              <div style={{ opacity: currentUser?.role === 'admin' ? 1 : 0.4, pointerEvents: currentUser?.role === 'admin' ? 'auto' : 'none' }}>
                                                  <h4 style={{ margin: '0 0 12px 0', color: 'var(--danger)' }}>Admin Arbitration</h4>
                                                  
                                                  <div style={{ marginBottom: '1.2rem' }}>
                                                      <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-muted)', fontSize: '0.875rem' }}>Action on Loser</label>
                                                      <select className="input" value={actionOnLoser} onChange={(e) => setActionOnLoser(e.target.value)} style={{ width: '100%', marginBottom: 0, appearance: 'auto' }}>
                                                          <option value="none">No Action</option>
                                                          <option value="warn">Warn (Reputation Penalty)</option>
                                                          <option value="ban">Ban (Deactivate Account)</option>
                                                      </select>
                                                  </div>
 
                                                  <div className="flex gap-4">
                                                      <button 
                                                          className="flex-1 btn" 
                                                          style={{ background: '#2563eb', padding: '1rem 0', display: 'flex', flexDirection: 'column' }}
                                                          onClick={() => handleAdminArbitrate('Buyer')}
                                                          disabled={!['Escalated', 'Escalated to Admin'].includes(selectedDispute.status)}
                                                      >
                                                          <div>Favor Buyer</div>
                                                          <div style={{ fontSize: '0.7rem', fontWeight: 'normal', opacity: 0.8 }}>(Refund)</div>
                                                      </button>
                                                      <button 
                                                          className="flex-1 btn" 
                                                          style={{ background: '#16a34a', padding: '1rem 0', display: 'flex', flexDirection: 'column' }}
                                                          onClick={() => handleAdminArbitrate('Seller')}
                                                          disabled={!['Escalated', 'Escalated to Admin'].includes(selectedDispute.status)}
                                                      >
                                                          <div>Favor Seller</div>
                                                          <div style={{ fontSize: '0.7rem', fontWeight: 'normal', opacity: 0.8 }}>(Release Funds)</div>
                                                      </button>
                                                  </div>
                                              </div>
                                         </>
                                     )}
                                 </div>
                             </div>
                        </div>
                    </>
                )}
            </div>

            {/* Evidence Image Lightbox Modal */}
            {lightboxImage && (
                <div 
                    onClick={() => setLightboxImage(null)}
                    style={{
                        position: 'fixed',
                        top: 0,
                        left: 0,
                        width: '100vw',
                        height: '100vh',
                        backgroundColor: 'rgba(15, 23, 42, 0.85)',
                        backdropFilter: 'blur(8px)',
                        zIndex: 9999,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        cursor: 'zoom-out',
                        animation: 'fadeIn 0.25s ease-out'
                    }}
                >
                    <img 
                        src={lightboxImage} 
                        alt="Enlarged evidence" 
                        style={{
                            maxWidth: '90%',
                            maxHeight: '90%',
                            borderRadius: '16px',
                            boxShadow: '0 25px 50px -12px rgba(0,0,0,0.5)',
                            border: '1px solid rgba(255,255,255,0.1)',
                            cursor: 'default'
                        }} 
                        onClick={e => e.stopPropagation()}
                    />
                </div>
            )}
        </div>
    );
};

export default Dispute;
