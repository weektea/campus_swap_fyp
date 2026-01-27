import React, { useEffect, useState } from 'react';
import api from '../services/api';
import Layout from '../components/Layout';
import { Search } from 'lucide-react';

const TransactionsPage = () => {
    const [transactions, setTransactions] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchTransactions = async () => {
            try {
                const response = await api.get('/admin/transactions');
                setTransactions(response.data);
            } catch (error) {
                console.error('Error fetching transactions:', error);
            } finally {
                setLoading(false);
            }
        };

        fetchTransactions();
    }, []);

    const getStatusColor = (status) => {
        switch (status) {
            case 'completed': return '#22c55e';
            case 'pending': return '#eab308';
            case 'cancelled': return '#ef4444';
            default: return '#94a3b8';
        }
    };

    return (
        <Layout>
            <div className="flex justify-between items-center mb-6">
                <h2 className="text-xl">Transactions</h2>
                <div style={{ position: 'relative' }}>
                    <Search size={18} style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: '#94a3b8' }} />
                    <input
                        type="text"
                        placeholder="Search ID..."
                        className="input"
                        style={{ width: '300px', margin: 0, paddingLeft: '40px' }}
                    />
                </div>
            </div>

            <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
                <table>
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Product</th>
                            <th>Buyer ID</th>
                            <th>Seller ID</th>
                            <th>Amount</th>
                            <th>Status</th>
                            <th>Date</th>
                        </tr>
                    </thead>
                    <tbody>
                        {transactions.map(tx => (
                            <tr key={tx.id}>
                                <td className="text-sm">#{tx.id}</td>
                                <td>{tx.product?.title || 'Unknown Product'}</td>
                                <td className="text-sm">#{tx.buyer_id}</td>
                                <td className="text-sm">#{tx.seller_id}</td>
                                <td style={{ fontWeight: 600 }}>RM {tx.amount}</td>
                                <td>
                                    <span style={{
                                        padding: '4px 8px',
                                        borderRadius: '4px',
                                        fontSize: '12px',
                                        background: `${getStatusColor(tx.status)}20`,
                                        color: getStatusColor(tx.status)
                                    }}>
                                        {tx.status}
                                    </span>
                                </td>
                                <td className="text-sm">{new Date(tx.createdAt).toLocaleDateString()}</td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </Layout>
    );
};

export default TransactionsPage;
