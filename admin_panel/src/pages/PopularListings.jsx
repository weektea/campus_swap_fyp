import React, { useState, useEffect } from 'react';
import { 
    Flame, 
    Eye, 
    Heart, 
    ShoppingBag, 
    RefreshCw, 
    Search, 
    TrendingUp, 
    Award,
    Info,
    ExternalLink
} from 'lucide-react';
import api from '../services/api';

const PopularListings = () => {
    const [listings, setListings] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [typeFilter, setTypeFilter] = useState('All');

    const fetchPopularListings = async () => {
        setLoading(true);
        try {
            const res = await api.get('/admin/popular-listings');
            setListings(res.data || []);
        } catch (err) {
            console.error('Failed to fetch popular listings:', err);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchPopularListings();
    }, []);

    const filteredListings = listings.filter(item => {
        const matchesSearch = item.title?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                              item.category?.toLowerCase().includes(searchTerm.toLowerCase());
        const matchesType = typeFilter === 'All' || item.type === typeFilter;
        return matchesSearch && matchesType;
    });

    return (
        <div style={{ padding: '1.5rem', maxWidth: '1400px', margin: '0 auto' }}>
            {/* Header Title */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: '1rem', marginBottom: '1.5rem' }}>
                <div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '4px' }}>
                        <div style={{ width: '36px', height: '36px', borderRadius: '10px', background: 'linear-gradient(135deg, #f97316 0%, #ea580c 100%)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white' }}>
                            <Flame size={22} />
                        </div>
                        <h1 style={{ margin: 0, fontSize: '1.75rem', fontWeight: '800', color: 'var(--text-main)' }}>
                            Popular Listings & Trending Calculations
                        </h1>
                    </div>
                    <p style={{ margin: 0, color: 'var(--text-muted)', fontSize: '0.925rem' }}>
                        Real-time user engagement score tracking based on views, favorites, chat inquiries, and purchases.
                    </p>
                </div>

                <button 
                    onClick={fetchPopularListings}
                    disabled={loading}
                    className="btn btn-secondary"
                    style={{ display: 'flex', alignItems: 'center', gap: '8px', padding: '0.6rem 1.2rem', fontWeight: '600' }}
                >
                    <RefreshCw size={18} className={loading ? 'spin' : ''} />
                    <span>Refresh Ranking</span>
                </button>
            </div>

            {/* Trending Score Calculation Formula Banner */}
            <div className="card" style={{ padding: '1.25rem 1.5rem', marginBottom: '1.75rem', background: 'linear-gradient(135deg, #fff7ed 0%, #ffedd5 100%)', border: '1px solid #fed7aa', borderRadius: '14px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '0.75rem' }}>
                    <TrendingUp size={20} color="#ea580c" />
                    <h3 style={{ margin: 0, fontSize: '1.05rem', fontWeight: '700', color: '#c2410c' }}>
                        Weighted Popularity Formula Breakdown
                    </h3>
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '1rem', marginTop: '0.75rem' }}>
                    <div style={{ background: 'white', padding: '0.85rem 1rem', borderRadius: '10px', border: '1px solid #ffedd5', display: 'flex', alignItems: 'center', gap: '10px' }}>
                        <div style={{ padding: '8px', borderRadius: '8px', background: '#eff6ff', color: '#2563eb' }}>
                            <Eye size={18} />
                        </div>
                        <div>
                            <div style={{ fontSize: '0.75rem', fontWeight: '600', color: '#6b7280' }}>Views</div>
                            <div style={{ fontSize: '0.95rem', fontWeight: '800', color: '#1e3a8a' }}>+1 pt / view</div>
                        </div>
                    </div>

                    <div style={{ background: 'white', padding: '0.85rem 1rem', borderRadius: '10px', border: '1px solid #ffedd5', display: 'flex', alignItems: 'center', gap: '10px' }}>
                        <div style={{ padding: '8px', borderRadius: '8px', background: '#fef2f2', color: '#dc2626' }}>
                            <Heart size={18} />
                        </div>
                        <div>
                            <div style={{ fontSize: '0.75rem', fontWeight: '600', color: '#6b7280' }}>User Saves</div>
                            <div style={{ fontSize: '0.95rem', fontWeight: '800', color: '#7f1d1d' }}>+5 pts / save</div>
                        </div>
                    </div>

                    <div style={{ background: 'white', padding: '0.85rem 1rem', borderRadius: '10px', border: '1px solid #ffedd5', display: 'flex', alignItems: 'center', gap: '10px' }}>
                        <div style={{ padding: '8px', borderRadius: '8px', background: '#fdf4ff', color: '#a855f7' }}>
                            <ShoppingBag size={18} />
                        </div>
                        <div>
                            <div style={{ fontSize: '0.75rem', fontWeight: '600', color: '#6b7280' }}>Purchases / Rents</div>
                            <div style={{ fontSize: '0.95rem', fontWeight: '800', color: '#581c87' }}>+10 pts / buy</div>
                        </div>
                    </div>
                </div>
            </div>

            {/* Controls Filter Bar */}
            <div className="card" style={{ padding: '1rem 1.25rem', marginBottom: '1.5rem', display: 'flex', gap: '1rem', flexWrap: 'wrap', alignItems: 'center', justifyContent: 'space-between' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px', flex: 1, minWidth: '260px' }}>
                    <Search size={18} color="var(--text-muted)" />
                    <input 
                        type="text" 
                        placeholder="Search by title or category..."
                        value={searchTerm}
                        onChange={e => setSearchTerm(e.target.value)}
                        style={{ border: 'none', outline: 'none', background: 'transparent', width: '100%', fontSize: '0.925rem' }}
                    />
                </div>

                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <span style={{ fontSize: '0.85rem', fontWeight: '600', color: 'var(--text-muted)' }}>Type:</span>
                    <button 
                        onClick={() => setTypeFilter('All')} 
                        className={`btn ${typeFilter === 'All' ? 'btn-primary' : 'btn-secondary'}`}
                        style={{ padding: '4px 12px', fontSize: '0.825rem' }}
                    >
                        All
                    </button>
                    <button 
                        onClick={() => setTypeFilter('Sale')} 
                        className={`btn ${typeFilter === 'Sale' ? 'btn-primary' : 'btn-secondary'}`}
                        style={{ padding: '4px 12px', fontSize: '0.825rem' }}
                    >
                        Sale
                    </button>
                    <button 
                        onClick={() => setTypeFilter('Rent')} 
                        className={`btn ${typeFilter === 'Rent' ? 'btn-primary' : 'btn-secondary'}`}
                        style={{ padding: '4px 12px', fontSize: '0.825rem' }}
                    >
                        Rent
                    </button>
                </div>
            </div>

            {/* Popular Listings Table */}
            <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
                <div style={{ overflowX: 'auto' }}>
                    <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                        <thead>
                            <tr style={{ background: '#f9fafb', borderBottom: '1px solid var(--border)' }}>
                                <th style={{ width: '60px', textAlign: 'center', padding: '1rem 0.75rem' }}>RANK</th>
                                <th style={{ textAlign: 'left', padding: '1rem' }}>PRODUCT TITLE</th>
                                <th style={{ textAlign: 'left', padding: '1rem' }}>CATEGORY</th>
                                <th style={{ textAlign: 'left', padding: '1rem' }}>PRICE</th>
                                <th style={{ textAlign: 'center', padding: '1rem' }}>TYPE</th>
                                <th style={{ textAlign: 'center', padding: '1rem' }}>VIEWS (+1)</th>
                                <th style={{ textAlign: 'center', padding: '1rem' }}>SAVES (+5)</th>
                                <th style={{ textAlign: 'center', padding: '1rem' }}>PURCHASES (+10)</th>
                                <th style={{ textAlign: 'center', padding: '1rem' }}>POPULARITY SCORE</th>
                            </tr>
                        </thead>
                        <tbody>
                            {loading ? (
                                <tr>
                                    <td colSpan="9" style={{ textAlign: 'center', padding: '3rem', color: 'var(--text-muted)' }}>
                                        <RefreshCw size={24} className="spin" style={{ margin: '0 auto 8px auto' }} />
                                        <p style={{ margin: 0 }}>Calculating popularity rankings...</p>
                                    </td>
                                </tr>
                            ) : filteredListings.length === 0 ? (
                                <tr>
                                    <td colSpan="9" style={{ textAlign: 'center', padding: '3rem', color: 'var(--text-muted)' }}>
                                        No listings match the selected search criteria.
                                    </td>
                                </tr>
                            ) : (
                                filteredListings.map((item, index) => {
                                    const rankColor = index === 0 ? '#eab308' : index === 1 ? '#94a3b8' : index === 2 ? '#b45309' : 'var(--primary)';
                                    return (
                                        <tr key={item.id} style={{ borderBottom: '1px solid #f3f4f6' }}>
                                            <td style={{ textAlign: 'center', fontWeight: '800', color: rankColor, fontSize: '1.05rem' }}>
                                                {index < 3 ? (
                                                    <span style={{ display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: '4px' }}>
                                                        <Award size={16} /> #{index + 1}
                                                    </span>
                                                ) : (
                                                    `#${index + 1}`
                                                )}
                                            </td>
                                            <td style={{ padding: '1rem' }}>
                                                <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                                                    {item.image_urls && item.image_urls.length > 0 ? (
                                                        <img 
                                                            src={item.image_urls[0]} 
                                                            alt={item.title} 
                                                            style={{ width: '44px', height: '44px', borderRadius: '8px', objectFit: 'cover', border: '1px solid #e5e7eb' }} 
                                                        />
                                                    ) : (
                                                        <div style={{ width: '44px', height: '44px', borderRadius: '8px', background: '#f3f4f6', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#9ca3af' }}>
                                                            <ShoppingBag size={20} />
                                                        </div>
                                                    )}
                                                    <div>
                                                        <div style={{ fontWeight: '600', color: 'var(--text-main)', fontSize: '0.95rem' }}>{item.title}</div>
                                                        <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>ID: {item.id}</div>
                                                    </div>
                                                </div>
                                            </td>
                                            <td style={{ padding: '1rem', color: '#4b5563', fontSize: '0.9rem' }}>
                                                {item.category || 'General'}
                                            </td>
                                            <td style={{ padding: '1rem', fontWeight: '700', color: 'var(--text-main)' }}>
                                                RM {parseFloat(item.price).toFixed(2)}
                                            </td>
                                            <td style={{ textAlign: 'center', padding: '1rem' }}>
                                                <span style={{ 
                                                    padding: '3px 10px', 
                                                    background: item.type === 'Rent' ? '#eff6ff' : '#f0fdf4', 
                                                    borderRadius: '12px', 
                                                    color: item.type === 'Rent' ? '#1d4ed8' : '#166534', 
                                                    fontSize: '0.75rem', 
                                                    fontWeight: '700' 
                                                }}>
                                                    {item.type}
                                                </span>
                                            </td>
                                            <td style={{ textAlign: 'center', fontWeight: '600', color: '#2563eb' }}>
                                                {item.view_count || 0}
                                            </td>
                                            <td style={{ textAlign: 'center', fontWeight: '600', color: '#dc2626' }}>
                                                {item.save_count || 0}
                                            </td>
                                            <td style={{ textAlign: 'center', fontWeight: '600', color: '#a855f7' }}>
                                                {item.buy_count || 0}
                                            </td>
                                            <td style={{ textAlign: 'center', padding: '1rem' }}>
                                                <span style={{ 
                                                    display: 'inline-block',
                                                    padding: '4px 12px',
                                                    borderRadius: '16px',
                                                    background: 'linear-gradient(135deg, var(--primary) 0%, #0d9488 100%)',
                                                    color: 'white',
                                                    fontWeight: '800',
                                                    fontSize: '0.95rem'
                                                }}>
                                                    {item.popularity_score} pts
                                                </span>
                                            </td>
                                        </tr>
                                    );
                                })
                            )}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    );
};

export default PopularListings;
