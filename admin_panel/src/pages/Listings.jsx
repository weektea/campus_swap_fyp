import React, { useState, useEffect } from 'react';
import { Search, Edit, Trash2 } from 'lucide-react';
import api from '../services/api';

const Listings = () => {
    const [listings, setListings] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [filterStatus, setFilterStatus] = useState('All');
    
    // Auth context
    const [currentUser, setCurrentUser] = useState(null);

    // Modal state for Edit
    const [selectedListing, setSelectedListing] = useState(null);
    const [isEditModalOpen, setIsEditModalOpen] = useState(false);
    const [editStatus, setEditStatus] = useState('Available');

    useEffect(() => {
        const userStr = localStorage.getItem('user');
        if (userStr) {
            setCurrentUser(JSON.parse(userStr));
        }
        fetchListings();
    }, []);

    const fetchListings = async () => {
        setLoading(true);
        try {
            const res = await api.get('/admin/listings');
            setListings(res.data);
        } catch (err) {
            console.error('Failed to fetch listings', err);
        } finally {
            setLoading(false);
        }
    };

    const handleManageClick = (listing) => {
        setSelectedListing(listing);
        setEditStatus(listing.status);
        setIsEditModalOpen(true);
    };

    const handleUpdateStatus = async () => {
        if (!selectedListing) return;
        try {
            await api.put(`/admin/listings/${selectedListing.id}/status`, {
                status: editStatus
            });
            setIsEditModalOpen(false);
            fetchListings(); // Refresh
        } catch (err) {
            alert(err.response?.data?.error || 'Failed to update listing status');
        }
    };

    const handleDeleteListing = async () => {
        if (!selectedListing) return;
        if (!window.confirm('WARNING: Are you sure you want to permanently delete this listing from the database? This action cannot be undone!')) return;
        
        try {
            await api.delete(`/admin/listings/${selectedListing.id}`);
            setIsEditModalOpen(false);
            fetchListings();
        } catch (err) {
            alert(err.response?.data?.error || 'Failed to delete listing');
        }
    };

    const filteredListings = listings.filter(item => {
        const titleMatch = (item.title || '').toLowerCase().includes(searchTerm.toLowerCase());
        const sellerMatch = (item.seller?.email || '').toLowerCase().includes(searchTerm.toLowerCase());
        const matchSearch = titleMatch || sellerMatch;
        const matchStatus = filterStatus === 'All' ? true : item.status === filterStatus;
        return matchSearch && matchStatus;
    });

    if (loading) return <div className="p-8 text-center text-gray-500">Loading listings...</div>;

    return (
        <div>
            <div className="flex justify-between items-center mb-8">
                <h1 style={{ fontSize: '1.5rem', margin: 0 }}>Listings Management</h1>
                <div className="flex gap-4 items-center">
                    <div style={{ 
                        display: 'flex', alignItems: 'center', 
                        background: 'white', 
                        border: '1px solid var(--border)',
                        borderRadius: '8px',
                        padding: '8px 16px',
                        width: '250px'
                    }}>
                        <Search size={18} color="var(--text-muted)" style={{ marginRight: '8px' }} />
                        <input 
                            type="text" 
                            placeholder="Search by title or email..." 
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            style={{ border: 'none', background: 'transparent', outline: 'none', width: '100%' }}
                        />
                    </div>
                    <select 
                        className="input" 
                        style={{ width: '150px', marginBottom: 0 }}
                        value={filterStatus}
                        onChange={(e) => setFilterStatus(e.target.value)}
                    >
                        <option value="All">All Status</option>
                        <option value="Available">Available</option>
                        <option value="Reserved">Reserved</option>
                        <option value="Sold">Sold</option>
                        <option value="Removed">Removed</option>
                    </select>
                </div>
            </div>

            <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
                <table>
                    <thead>
                        <tr>
                            <th>LISTING</th>
                            <th>PRICE</th>
                            <th>SELLER</th>
                            <th>TYPE</th>
                            <th>STATUS</th>
                            <th>ACTIONS</th>
                        </tr>
                    </thead>
                    <tbody>
                        {filteredListings.map(item => (
                            <tr key={item.id}>
                                <td style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                                    <div style={{ width: '40px', height: '40px', background: '#f3f4f6', borderRadius: '8px', overflow: 'hidden', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                        {item.image_urls && item.image_urls.length > 0 ? (
                                            <img src={`http://localhost:3000${item.image_urls[0]}`} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                                        ) : (
                                            <span style={{ color: '#9ca3af', fontSize: '0.6rem' }}>No Img</span>
                                        )}
                                    </div>
                                    <div>
                                        <div style={{ fontWeight: 'bold' }}>{item.title}</div>
                                        <div style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>ID: {item.id.substring(0,8)}...</div>
                                    </div>
                                </td>
                                <td style={{ color: 'var(--primary)' }}>
                                    {item.type === 'Rent' ? (
                                        <>
                                            <div style={{ fontWeight: 'bold' }}>RM {item.rental_price_per_day} <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>/ day</span></div>
                                            <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Dep: RM {item.rental_deposit}</div>
                                            <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Max: {item.max_rental_duration}d</div>
                                        </>
                                    ) : (
                                        <div style={{ fontWeight: 'bold' }}>RM {item.price}</div>
                                    )}
                                </td>
                                <td>
                                    <div>{item.seller?.full_name || 'No Name'}</div>
                                    <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{item.seller?.email}</div>
                                </td>
                                <td>
                                    <span style={{ 
                                        padding: '4px 8px', 
                                        background: item.type === 'Sale' ? '#e0e7ff' : '#fce7f3', 
                                        borderRadius: '4px', 
                                        color: item.type === 'Sale' ? '#3730a3' : '#9d174d', 
                                        fontSize: '0.75rem', 
                                        fontWeight: 'bold',
                                    }}>
                                        {item.type || 'Sale'}
                                    </span>
                                </td>
                                <td>
                                    <span style={{ 
                                        padding: '4px 12px', 
                                        borderRadius: '12px', 
                                        fontSize: '0.75rem', 
                                        fontWeight: 'bold',
                                        background: item.status === 'Available' ? '#dcfce7' : 
                                                    item.status === 'Sold' ? '#f3f4f6' : 
                                                    item.status === 'Reserved' ? '#fef3c7' : '#fee2e2',
                                        color: item.status === 'Available' ? '#16a34a' : 
                                               item.status === 'Sold' ? '#4b5563' : 
                                               item.status === 'Reserved' ? '#d97706' : '#dc2626'
                                    }}>
                                        {item.status}
                                    </span>
                                </td>
                                <td>
                                    <button 
                                        onClick={() => handleManageClick(item)}
                                        style={{ background: 'none', border: 'none', color: 'var(--primary)', fontWeight: 'bold', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '4px' }}
                                    >
                                        <Edit size={14} /> Manage
                                    </button>
                                </td>
                            </tr>
                        ))}
                        {filteredListings.length === 0 && (
                            <tr>
                                <td colSpan="6" style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>No listings found.</td>
                            </tr>
                        )}
                    </tbody>
                </table>
            </div>

            {/* Edit Modal */}
            {isEditModalOpen && selectedListing && (
                <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 50 }}>
                    <div className="card" style={{ width: '400px', background: 'white' }}>
                        <h2 style={{ marginTop: 0 }}>Manage Listing</h2>
                        <div style={{ marginBottom: '16px' }}>
                            <strong>{selectedListing.title}</strong>
                            <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', marginTop: '4px' }}>
                                Seller: {selectedListing.seller?.email}
                            </div>
                        </div>
                        
                        <div style={{ marginBottom: '24px' }}>
                            <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-muted)' }}>Listing Status</label>
                            <select 
                                className="input" 
                                value={editStatus} 
                                onChange={(e) => setEditStatus(e.target.value)}
                                style={{ width: '100%' }}
                            >
                                <option value="Available">Available</option>
                                <option value="Reserved">Reserved</option>
                                <option value="Sold">Sold</option>
                                <option value="Removed">Removed (Suspended)</option>
                            </select>
                        </div>

                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                            {currentUser?.role === 'admin' ? (
                                <button className="btn" style={{ background: '#fef2f2', color: '#dc2626', border: '1px solid #fca5a5' }} onClick={handleDeleteListing}>
                                    <Trash2 size={16} /> Delete
                                </button>
                            ) : <div></div>}

                            <div style={{ display: 'flex', gap: '12px' }}>
                                <button className="btn" style={{ background: '#e5e7eb', color: '#374151' }} onClick={() => setIsEditModalOpen(false)}>Cancel</button>
                                <button className="btn" style={{ background: 'var(--primary)' }} onClick={handleUpdateStatus}>Save Changes</button>
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default Listings;
