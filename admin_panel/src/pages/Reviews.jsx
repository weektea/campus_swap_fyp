import React, { useState, useEffect } from 'react';
import { Search, Trash2 } from 'lucide-react';
import api from '../services/api';

import PaginationControls from '../components/PaginationControls';

const Reviews = () => {
    const [reviews, setReviews] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [currentUser, setCurrentUser] = useState(null);

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
        fetchReviews();
    }, []);

    const fetchReviews = async () => {
        try {
            const res = await api.get('/admin/reviews');
            setReviews(res.data);
        } catch (err) {
            console.error(err);
        } finally {
            setLoading(false);
        }
    };

    const handleDeleteReview = async (id) => {
        const confirmDelete = window.confirm("Are you sure you want to permanently delete this review?");
        if (!confirmDelete) return;

        try {
            await api.delete(`/admin/reviews/${id}`);
            fetchReviews();
        } catch (err) {
            alert('Failed to delete review');
        }
    };

    const filtered = reviews.filter(r => {
        const textMatch = (r.comment || '').toLowerCase().includes(searchTerm.toLowerCase());
        const reviewerMatch = (r.reviewer?.email || '').toLowerCase().includes(searchTerm.toLowerCase());
        const revieweeMatch = (r.reviewee?.email || '').toLowerCase().includes(searchTerm.toLowerCase());
        return textMatch || reviewerMatch || revieweeMatch;
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

    if (loading) return <div className="p-8 text-center text-gray-500">Loading reviews...</div>;

    const isAdmin = currentUser?.role === 'admin';

    return (
        <div>
            <div className="flex justify-between items-center mb-8">
                <div className="flex items-center gap-3">
                    <h1 style={{ fontSize: '1.5rem', margin: 0 }}>Reviews Moderation</h1>
                    <span style={{ fontSize: '0.85rem', padding: '4px 12px', borderRadius: '12px', background: '#eff6ff', color: '#2563eb', fontWeight: 'bold', border: '1px solid #bfdbfe' }}>
                        Showing {filtered.length} of {reviews.length} reviews
                    </span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', background: 'white', border: '1px solid var(--border)', borderRadius: '8px', padding: '8px 16px', width: '300px' }}>
                    <Search size={18} color="var(--text-muted)" style={{ marginRight: '8px' }} />
                    <input type="text" placeholder="Search comments or users..." value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} style={{ border: 'none', background: 'transparent', outline: 'none', width: '100%' }} />
                </div>
            </div>

            <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
                <table>
                    <thead>
                        <tr>
                            <th style={{ width: '50px', textAlign: 'center' }}>NO.</th>
                            <th>DATE</th>
                            <th>RATING</th>
                            <th>COMMENT</th>
                            <th>REVIEWER (FROM)</th>
                            <th>REVIEWEE (TO)</th>
                            {isAdmin && <th>ACTIONS</th>}
                        </tr>
                    </thead>
                    <tbody>
                        {paginatedReviews.map((r, index) => (
                            <tr key={r.id}>
                                <td style={{ textAlign: 'center', fontWeight: 'bold', color: 'var(--text-muted)' }}>{(currentPage - 1) * pageSize + index + 1}</td>
                                <td style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>{new Date(r.createdAt).toLocaleDateString()}</td>
                                <td style={{ fontWeight: 'bold', color: r.rating >= 4 ? '#16a34a' : r.rating <= 2 ? '#dc2626' : '#d97706' }}>
                                    {r.rating} / 5
                                </td>
                                <td style={{ maxWidth: '300px' }}>
                                    <div style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{r.comment || <span style={{color: '#9ca3af', fontStyle: 'italic'}}>No text</span>}</div>
                                </td>
                                <td>
                                    <div>{r.reviewer?.full_name}</div>
                                    <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{r.reviewer?.email}</div>
                                </td>
                                <td>
                                    <div>{r.reviewee?.full_name}</div>
                                    <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{r.reviewee?.email}</div>
                                </td>
                                {isAdmin && (
                                    <td>
                                        <button 
                                            style={{ background: 'none', border: 'none', color: '#dc2626', cursor: 'pointer' }}
                                            onClick={() => handleDeleteReview(r.id)}
                                        >
                                            <Trash2 size={18} />
                                        </button>
                                    </td>
                                )}
                            </tr>
                        ))}
                        {paginatedReviews.length === 0 && <tr><td colSpan={isAdmin ? 7 : 6} style={{ textAlign: 'center', padding: '2rem' }}>No reviews found.</td></tr>}
                    </tbody>
                </table>
            </div>

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
