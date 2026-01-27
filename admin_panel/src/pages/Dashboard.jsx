import React, { useEffect, useState } from 'react';
import api from '../services/api';
import Layout from '../components/Layout';
import { Users, ShoppingBag, DollarSign, Package } from 'lucide-react';

const Dashboard = () => {
    const [stats, setStats] = useState({ users: 0, products: 0, transactions: 0, revenue: 0 });
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchStats = async () => {
            try {
                const response = await api.get('/admin/stats');
                setStats(response.data);
            } catch (error) {
                console.error('Failed to fetch stats', error);
            } finally {
                setLoading(false);
            }
        };

        fetchStats();
    }, []);

    const StatCard = ({ title, value, icon: Icon, color }) => (
        <div className="card">
            <div className="flex justify-between items-center mb-4">
                <h3 className="text-sm">{title}</h3>
                <div style={{ padding: '8px', borderRadius: '8px', background: `${color}20`, color: color }}>
                    <Icon size={20} />
                </div>
            </div>
            <div className="stat-value">{value}</div>
        </div>
    );

    return (
        <Layout>
            <div className="flex justify-between items-center mb-8">
                <h2 className="text-xl">Dashboard Overview</h2>
                <button className="btn">Download Report</button>
            </div>

            <div className="stats-grid">
                <StatCard title="Total Users" value={stats.users} icon={Users} color="#3b82f6" />
                <StatCard title="Active Listings" value={stats.products} icon={Package} color="#a855f7" />
                <StatCard title="Transactions" value={stats.transactions} icon={ShoppingBag} color="#22c55e" />
                <StatCard title="Total Revenue" value={`RM ${stats.revenue || 0}`} icon={DollarSign} color="#eab308" />
            </div>

            <div className="card">
                <h3 className="text-xl mb-4">Recent Activity</h3>
                <p className="text-sm">Activity feed coming soon...</p>
            </div>
        </Layout>
    );
};

export default Dashboard;
