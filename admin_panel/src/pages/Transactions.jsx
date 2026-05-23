import React, { useState, useEffect } from 'react';
import { Search } from 'lucide-react';
import api from '../services/api';

const Transactions = () => {
    const [transactions, setTransactions] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [filterStatus, setFilterStatus] = useState('All');

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

    if (loading) return <div className="p-8 text-center text-gray-500">Loading transactions...</div>;

    return (
        <div>
            <div className="flex justify-between items-center mb-8">
                <h1 style={{ fontSize: '1.5rem', margin: 0 }}>Transactions (Orders)</h1>
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
                    </select>
                </div>
            </div>

            <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
                <table>
                    <thead>
                        <tr>
                            <th>ORDER ID / DATE</th>
                            <th>PRODUCT</th>
                            <th>BUYER</th>
                            <th>SELLER</th>
                            <th>AMOUNT</th>
                            <th>STATUS</th>
                        </tr>
                    </thead>
                    <tbody>
                        {filtered.map(t => (
                            <tr key={t.id}>
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
                            </tr>
                        ))}
                        {filtered.length === 0 && <tr><td colSpan="6" style={{ textAlign: 'center', padding: '2rem' }}>No transactions found.</td></tr>}
                    </tbody>
                </table>
            </div>
        </div>
    );
};

export default Transactions;
