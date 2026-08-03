import React, { useState, useEffect } from 'react';
import { Search, Eye, Calendar, Clock, User, ShieldAlert, Award } from 'lucide-react';
import api, { IMAGE_BASE_URL } from '../services/api';

import PaginationControls from '../components/PaginationControls';

const getImageUrl = (url) => {
    if (!url) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return `${IMAGE_BASE_URL}${url.startsWith('/') ? '' : '/'}${url}`;
};

const Transactions = () => {
    const [transactions, setTransactions] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [filterStatus, setFilterStatus] = useState('All');
    const [selectedTransaction, setSelectedTransaction] = useState(null);

    // Pagination & Sort states
    const [currentPage, setCurrentPage] = useState(1);
    const [pageSize, setPageSize] = useState(10);
    const [sortBy, setSortBy] = useState('newest');

    const sortOptions = [
        { label: 'Date: Newest First', value: 'newest' },
        { label: 'Date: Oldest First', value: 'oldest' },
        { label: 'Amount: High to Low', value: 'amount_desc' },
        { label: 'Amount: Low to High', value: 'amount_asc' }
    ];

    useEffect(() => {
        fetchTransactions();
    }, []);

    const fetchTransactions = async () => {
        try {
            const res = await api.get('/admin/transactions');
            setTransactions(res.data);
        } catch (err) {
            console.error(err);
        } finally {
            setLoading(false);
        }
    };

    const filtered = transactions.filter(t => {
        const productTitle = t.product?.title?.toLowerCase() || '';
        const buyerEmail = t.buyer?.email?.toLowerCase() || '';
        const sellerEmail = t.seller?.email?.toLowerCase() || '';
        const matchSearch = productTitle.includes(searchTerm.toLowerCase()) || 
                            buyerEmail.includes(searchTerm.toLowerCase()) || 
                            sellerEmail.includes(searchTerm.toLowerCase());
        const matchStatus = filterStatus === 'All' ? true : t.status === filterStatus;
        return matchSearch && matchStatus;
    });

    const sortedTransactions = [...filtered].sort((a, b) => {
        if (sortBy === 'newest') return new Date(b.createdAt) - new Date(a.createdAt);
        if (sortBy === 'oldest') return new Date(a.createdAt) - new Date(b.createdAt);
        if (sortBy === 'amount_desc') return (parseFloat(b.amount) || 0) - (parseFloat(a.amount) || 0);
        if (sortBy === 'amount_asc') return (parseFloat(a.amount) || 0) - (parseFloat(b.amount) || 0);
        return 0;
    });

    const totalPages = Math.ceil(sortedTransactions.length / pageSize) || 1;
    const paginatedTransactions = sortedTransactions.slice((currentPage - 1) * pageSize, currentPage * pageSize);

    if (loading) return <div className="p-8 text-center text-gray-500">Loading transactions...</div>;

    return (
        <div>
            <div className="flex justify-between items-center mb-8">
                <div className="flex items-center gap-3">
                    <h1 style={{ fontSize: '1.5rem', margin: 0, fontWeight: 'bold', color: 'var(--primary)' }}>Transactions (Orders)</h1>
                    <span style={{ fontSize: '0.85rem', padding: '4px 12px', borderRadius: '12px', background: '#eff6ff', color: '#2563eb', fontWeight: 'bold', border: '1px solid #bfdbfe' }}>
                        Showing {filtered.length} of {transactions.length} transactions
                    </span>
                </div>
                <div className="flex gap-4">
                    <div style={{ display: 'flex', alignItems: 'center', background: 'white', border: '1px solid var(--border)', borderRadius: '8px', padding: '8px 16px', width: '300px' }}>
                        <Search size={18} color="var(--text-muted)" style={{ marginRight: '8px' }} />
                        <input type="text" placeholder="Search by title or email..." value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} style={{ border: 'none', background: 'transparent', outline: 'none', width: '100%' }} />
                    </div>
                    <select className="input" style={{ width: '150px', marginBottom: 0 }} value={filterStatus} onChange={(e) => setFilterStatus(e.target.value)}>
                        <option value="All">All Status</option>
                        <option value="Pending">Pending</option>
                        <option value="Scheduled">Scheduled</option>
                        <option value="Completed">Completed</option>
                        <option value="Cancelled">Cancelled</option>
                        <option value="Disputed">Disputed</option>
                    </select>
                </div>
            </div>

            <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
                <table>
                    <thead>
                        <tr>
                            <th style={{ width: '50px', textAlign: 'center' }}>NO.</th>
                            <th>ORDER ID / DATE</th>
                            <th>PRODUCT</th>
                            <th>BUYER</th>
                            <th>SELLER</th>
                            <th>AMOUNT</th>
                            <th>STATUS</th>
                            <th>ACTION</th>
                        </tr>
                    </thead>
                    <tbody>
                        {paginatedTransactions.map((t, index) => (
                            <tr key={t.id} onClick={() => setSelectedTransaction(t)} style={{ cursor: 'pointer' }}>
                                <td style={{ textAlign: 'center', fontWeight: 'bold', color: 'var(--text-muted)' }}>{(currentPage - 1) * pageSize + index + 1}</td>
                                <td>
                                    <div style={{ fontWeight: 'bold' }}>{t.id.substring(0,8)}...</div>
                                    <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{new Date(t.createdAt).toLocaleDateString()}</div>
                                </td>
                                <td>
                                    <div style={{ fontWeight: 'bold' }}>{t.product?.title || 'Unknown Product'}</div>
                                    <span style={{ fontSize: '0.7rem', padding: '2px 6px', background: '#e0e7ff', color: '#3730a3', borderRadius: '4px' }}>{t.product?.type || 'Sale'}</span>
                                </td>
                                <td>
                                    <div>{t.buyer?.full_name}</div>
                                    <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{t.buyer?.email}</div>
                                </td>
                                <td>
                                    <div>{t.seller?.full_name}</div>
                                    <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{t.seller?.email}</div>
                                </td>
                                <td style={{ fontWeight: 'bold', color: 'var(--primary)' }}>
                                    RM {t.amount}
                                </td>
                                <td>
                                    <span style={{
                                        padding: '4px 12px', borderRadius: '12px', fontSize: '0.75rem', fontWeight: 'bold',
                                        background: t.status === 'Completed' ? '#dcfce7' : 
                                                    t.status === 'Cancelled' ? '#fee2e2' : '#fef3c7',
                                        color: t.status === 'Completed' ? '#16a34a' : 
                                               t.status === 'Cancelled' ? '#dc2626' : '#d97706'
                                    }}>
                                        {t.status}
                                    </span>
                                </td>
                                <td>
                                    <button 
                                        className="btn btn-outline" 
                                        onClick={(e) => { e.stopPropagation(); setSelectedTransaction(t); }}
                                        style={{ 
                                            padding: '4px 8px', 
                                            fontSize: '0.75rem',
                                            display: 'flex',
                                            alignItems: 'center',
                                            gap: '4px'
                                        }}
                                    >
                                        <Eye size={12} />
                                        <span>View</span>
                                    </button>
                                </td>
                            </tr>
                        ))}
                        {paginatedTransactions.length === 0 && <tr><td colSpan="8" style={{ textAlign: 'center', padding: '2rem' }}>No transactions found.</td></tr>}
                    </tbody>
                </table>
            </div>

            <PaginationControls
                currentPage={currentPage}
                totalPages={totalPages}
                pageSize={pageSize}
                totalItems={sortedTransactions.length}
                onPageChange={(page) => setCurrentPage(page)}
                onPageSizeChange={(size) => { setPageSize(size); setCurrentPage(1); }}
                sortBy={sortBy}
                sortOptions={sortOptions}
                onSortChange={(sort) => { setSortBy(sort); setCurrentPage(1); }}
            />

            {/* Transaction Details Modal */}
            {selectedTransaction && (
                <div style={{
                    position: 'fixed',
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    backgroundColor: 'rgba(0, 0, 0, 0.4)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    zIndex: 1000,
                    backdropFilter: 'blur(4px)',
                    animation: 'fadeIn 0.2s ease-out'
                }} onClick={() => setSelectedTransaction(null)}>
                    <div style={{
                        background: 'white',
                        borderRadius: '16px',
                        padding: '2rem',
                        width: '650px',
                        maxWidth: '90%',
                        maxHeight: '85vh',
                        overflowY: 'auto',
                        boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)',
                        animation: 'scaleIn 0.2s ease-out'
                    }} onClick={(e) => e.stopPropagation()}>
                        {/* Modal Header */}
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid var(--border)', paddingBottom: '1rem', marginBottom: '1.5rem' }}>
                            <div>
                                <h3 style={{ margin: 0, fontSize: '1.25rem', fontWeight: 'bold', color: 'var(--primary)' }}>Transaction Details</h3>
                                <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>ID: {selectedTransaction.id}</span>
                            </div>
                            <button 
                                onClick={() => setSelectedTransaction(null)}
                                style={{ background: 'transparent', border: 'none', fontSize: '1.5rem', cursor: 'pointer', color: 'var(--text-muted)' }}
                            >
                                &times;
                            </button>
                        </div>

                        {/* Modal Content */}
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                            {/* Summary row */}
                            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(110px, 1fr))', gap: '1rem', background: '#f9fafb', padding: '1rem', borderRadius: '12px', border: '1px solid var(--border)' }}>
                                <div>
                                    <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Order Date</div>
                                    <div style={{ fontWeight: '600', marginTop: '2px', fontSize: '0.85rem' }}>{new Date(selectedTransaction.createdAt).toLocaleDateString()}</div>
                                </div>
                                <div>
                                    <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Status</div>
                                    <div style={{ marginTop: '2px' }}>
                                        <span style={{
                                            padding: '2px 8px', borderRadius: '8px', fontSize: '0.7rem', fontWeight: 'bold',
                                            background: selectedTransaction.status === 'Completed' ? '#dcfce7' : 
                                                        selectedTransaction.status === 'Cancelled' ? '#fee2e2' : '#fef3c7',
                                            color: selectedTransaction.status === 'Completed' ? '#16a34a' : 
                                                   selectedTransaction.status === 'Cancelled' ? '#dc2626' : '#d97706'
                                        }}>
                                            {selectedTransaction.status}
                                        </span>
                                    </div>
                                </div>
                                <div>
                                    <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Amount</div>
                                    <div style={{ fontWeight: 'bold', color: 'var(--primary)', marginTop: '2px', fontSize: '0.85rem' }}>RM {selectedTransaction.amount}</div>
                                </div>
                                <div>
                                    <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Platform Fee</div>
                                    <div style={{ fontWeight: '600', marginTop: '2px', fontSize: '0.85rem' }}>RM {selectedTransaction.platform_fee || '0.00'}</div>
                                </div>
                                <div>
                                    <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Carbon Saved</div>
                                    <div style={{ fontWeight: '600', color: '#16a34a', marginTop: '2px', fontSize: '0.85rem' }}>{selectedTransaction.awarded_carbon_points || '0.00'} kg CO2e</div>
                                </div>
                            </div>

                            {/* Product Info Section */}
                            <div>
                                <h4 style={{ margin: '0 0 0.5rem 0', fontSize: '0.9rem', borderBottom: '1px solid var(--border)', paddingBottom: '4px', color: 'var(--primary)', fontWeight: 'bold' }}>Product Details</h4>
                                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                    <div>
                                        <div style={{ fontWeight: 'bold', fontSize: '0.95rem' }}>{selectedTransaction.product?.title || 'Unknown Product'}</div>
                                        <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: '2px' }}>Type: {selectedTransaction.product?.type || 'Sale'}</div>
                                    </div>
                                    <div style={{ fontWeight: 'bold' }}>RM {selectedTransaction.product?.price || '0.00'}</div>
                                </div>
                            </div>

                            {/* Parties Info Section */}
                            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem' }}>
                                <div>
                                    <h4 style={{ margin: '0 0 0.5rem 0', fontSize: '0.9rem', borderBottom: '1px solid var(--border)', paddingBottom: '4px', color: 'var(--primary)', fontWeight: 'bold' }}>Buyer Details</h4>
                                    <div style={{ fontSize: '0.85rem', lineHeight: '1.4' }}>
                                        <div><strong>Name:</strong> {selectedTransaction.buyer?.full_name}</div>
                                        <div><strong>Username:</strong> {selectedTransaction.buyer?.username}</div>
                                        <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', overflow: 'hidden', textOverflow: 'ellipsis' }}>{selectedTransaction.buyer?.email}</div>
                                    </div>
                                </div>
                                <div>
                                    <h4 style={{ margin: '0 0 0.5rem 0', fontSize: '0.9rem', borderBottom: '1px solid var(--border)', paddingBottom: '4px', color: 'var(--primary)', fontWeight: 'bold' }}>Seller Details</h4>
                                    <div style={{ fontSize: '0.85rem', lineHeight: '1.4' }}>
                                        <div><strong>Name:</strong> {selectedTransaction.seller?.full_name}</div>
                                        <div><strong>Username:</strong> {selectedTransaction.seller?.username}</div>
                                        <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', overflow: 'hidden', textOverflow: 'ellipsis' }}>{selectedTransaction.seller?.email}</div>
                                    </div>
                                </div>
                            </div>

                            {/* Meetup Details Section */}
                            <div>
                                <h4 style={{ margin: '0 0 0.5rem 0', fontSize: '0.9rem', borderBottom: '1px solid var(--border)', paddingBottom: '4px', color: 'var(--primary)', fontWeight: 'bold' }}>Meetup & Scheduling</h4>
                                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', fontSize: '0.85rem' }}>
                                    <div><strong>Meetup Location:</strong> {selectedTransaction.meetup_location || 'Not Specified'}</div>
                                    <div><strong>Scheduled Time:</strong> {selectedTransaction.scheduled_at ? new Date(selectedTransaction.scheduled_at).toLocaleString() : 'Not Scheduled'}</div>
                                </div>
                            </div>

                            {/* Rental Period (Visible only for Rental Transactions) */}
                            {(selectedTransaction.product?.type === 'Rent' || selectedTransaction.rental_start_date) && (
                                <div>
                                    <h4 style={{ margin: '0 0 0.5rem 0', fontSize: '0.9rem', borderBottom: '1px solid var(--border)', paddingBottom: '4px', color: 'var(--primary)', fontWeight: 'bold' }}>Rental & Deposit Escrow Info</h4>
                                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '1rem', fontSize: '0.85rem' }}>
                                        <div><strong>Rental Type:</strong> {selectedTransaction.rental_type || 'Short-term'}</div>
                                        <div><strong>Deposit Amount:</strong> RM {selectedTransaction.deposit_amount || '0.00'}</div>
                                        <div>
                                            <strong>Deposit Status:</strong>
                                            <div style={{ marginTop: '2px' }}>
                                                <span style={{
                                                    padding: '2px 8px', borderRadius: '8px', fontSize: '0.7rem', fontWeight: 'bold',
                                                    background: selectedTransaction.deposit_status === 'Refunded' ? '#dcfce7' :
                                                                selectedTransaction.deposit_status === 'Claimed_Forfeited' ? '#fee2e2' : '#e0f2fe',
                                                    color: selectedTransaction.deposit_status === 'Refunded' ? '#16a34a' :
                                                           selectedTransaction.deposit_status === 'Claimed_Forfeited' ? '#dc2626' : '#0369a1'
                                                }}>
                                                    {selectedTransaction.deposit_status || 'Held'}
                                                </span>
                                            </div>
                                        </div>
                                        <div>
                                            <strong>Period:</strong> 
                                            <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: '2px' }}>
                                                {selectedTransaction.rental_start_date ? `${new Date(selectedTransaction.rental_start_date).toLocaleDateString()} to ${new Date(selectedTransaction.rental_end_date).toLocaleDateString()}` : 'N/A'}
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            )}

                            {/* Payment proof and method info */}
                            <div>
                                <h4 style={{ margin: '0 0 0.5rem 0', fontSize: '0.9rem', borderBottom: '1px solid var(--border)', paddingBottom: '4px', color: 'var(--primary)', fontWeight: 'bold' }}>Payment Details</h4>
                                <div style={{ fontSize: '0.85rem' }}>
                                    <div><strong>Method Selected:</strong> {selectedTransaction.selected_payment_method || 'N/A'}</div>
                                    {selectedTransaction.payment_proof_url && (
                                        <div style={{ marginTop: '0.75rem' }}>
                                            <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', marginBottom: '4px' }}>Proof of Payment:</div>
                                            <a href={getImageUrl(selectedTransaction.payment_proof_url)} target="_blank" rel="noopener noreferrer">
                                                <img 
                                                    src={getImageUrl(selectedTransaction.payment_proof_url)} 
                                                    alt="Payment Proof" 
                                                    style={{ maxWidth: '100%', maxHeight: '220px', borderRadius: '8px', border: '1px solid var(--border)', cursor: 'pointer', objectFit: 'cover' }} 
                                                />
                                            </a>
                                        </div>
                                    )}
                                </div>
                            </div>

                            {/* Ratings and Reviews */}
                            {(selectedTransaction.rating_from_buyer || selectedTransaction.rating_from_seller) && (
                                <div>
                                    <h4 style={{ margin: '0 0 0.5rem 0', fontSize: '0.9rem', borderBottom: '1px solid var(--border)', paddingBottom: '4px', color: 'var(--primary)', fontWeight: 'bold' }}>Feedback & Reviews</h4>
                                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem', fontSize: '0.85rem' }}>
                                        {selectedTransaction.rating_from_buyer && (
                                            <div>
                                                <div><strong>Buyer Rating:</strong> {'⭐'.repeat(selectedTransaction.rating_from_buyer)}</div>
                                                <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontStyle: 'italic', marginTop: '2px' }}>"{selectedTransaction.buyer_comment || 'No comment'}"</div>
                                            </div>
                                        )}
                                        {selectedTransaction.rating_from_seller && (
                                            <div>
                                                <div><strong>Seller Rating:</strong> {'⭐'.repeat(selectedTransaction.rating_from_seller)}</div>
                                                <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontStyle: 'italic', marginTop: '2px' }}>"{selectedTransaction.seller_comment || 'No comment'}"</div>
                                            </div>
                                        )}
                                    </div>
                                </div>
                            )}
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default Transactions;
