import React, { useState, useEffect } from 'react';
import { Search, Trash2 } from 'lucide-react';
import api from '../services/api';

const Reviews = () => {
    const [reviews, setReviews] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [currentUser, setCurrentUser] = useState(null);

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

    if (loading) return <div className="p-8 text-center text-gray-500">Loading reviews...</div>;

    const isAdmin = currentUser?.role === 'admin';

    return (
        <div>
            <div className="flex justify-between items-center mb-8">
                <h1 style={{ fontSize: '1.5rem', margin: 0 }}>Reviews Moderation</h1>
                <div style={{ display: 'flex', alignItems: 'center', background: 'white', border: '1px solid var(--border)', borderRadius: '8px', padding: '8px 16px', width: '300px' }}>
                    <Search size={18} color="var(--text-muted)" style={{ marginRight: '8px' }} />
                    <input type="text" placeholder="Search comments or users..." value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} style={{ border: 'none', background: 'transparent', outline: 'none', width: '100%' }} />
                </div>
            </div>

            <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
                <table>
                    <thead>
                        <tr>
                            <th>DATE</th>
                            <th>RATING</th>
                            <th>COMMENT</th>
                            <th>REVIEWER (FROM)</th>
                            <th>REVIEWEE (TO)</th>
                            {isAdmin && <th>ACTIONS</th>}
                        </tr>
                    </thead>
                    <tbody>
                        {filtered.map(r => (
                            <tr key={r.id}>
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
                        {filtered.length === 0 && <tr><td colSpan={isAdmin ? 6 : 5} style={{ textAlign: 'center', padding: '2rem' }}>No reviews found.</td></tr>}
                    </tbody>
                </table>
            </div>
        </div>
    );
};

export default Reviews;
