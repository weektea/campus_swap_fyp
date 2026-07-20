import React, { useState, useEffect } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { AlertTriangle, CheckCircle } from 'lucide-react';
import api, { IMAGE_BASE_URL } from '../services/api';

const Reports = () => {
    const location = useLocation();
    const navigate = useNavigate();
    const [allReports, setAllReports] = useState([]);
    const [activeTab, setActiveTab] = useState('Pending'); // Pending | History
    const [selectedReport, setSelectedReport] = useState(null);
    const [lightboxImage, setLightboxImage] = useState(null);
    const [loading, setLoading] = useState(true);
    const [modNotes, setModNotes] = useState('');
    const [action, setAction] = useState('Dismissed'); // Dismissed, Uphold, Escalated
    const [currentUser, setCurrentUser] = useState(null);
    const [privateTranscript, setPrivateTranscript] = useState(null);
    const [loadingTranscript, setLoadingTranscript] = useState(false);
    const [showTranscriptModal, setShowTranscriptModal] = useState(false);

    const fetchPrivateTranscript = async () => {
        const reporterId = selectedReport?.raw?.reporter_id;
        const reportedUserId = selectedReport?.raw?.reported_user_id;
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
        fetchReports();
    }, [location]);

    const pendingReports = allReports.filter(r => ['Pending', 'In-Progress', 'Escalated'].includes(r.status));
    const historyReports = allReports.filter(r => ['Uphold', 'Dismissed'].includes(r.status));
    const displayedReports = activeTab === 'Pending' ? pendingReports : historyReports;
    const isModerator = currentUser?.role === 'moderator';

    const fetchReports = async () => {
        setLoading(true);
        try {
            const res = await api.get('/admin/reports');
            const data = res.data.map(r => ({
                id: `REP-${r.id}`,
                realId: r.id,
                target: r.product 
                    ? `Listing: ${r.product.title}` 
                    : (r.reported_user ? `User: ${r.reported_user.full_name} (@${r.reported_user.email})` : 'General'),
                content: r.description,
                submittedAt: r.createdAt,
                status: r.status,
                raw: r
            }));

            data.sort((a, b) => new Date(b.submittedAt) - new Date(a.submittedAt));
            setAllReports(data);

            // Pre-select if navigated from dashboard
            const targetId = location.state?.selectedId;
            if (targetId) {
                const found = data.find(r => r.realId === targetId);
                if (found) {
                    setSelectedReport(found);
                    setModNotes(found.raw.admin_notes || '');
                    setAction(found.status === 'Pending' || found.status === 'In-Progress' || found.status === 'Escalated' ? 'Dismissed' : found.status);
                    if (['Uphold', 'Dismissed'].includes(found.status)) {
                        setActiveTab('History');
                    } else {
                        setActiveTab('Pending');
                    }
                } else {
                    const pending = data.filter(r => ['Pending', 'In-Progress', 'Escalated'].includes(r.status));
                    if (pending.length > 0) {
                        setSelectedReport(pending[0]);
                        setActiveTab('Pending');
                    }
                }
            } else {
                const pending = data.filter(r => ['Pending', 'In-Progress', 'Escalated'].includes(r.status));
                if (pending.length > 0 && !selectedReport) {
                    setSelectedReport(pending[0]);
                    setActiveTab('Pending');
                }
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
                {/* Tab Switcher */}
                <div style={{ display: 'flex', borderBottom: '1px solid var(--border)', marginBottom: '12px' }}>
                    <button
                        onClick={() => { setActiveTab('Pending'); setSelectedReport(pendingReports[0] || null); }}
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
                        Pending ({pendingReports.length})
                    </button>
                    <button
                        onClick={() => { setActiveTab('History'); setSelectedReport(historyReports[0] || null); }}
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
                        History ({historyReports.length})
                    </button>
                </div>

                {displayedReports.map(report => (
                    <div 
                        key={report.id}
                        onClick={() => { 
                            setSelectedReport(report); 
                            setModNotes(report.raw.admin_notes || ''); 
                            setAction(report.status === 'Pending' || report.status === 'In-Progress' || report.status === 'Escalated' ? 'Dismissed' : report.status); 
                        }}
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
                {displayedReports.length === 0 && <div style={{ color: 'var(--text-muted)', textAlign: 'center', marginTop: '2rem' }}>No {activeTab.toLowerCase()} reports.</div>}
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
                                        <div style={{ width: '120px', height: '120px', background: '#f3f4f6', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#9ca3af', overflow: 'hidden', border: '1px solid var(--border)' }}>
                                            {selectedReport.raw.product.image_urls && selectedReport.raw.product.image_urls[0] ? (
                                                <img 
                                                    src={`${IMAGE_BASE_URL}${selectedReport.raw.product.image_urls[0]}`} 
                                                    alt="Product" 
                                                    style={{ width: '100%', height: '100%', objectFit: 'cover', cursor: 'zoom-in', transition: 'transform 0.2s' }} 
                                                    onClick={() => setLightboxImage(`${IMAGE_BASE_URL}${selectedReport.raw.product.image_urls[0]}`)}
                                                    onMouseEnter={e => e.currentTarget.style.transform = 'scale(1.05)'}
                                                    onMouseLeave={e => e.currentTarget.style.transform = 'scale(1)'}
                                                />
                                            ) : (
                                                'No Image'
                                            )}
                                        </div>
                                        <div>
                                            <h3 style={{ margin: '0 0 8px 0', fontSize: '1.25rem' }}>{selectedReport.raw.product.title}</h3>
                                            <div style={{ color: 'var(--text-muted)', marginBottom: '4px' }}>Price: RM {selectedReport.raw.product.price}</div>
                                            <div style={{ color: 'var(--text-muted)', marginBottom: '4px' }}>Condition: {selectedReport.raw.product.condition}</div>
                                            <div style={{ color: 'var(--text-muted)', marginBottom: '8px' }}>Seller ID: {selectedReport.raw.product.seller_id}</div>
                                            <button 
                                                className="btn" 
                                                style={{ padding: '6px 12px', fontSize: '0.8rem', background: 'var(--primary)', color: 'white', border: 'none' }}
                                                onClick={() => navigate('/listings', { state: { selectedId: selectedReport.raw.product_id } })}
                                            >
                                                🔍 View Listing & Student Profile
                                            </button>
                                        </div>
                                    </div>
                                )}
                                {selectedReport.raw.reported_user && (
                                    <div className="flex gap-6 mb-6" style={{ background: '#f0f9ff', padding: '16px', borderRadius: '12px', border: '1px solid #bae6fd' }}>
                                        <div style={{ width: '120px', height: '120px', background: '#e0f2fe', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#0284c7', overflow: 'hidden', border: '1px solid #bae6fd', fontSize: '2.5rem', fontWeight: 'bold' }}>
                                            {selectedReport.raw.reported_user.profile_image_url ? (
                                                <img 
                                                    src={`${IMAGE_BASE_URL}${selectedReport.raw.reported_user.profile_image_url}`} 
                                                    alt="User Avatar" 
                                                    style={{ width: '100%', height: '100%', objectFit: 'cover' }} 
                                                />
                                            ) : (
                                                selectedReport.raw.reported_user.full_name[0].toUpperCase()
                                            )}
                                        </div>
                                        <div style={{ display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
                                            <span style={{ fontSize: '0.75rem', color: '#0369a1', fontWeight: 'bold', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Reported User</span>
                                            <h3 style={{ margin: '4px 0 8px 0', fontSize: '1.25rem', color: '#0f172a' }}>{selectedReport.raw.reported_user.full_name}</h3>
                                            <div style={{ color: '#475569', marginBottom: '4px', fontSize: '0.9rem' }}>Email: {selectedReport.raw.reported_user.email}</div>
                                            <div style={{ color: '#475569', marginBottom: '4px', fontSize: '0.9rem' }}>Reputation: <span style={{ fontWeight: 'bold', color: '#ca8a04' }}>★ {parseFloat(selectedReport.raw.reported_user.reputation_score || 0).toFixed(1)}</span> ({selectedReport.raw.reported_user.total_reviews || 0} reviews)</div>
                                            <div style={{ color: '#475569', marginBottom: '8px', fontSize: '0.9rem' }}>User ID: {selectedReport.raw.reported_user_id}</div>
                                            <button 
                                                className="btn" 
                                                style={{ padding: '6px 12px', fontSize: '0.8rem', background: '#0284c7', color: 'white', border: 'none', width: 'fit-content' }}
                                                onClick={() => navigate('/users', { state: { selectedId: selectedReport.raw.reported_user_id } })}
                                            >
                                                🔍 View Student Details
                                            </button>
                                        </div>
                                    </div>
                                )}
                                <div className="flex gap-4 items-start mb-4 bg-gray-50 p-4 rounded-lg">
                                    <AlertTriangle color="var(--danger)" />
                                    <div>
                                        <div style={{ fontWeight: 'bold', marginBottom: '8px' }}>Reporter's Claim (Violation Type: {selectedReport.raw.violation_type}): </div>
                                        <div style={{ lineHeight: 1.6 }}>{selectedReport.content}</div>
                                    </div>
                                </div>
                                {selectedReport.raw.evidence_urls && selectedReport.raw.evidence_urls.length > 0 && (
                                    <div style={{ marginTop: '1.5rem', paddingTop: '1.5rem', borderTop: '1px solid #e2e8f0', marginBottom: '1rem' }}>
                                        <span style={{ fontWeight: 'bold', fontSize: '0.8rem', color: '#64748b', display: 'block', marginBottom: '8px' }}>REPORT EVIDENCE IMAGES</span>
                                        <div className="flex gap-4" style={{ flexWrap: 'wrap' }}>
                                            {selectedReport.raw.evidence_urls.map((url, i) => (
                                                <div 
                                                    key={i} 
                                                    style={{ width: '80px', height: '80px', borderRadius: '8px', overflow: 'hidden', border: '1px solid var(--border)', cursor: 'zoom-in', transition: 'transform 0.2s' }}
                                                    onClick={() => setLightboxImage(`${IMAGE_BASE_URL}${url}`)}
                                                    onMouseEnter={e => e.currentTarget.style.transform = 'scale(1.05)'}
                                                    onMouseLeave={e => e.currentTarget.style.transform = 'scale(1)'}
                                                >
                                                    <img src={`${IMAGE_BASE_URL}${url}`} alt={`Evidence ${i+1}`} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                                                </div>
                                            ))}
                                        </div>
                                    </div>
                                )}
                                {selectedReport.raw.reporter && (
                                    <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginTop: '1rem' }}>
                                        Reported by: {selectedReport.raw.reporter.email}
                                    </div>
                                )}
                                {selectedReport.raw.reporter_id && selectedReport.raw.reported_user_id && (
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

                        {/* Action Terminal */}
                        <div className="card" style={{ flex: 2 }}>
                            <h2 style={{ margin: '0 0 1.5rem 0', fontSize: '1.25rem' }}>Moderation Terminal</h2>
                            {['Uphold', 'Dismissed'].includes(selectedReport.status) || (selectedReport.status === 'Escalated' && isModerator) ? (
                                <div style={{ padding: '16px', background: '#f8fafc', borderRadius: '12px', border: '1px solid var(--border)' }}>
                                    <div style={{ display: 'flex', gap: '8px', alignItems: 'center', marginBottom: '12px' }}>
                                        {selectedReport.status === 'Escalated' ? (
                                            <>
                                                <AlertTriangle size={18} color="#eab308" />
                                                <strong style={{ fontSize: '1rem', color: 'var(--text-main)' }}>Escalated to Administrator</strong>
                                            </>
                                        ) : (
                                            <>
                                                <CheckCircle size={18} color="var(--success)" />
                                                <strong style={{ fontSize: '1rem', color: 'var(--text-main)' }}>Report Resolved</strong>
                                            </>
                                        )}
                                    </div>
                                    <div style={{ fontSize: '0.9rem', marginBottom: '8px' }}>
                                        <strong>Action/Status:</strong> <span style={{ color: selectedReport.status === 'Uphold' ? 'var(--danger)' : selectedReport.status === 'Escalated' ? '#eab308' : 'var(--primary)', fontWeight: 'bold' }}>{selectedReport.status === 'Uphold' ? 'Uphold & Suspend' : selectedReport.status === 'Escalated' ? 'Escalated' : 'Dismissed'}</span>
                                    </div>
                                    {selectedReport.raw.handler && (
                                        <div style={{ fontSize: '0.9rem', marginBottom: '8px' }}>
                                            <strong>Processed By:</strong> <span style={{ color: 'var(--text-main)', fontWeight: 'bold' }}>{selectedReport.raw.handler.full_name} ({selectedReport.raw.handler.role})</span>
                                        </div>
                                    )}
                                    <div style={{ fontSize: '0.9rem', color: 'var(--text-muted)', lineHeight: '1.5' }}>
                                        <strong>Internal Notes:</strong>
                                        <p style={{ marginTop: '4px', fontStyle: 'italic', background: 'white', padding: '8px 12px', borderRadius: '6px', border: '1px solid #e2e8f0', color: 'var(--text-main)' }}>
                                            {selectedReport.raw.admin_notes || 'No notes provided.'}
                                        </p>
                                    </div>
                                </div>
                            ) : (
                                <>
                                    <div style={{ marginBottom: '1.5rem' }}>
                                        <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-muted)', fontSize: '0.875rem' }}>Action Type</label>
                                        <select className="input" value={action} onChange={(e) => setAction(e.target.value)} style={{ marginBottom: 0, appearance: 'auto', width: '100%' }}>
                                            <option value="Dismissed">Dismiss Report</option>
                                            <option value="Uphold">Uphold & Suspend Listing</option>
                                            {currentUser?.role !== 'admin' && selectedReport.status !== 'Escalated' && (
                                                <option value="Escalated">Escalate to Admin</option>
                                            )}
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
                                </>
                            )}
                        </div>
                    </div>
                )}
            </div>

            {/* Image Lightbox Modal */}
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
                        alt="Enlarged view" 
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
                                    const isReporter = msg.sender_id === selectedReport.raw.reporter_id;
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
                                                {isReporter ? `Reporter (${selectedReport.raw.reporter?.username || 'Reporter'})` : `Reported User (${selectedReport.raw.reported_user?.username || 'Reported'})`}
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

export default Reports;
