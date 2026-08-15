import React, { useState, useEffect } from 'react';
import { Search, Trash2, CheckCircle2, AlertTriangle, ShieldAlert, Sparkles, Filter } from 'lucide-react';
import api from '../services/api';
import PaginationControls from '../components/PaginationControls';

const Reviews = () => {
    const [activeTab, setActiveTab] = useState('flagged'); // Default to flagged for immediate moderator attention
    const [reviews, setReviews] = useState([]);
    const [flaggedReviews, setFlaggedReviews] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [currentUser, setCurrentUser] = useState(null);
    const [actionLoading, setActionLoading] = useState(null);

    // Pagination & Sort states
    const [currentPage, setCurrentPage] = useState(1);
    const [pageSize, setPageSize] = useState(10);
    const [sortBy, setSortBy] = useState('newest');

    const sortOptions = [
        { label: 'Date: Newest First', value: 'newest' },
        { label: 'Date: Oldest First', value: 'oldest' },
        { label: 'Rating: High to Low', value: 'rating_desc' },
        { label: 'Rating: Low to High', value: 'rating_asc' }
    ];

    useEffect(() => {
        const userStr = localStorage.getItem('user');
        if (userStr) setCurrentUser(JSON.parse(userStr));
        fetchAllData();
    }, []);

    const fetchAllData = async () => {
        setLoading(true);
        try {
            const [allRes, flaggedRes] = await Promise.all([
                api.get('/admin/reviews'),
                api.get('/admin/flagged-reviews')
            ]);
            setReviews(allRes.data || []);
            setFlaggedReviews(flaggedRes.data || []);
        } catch (err) {
            console.error('Failed to fetch reviews:', err);
        } finally {
            setLoading(false);
        }
    };

    const handleApproveReview = async (id) => {
        const confirmApprove = window.confirm("Approve this review? It will be marked safe, published to public view, and calculated into the user's reputation score.");
        if (!confirmApprove) return;

        setActionLoading(id);
        try {
            await api.post(`/admin/reviews/${id}/approve`);
            await fetchAllData();
        } catch (err) {
            alert('Failed to approve review: ' + (err.response?.data?.error || err.message));
        } finally {
            setActionLoading(null);
        }
    };

    const handleDeleteReview = async (id) => {
        const confirmDelete = window.confirm("Are you sure you want to permanently delete this review? It will be removed from the database.");
        if (!confirmDelete) return;

        setActionLoading(id);
        try {
            await api.delete(`/admin/reviews/${id}`);
            await fetchAllData();
        } catch (err) {
            alert('Failed to delete review: ' + (err.response?.data?.error || err.message));
        } finally {
            setActionLoading(null);
        }
    };

    const currentDataset = activeTab === 'flagged' ? flaggedReviews : reviews;

    const filtered = currentDataset.filter(r => {
        const textMatch = (r.comment || '').toLowerCase().includes(searchTerm.toLowerCase());
        const reviewerMatch = (r.reviewer?.email || '' + r.reviewer?.username || '' + r.reviewer?.full_name || '').toLowerCase().includes(searchTerm.toLowerCase());
        const revieweeMatch = (r.reviewee?.email || '' + r.reviewee?.username || '' + r.reviewee?.full_name || '').toLowerCase().includes(searchTerm.toLowerCase());
        const flagMatch = (r.flag_reason || '').toLowerCase().includes(searchTerm.toLowerCase());
        return textMatch || reviewerMatch || revieweeMatch || flagMatch;
    });

    const sortedReviews = [...filtered].sort((a, b) => {
        if (sortBy === 'newest') return new Date(b.createdAt) - new Date(a.createdAt);
        if (sortBy === 'oldest') return new Date(a.createdAt) - new Date(b.createdAt);
        if (sortBy === 'rating_desc') return (parseFloat(b.rating) || 0) - (parseFloat(a.rating) || 0);
        if (sortBy === 'rating_asc') return (parseFloat(a.rating) || 0) - (parseFloat(b.rating) || 0);
        return 0;
    });

    const totalPages = Math.ceil(sortedReviews.length / pageSize) || 1;
    const paginatedReviews = sortedReviews.slice((currentPage - 1) * pageSize, currentPage * pageSize);

    const isAdmin = currentUser?.role === 'admin' || currentUser?.role === 'moderator';

    return (
        <div>
            {/* Header & NLP Auto-Moderation Banner */}
            <div className="flex justify-between items-center mb-6">
                <div>
                    <h1 style={{ fontSize: '1.6rem', fontWeight: 'bold', margin: 0, color: '#1e293b' }}>
                        Reviews & NLP Content Moderation
                    </h1>
                    <p style={{ color: '#64748b', fontSize: '0.9rem', marginTop: '4px' }}>
                        Automated sentiment analysis & toxicity detection filter for community trust protection.
                    </p>
                </div>

                <div style={{ display: 'flex', alignItems: 'center', background: 'white', border: '1px solid #cbd5e1', borderRadius: '10px', padding: '8px 16px', width: '320px', boxShadow: '0 1px 2px rgba(0,0,0,0.05)' }}>
                    <Search size={18} color="#94a3b8" style={{ marginRight: '8px' }} />
                    <input 
                        type="text" 
                        placeholder="Search comments, users, or flags..." 
                        value={searchTerm} 
                        onChange={(e) => { setSearchTerm(e.target.value); setCurrentPage(1); }} 
                        style={{ border: 'none', background: 'transparent', outline: 'none', width: '100%', fontSize: '0.9rem' }} 
                    />
                </div>
            </div>

            {/* Metrics Overview */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '16px', marginBottom: '24px' }}>
                <div style={{ background: 'white', borderRadius: '12px', padding: '16px 20px', border: '1px solid #e2e8f0', display: 'flex', alignItems: 'center', gap: '14px' }}>
                    <div style={{ width: '44px', height: '44px', borderRadius: '10px', background: '#fef2f2', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#ef4444' }}>
                        <ShieldAlert size={24} />
                    </div>
                    <div>
                        <div style={{ fontSize: '0.8rem', color: '#64748b', fontWeight: '600' }}>FLAGGED TOXIC REVIEWS</div>
                        <div style={{ fontSize: '1.5rem', fontWeight: 'bold', color: flaggedReviews.length > 0 ? '#ef4444' : '#10b981' }}>
                            {flaggedReviews.length}
                        </div>
                    </div>
                </div>

                <div style={{ background: 'white', borderRadius: '12px', padding: '16px 20px', border: '1px solid #e2e8f0', display: 'flex', alignItems: 'center', gap: '14px' }}>
                    <div style={{ width: '44px', height: '44px', borderRadius: '10px', background: '#ecfdf5', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#10b981' }}>
                        <CheckCircle2 size={24} />
                    </div>
                    <div>
                        <div style={{ fontSize: '0.8rem', color: '#64748b', fontWeight: '600' }}>TOTAL REVIEWS LOGGED</div>
                        <div style={{ fontSize: '1.5rem', fontWeight: 'bold', color: '#0f172a' }}>
                            {reviews.length}
                        </div>
                    </div>
                </div>

                <div style={{ background: 'white', borderRadius: '12px', padding: '16px 20px', border: '1px solid #e2e8f0', display: 'flex', alignItems: 'center', gap: '14px' }}>
                    <div style={{ width: '44px', height: '44px', borderRadius: '10px', background: '#eff6ff', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#3b82f6' }}>
                        <Sparkles size={24} />
                    </div>
                    <div>
                        <div style={{ fontSize: '0.8rem', color: '#64748b', fontWeight: '600' }}>NLP FILTER STATUS</div>
                        <div style={{ fontSize: '1rem', fontWeight: 'bold', color: '#2563eb', marginTop: '4px' }}>
                            Active (VADER + Profanity)
                        </div>
                    </div>
                </div>
            </div>

            {/* Tab Navigation */}
            <div style={{ display: 'flex', gap: '12px', borderBottom: '2px solid #e2e8f0', marginBottom: '20px' }}>
                <button
                    onClick={() => { setActiveTab('flagged'); setCurrentPage(1); }}
                    style={{
                        padding: '10px 20px',
                        fontWeight: 'bold',
                        fontSize: '0.95rem',
                        background: 'none',
                        border: 'none',
                        borderBottom: activeTab === 'flagged' ? '3px solid #ef4444' : '3px solid transparent',
                        color: activeTab === 'flagged' ? '#ef4444' : '#64748b',
                        cursor: 'pointer',
                        display: 'flex',
                        alignItems: 'center',
                        gap: '8px',
                        marginBottom: '-2px'
                    }}
                >
                    <AlertTriangle size={18} />
                    Flagged Toxic Reviews
                    {flaggedReviews.length > 0 && (
                        <span style={{ background: '#ef4444', color: 'white', fontSize: '0.75rem', padding: '2px 8px', borderRadius: '10px', fontWeight: 'bold' }}>
                            {flaggedReviews.length}
                        </span>
                    )}
                </button>

                <button
                    onClick={() => { setActiveTab('all'); setCurrentPage(1); }}
                    style={{
                        padding: '10px 20px',
                        fontWeight: 'bold',
                        fontSize: '0.95rem',
                        background: 'none',
                        border: 'none',
                        borderBottom: activeTab === 'all' ? '3px solid #0284c7' : '3px solid transparent',
                        color: activeTab === 'all' ? '#0284c7' : '#64748b',
                        cursor: 'pointer',
                        display: 'flex',
                        alignItems: 'center',
                        gap: '8px',
                        marginBottom: '-2px'
                    }}
                >
                    All Published Reviews ({reviews.length})
                </button>
            </div>

            {/* Reviews Table */}
            {loading ? (
                <div style={{ padding: '3rem', textAlign: 'center', color: '#64748b' }}>Loading reviews and NLP analysis...</div>
            ) : (
                <div className="card" style={{ padding: 0, overflow: 'hidden', border: '1px solid #e2e8f0', borderRadius: '12px' }}>
                    <table>
                        <thead>
                            <tr style={{ background: '#f8fafc', borderBottom: '1px solid #e2e8f0' }}>
                                <th style={{ width: '50px', textAlign: 'center' }}>NO.</th>
                                <th>DATE</th>
                                <th>RATING</th>
                                {activeTab === 'flagged' && <th>NLP TOXICITY & SENTIMENT</th>}
                                <th>COMMENT CONTENT</th>
                                <th>AUTHOR (FROM)</th>
                                <th>TARGET (TO)</th>
                                {isAdmin && <th style={{ textAlign: 'center' }}>ACTIONS</th>}
                            </tr>
                        </thead>
                        <tbody>
                            {paginatedReviews.map((r, index) => (
                                <tr key={r.id} style={{ background: r.is_toxic ? '#fff5f5' : 'white', borderBottom: '1px solid #f1f5f9' }}>
                                    <td style={{ textAlign: 'center', fontWeight: 'bold', color: '#94a3b8' }}>
                                        {(currentPage - 1) * pageSize + index + 1}
                                    </td>
                                    <td style={{ fontSize: '0.8rem', color: '#64748b', whiteSpace: 'nowrap' }}>
                                        {new Date(r.createdAt).toLocaleDateString()}
                                    </td>
                                    <td>
                                        <div style={{ display: 'inline-flex', alignItems: 'center', gap: '4px', fontWeight: 'bold', color: r.rating >= 4 ? '#16a34a' : r.rating <= 2 ? '#dc2626' : '#d97706' }}>
                                            <span>★</span> {r.rating} / 5
                                        </div>
                                    </td>

                                    {activeTab === 'flagged' && (
                                        <td>
                                            <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
                                                <span style={{ 
                                                    display: 'inline-block',
                                                    padding: '2px 8px',
                                                    borderRadius: '6px',
                                                    fontSize: '0.75rem',
                                                    fontWeight: 'bold',
                                                    background: r.sentiment_score < 0 ? '#fee2e2' : '#fef3c7',
                                                    color: r.sentiment_score < 0 ? '#991b1b' : '#92400e',
                                                    border: '1px solid ' + (r.sentiment_score < 0 ? '#fca5a5' : '#fde68a')
                                                }}>
                                                    Score: {r.sentiment_score?.toFixed(2) || '0.00'} (Toxic)
                                                </span>
                                                {r.flag_reason && (
                                                    <span style={{ fontSize: '0.75rem', color: '#b91c1c', fontWeight: '600' }}>
                                                        {r.flag_reason}
                                                    </span>
                                                )}
                                            </div>
                                        </td>
                                    )}

                                    <td style={{ maxWidth: '320px' }}>
                                        <div style={{ 
                                            background: r.is_toxic ? '#fef2f2' : 'transparent',
                                            padding: r.is_toxic ? '6px 10px' : '0',
                                            borderRadius: '6px',
                                            border: r.is_toxic ? '1px dashed #f87171' : 'none',
                                            color: r.is_toxic ? '#991b1b' : '#334155',
                                            fontSize: '0.85rem'
                                        }}>
                                            {r.comment || <span style={{ color: '#94a3b8', fontStyle: 'italic' }}>No comment text</span>}
                                        </div>
                                    </td>

                                    <td>
                                        <div style={{ fontWeight: '600', fontSize: '0.85rem', color: '#0f172a' }}>{r.reviewer?.full_name || r.reviewer?.username || 'Unknown'}</div>
                                        <div style={{ fontSize: '0.75rem', color: '#64748b' }}>{r.reviewer?.email}</div>
                                    </td>

                                    <td>
                                        <div style={{ fontWeight: '600', fontSize: '0.85rem', color: '#0f172a' }}>{r.reviewee?.full_name || r.reviewee?.username || 'Unknown'}</div>
                                        <div style={{ fontSize: '0.75rem', color: '#64748b' }}>{r.reviewee?.email}</div>
                                    </td>

                                    {isAdmin && (
                                        <td style={{ textAlign: 'center', whiteSpace: 'nowrap' }}>
                                            <div style={{ display: 'inline-flex', gap: '8px', alignItems: 'center' }}>
                                                {activeTab === 'flagged' && (
                                                    <button
                                                        onClick={() => handleApproveReview(r.id)}
                                                        disabled={actionLoading === r.id}
                                                        title="Approve & Publish (Mark as Safe)"
                                                        style={{
                                                            background: '#dcfce7',
                                                            border: '1px solid #86efac',
                                                            color: '#15803d',
                                                            padding: '6px 10px',
                                                            borderRadius: '6px',
                                                            cursor: 'pointer',
                                                            display: 'flex',
                                                            alignItems: 'center',
                                                            gap: '4px',
                                                            fontSize: '0.8rem',
                                                            fontWeight: 'bold'
                                                        }}
                                                    >
                                                        <CheckCircle2 size={14} />
                                                        Approve
                                                    </button>
                                                )}

                                                <button
                                                    onClick={() => handleDeleteReview(r.id)}
                                                    disabled={actionLoading === r.id}
                                                    title="Permanently Delete Review"
                                                    style={{
                                                        background: '#fee2e2',
                                                        border: '1px solid #fca5a5',
                                                        color: '#dc2626',
                                                        padding: '6px 10px',
                                                        borderRadius: '6px',
                                                        cursor: 'pointer',
                                                        display: 'flex',
                                                        alignItems: 'center',
                                                        gap: '4px',
                                                        fontSize: '0.8rem',
                                                        fontWeight: 'bold'
                                                    }}
                                                >
                                                    <Trash2 size={14} />
                                                    Delete
                                                </button>
                                            </div>
                                        </td>
                                    )}
                                </tr>
                            ))}

                            {paginatedReviews.length === 0 && (
                                <tr>
                                    <td colSpan={activeTab === 'flagged' ? 8 : 7} style={{ textAlign: 'center', padding: '3rem', color: '#64748b' }}>
                                        {activeTab === 'flagged' ? (
                                            <div>
                                                <CheckCircle2 size={36} color="#10b981" style={{ margin: '0 auto 8px auto' }} />
                                                <div style={{ fontWeight: 'bold', color: '#0f172a' }}>Zero Flagged Reviews!</div>
                                                <div style={{ fontSize: '0.85rem' }}>All submitted reviews passed the NLP sentiment and toxicity threshold.</div>
                                            </div>
                                        ) : (
                                            'No reviews found matching your search.'
                                        )}
                                    </td>
                                </tr>
                            )}
                        </tbody>
                    </table>
                </div>
            )}

            <PaginationControls
                currentPage={currentPage}
                totalPages={totalPages}
                pageSize={pageSize}
                totalItems={sortedReviews.length}
                onPageChange={(page) => setCurrentPage(page)}
                onPageSizeChange={(size) => { setPageSize(size); setCurrentPage(1); }}
                sortBy={sortBy}
                sortOptions={sortOptions}
                onSortChange={(sort) => { setSortBy(sort); setCurrentPage(1); }}
            />
        </div>
    );
};

export default Reviews;
