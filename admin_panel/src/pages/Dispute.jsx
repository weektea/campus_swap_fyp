import React, { useState, useEffect } from 'react';
import { Flame, Info, CheckCircle } from 'lucide-react';
import api from '../services/api';

const Dispute = () => {
    const [disputes, setDisputes] = useState([]);
    const [selectedDispute, setSelectedDispute] = useState(null);
    const [loading, setLoading] = useState(true);
    const [notes, setNotes] = useState('');
    const [modAction, setModAction] = useState('Investigate'); // Dismiss, Investigate, Escalate
    
    const [currentUser, setCurrentUser] = useState(null);

    useEffect(() => {
        const userStr = localStorage.getItem('user');
        if (userStr) setCurrentUser(JSON.parse(userStr));
        fetchDisputes();
    }, []);

    const fetchDisputes = async () => {
        setLoading(true);
        try {
            const res = await api.get('/admin/disputes');
            const data = res.data.filter(d => d.status !== 'Resolved' && d.status !== 'Dismissed');
            data.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
            setDisputes(data);
            if (data.length > 0 && !selectedDispute) {
                setSelectedDispute(data[0]);
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
        if (selectedDispute.status !== 'Escalated') {
            alert('Only escalated disputes can be arbitrated by an Admin.');
            return;
        }
        try {
            await api.put(`/disputes/${selectedDispute.id}/arbitrate`, {
                winning_party: winner,
                admin_notes: notes
            });
            alert(`Dispute resolved in favor of ${winner}!`);
            setNotes('');
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
                <h3 style={{ margin: '0 0 1rem 0' }}>Open Disputes ({disputes.length})</h3>
                {disputes.map(dispute => (
                    <div 
                        key={dispute.id}
                        onClick={() => { setSelectedDispute(dispute); setNotes(''); }}
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
                            <span style={{ fontWeight: 'bold', fontSize: '0.875rem' }}>DSP-{dispute.id}</span>
                            <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>{new Date(dispute.createdAt).toLocaleDateString()}</span>
                        </div>
                        <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                            Transaction: TRX-{dispute.transaction_id}
                        </div>
                        <div>
                            <span style={{ 
                                padding: '2px 6px', 
                                background: dispute.status === 'Escalated' ? '#fee2e2' : '#fef3c7', 
                                color: dispute.status === 'Escalated' ? '#991b1b' : '#92400e',
                                borderRadius: '4px', fontSize: '0.7rem', fontWeight: 'bold' 
                            }}>
                                {dispute.status}
                            </span>
                        </div>
                    </div>
                ))}
                {disputes.length === 0 && <div style={{ color: 'var(--text-muted)', textAlign: 'center', marginTop: '2rem' }}>No open disputes.</div>}
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
                            {/* Details Column */}
                            <div style={{ flex: 3 }} className="flex-col gap-8">
                                {/* Dispute Notes / Content */}
                                <div style={{ background: '#f8fafc', padding: '1.5rem', borderRadius: '16px', marginBottom: '2rem' }}>
                                    <div style={{ fontSize: '0.75rem', fontWeight: 'bold', color: '#64748b', letterSpacing: '1px', marginBottom: '1rem' }}>
                                        DISPUTE REASON
                                    </div>
                                    <h3 style={{ margin: '0 0 8px 0', color: 'var(--danger)' }}>{selectedDispute.reason}</h3>
                                    <p style={{ margin: 0, lineHeight: 1.6 }}>
                                        {selectedDispute.description}
                                    </p>
                                    
                                    {selectedDispute.admin_notes && (
                                        <div style={{ marginTop: '1rem', paddingTop: '1rem', borderTop: '1px solid #e2e8f0' }}>
                                            <span style={{ fontWeight: 'bold', fontSize: '0.8rem', color: '#64748b' }}>MODERATOR NOTES: </span>
                                            <span style={{ fontSize: '0.9rem' }}>{selectedDispute.admin_notes}</span>
                                        </div>
                                    )}
                                </div>
                                
                                <div className="card" style={{ padding: '1.5rem' }}>
                                    <h3 style={{ margin: '0 0 1rem 0' }}>Parties Involved</h3>
                                    <div className="flex gap-8">
                                        <div>
                                            <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Complainant (Initiated Dispute)</div>
                                            <div style={{ fontWeight: 'bold' }}>{selectedDispute.complainant?.email || 'User ID: ' + selectedDispute.complainant_id}</div>
                                        </div>
                                        <div>
                                            <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Transaction ID</div>
                                            <div style={{ fontWeight: 'bold' }}>TRX-{selectedDispute.transaction_id}</div>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            {/* Actions Column */}
                            <div style={{ flex: 2 }} className="flex-col gap-6">
                                <div className="card">
                                    <h3 style={{ margin: '0 0 1rem 0', fontSize: '1.2rem' }}>Actions</h3>
                                    
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

                                    {/* Moderator Actions */}
                                    <div style={{ marginBottom: '2rem', paddingBottom: '1.5rem', borderBottom: '1px solid var(--border)' }}>
                                        <h4 style={{ margin: '0 0 12px 0', color: 'var(--text-muted)' }}>Moderator Triage</h4>
                                        <select className="input" value={modAction} onChange={(e) => setModAction(e.target.value)} style={{ width: '100%', marginBottom: '12px' }}>
                                            <option value="Investigate">Keep Investigating</option>
                                            <option value="Escalate">Escalate to Admin</option>
                                            <option value="Dismiss">Dismiss (Invalid)</option>
                                        </select>
                                        <button className="btn btn-outline" style={{ width: '100%' }} onClick={handleModTriage}>
                                            Apply Triage Action
                                        </button>
                                    </div>

                                    {/* Admin Actions */}
                                    <div style={{ opacity: currentUser?.role === 'admin' ? 1 : 0.4, pointerEvents: currentUser?.role === 'admin' ? 'auto' : 'none' }}>
                                        <h4 style={{ margin: '0 0 12px 0', color: 'var(--danger)' }}>Admin Arbitration</h4>
                                        <div className="flex gap-4">
                                            <button 
                                                className="flex-1 btn" 
                                                style={{ background: '#2563eb', padding: '1rem 0', display: 'flex', flexDirection: 'column' }}
                                                onClick={() => handleAdminArbitrate('Buyer')}
                                                disabled={selectedDispute.status !== 'Escalated'}
                                            >
                                                <div>Favor Buyer</div>
                                                <div style={{ fontSize: '0.7rem', fontWeight: 'normal', opacity: 0.8 }}>(Refund)</div>
                                            </button>
                                            <button 
                                                className="flex-1 btn" 
                                                style={{ background: '#16a34a', padding: '1rem 0', display: 'flex', flexDirection: 'column' }}
                                                onClick={() => handleAdminArbitrate('Seller')}
                                                disabled={selectedDispute.status !== 'Escalated'}
                                            >
                                                <div>Favor Seller</div>
                                                <div style={{ fontSize: '0.7rem', fontWeight: 'normal', opacity: 0.8 }}>(Release Funds)</div>
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </>
                )}
            </div>
        </div>
    );
};

export default Dispute;
