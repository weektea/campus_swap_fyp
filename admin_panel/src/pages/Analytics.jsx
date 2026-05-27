import React, { useState, useEffect } from 'react';
import { Calendar, Download, BrainCircuit } from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import api from '../services/api';

const Analytics = () => {
    const [metrics, setMetrics] = useState(null);
    const [loading, setLoading] = useState(true);
    const [isRetraining, setIsRetraining] = useState(false);
    const [retrainMsg, setRetrainMsg] = useState("");

    useEffect(() => {
        const fetchMetrics = async () => {
            try {
                const res = await api.get('/admin/metrics');
                setMetrics(res.data);
            } catch (err) {
                console.error('Failed to fetch metrics', err);
            } finally {
                setLoading(false);
            }
        };

        fetchMetrics();
    }, []);

    if (loading) return <div className="p-8 text-center text-gray-500">Loading analytics...</div>;

    const COLORS = ['#16a34a', '#2563eb', '#d97706', '#dc2626', '#8b5cf6'];

    return (
        <div>
            <div className="flex justify-between items-center mb-8">
                <h1 style={{ fontSize: '1.5rem', margin: 0 }}>System Analytics</h1>
                <div className="flex gap-4">
                    <button 
                        className="btn btn-secondary" 
                        style={{ display: 'flex', alignItems: 'center', gap: '8px' }}
                        onClick={async () => {
                            if (!window.confirm("Are you sure you want to retrain the ML model with the newly collected datasets? This may take some time.")) return;
                            setIsRetraining(true);
                            setRetrainMsg("Triggering model training...");
                            try {
                                const res = await fetch('http://localhost:5000/train/image-model', { method: 'POST' });
                                if(res.ok) {
                                    setRetrainMsg("Training started in background successfully!");
                                    setTimeout(() => setRetrainMsg(""), 5000);
                                } else {
                                    setRetrainMsg("Failed to start training. Is ML service running?");
                                }
                            } catch (e) {
                                setRetrainMsg("Error connecting to ML service.");
                            } finally {
                                setIsRetraining(false);
                            }
                        }}
                        disabled={isRetraining}
                    >
                        <BrainCircuit size={18} />
                        {isRetraining ? "Triggering..." : "Retrain ML Model"}
                    </button>
                    <div style={{ 
                        display: 'flex', alignItems: 'center', 
                        background: 'white', 
                        border: '1px solid var(--border)',
                        borderRadius: '8px',
                        padding: '8px 16px'
                    }}>
                        <Calendar size={18} color="var(--text-muted)" style={{ marginRight: '8px' }} />
                        <span style={{ color: 'var(--text-muted)' }}>Last 30 Days</span>
                    </div>
                </div>
            </div>

            {retrainMsg && (
                <div style={{ padding: '12px', background: '#dbeafe', color: '#1e40af', borderRadius: '8px', marginBottom: '24px' }}>
                    {retrainMsg}
                </div>
            )}

            {/* Metric Cards Row */}
            <div className="flex gap-6 mb-8">
                <div className="card flex-1">
                    <div style={{ color: 'var(--text-muted)', marginBottom: '16px' }}>Total Volume (GMV)</div>
                    <div style={{ fontSize: '1.75rem', fontWeight: 'bold' }}>RM {metrics?.gmv || 0}</div>
                </div>
                <div className="card flex-1">
                    <div style={{ color: 'var(--text-muted)', marginBottom: '16px' }}>Completed Transactions</div>
                    <div style={{ fontSize: '1.75rem', fontWeight: 'bold' }}>{metrics?.completed_transactions || 0}</div>
                </div>
                <div className="card flex-1" style={{ background: '#f0fdf4', borderColor: '#bbf7d0' }}>
                    <div style={{ color: '#16a34a', marginBottom: '16px' }}>Platform CO2 Saved</div>
                    <div style={{ fontSize: '1.75rem', fontWeight: 'bold', color: '#15803d' }}>
                        {metrics?.carbon_saved_kg ? Number(metrics.carbon_saved_kg).toFixed(2) : 0} kg
                    </div>
                </div>
                <div className="card flex-1" style={{ background: '#fef2f2', borderColor: '#fecaca' }}>
                    <div style={{ color: '#dc2626', marginBottom: '16px' }}>Active Users / Total</div>
                    <div style={{ fontSize: '1.75rem', fontWeight: 'bold', color: '#b91c1c' }}>
                        {metrics?.active_users || 0} <span style={{ fontSize: '1rem', color: '#f87171' }}>/ {metrics?.total_users || 0}</span>
                    </div>
                </div>
            </div>

            {/* Charts Row */}
            <div className="flex gap-6">
                <div className="card flex-col" style={{ flex: 2, height: '400px' }}>
                    <h3 style={{ margin: '0 0 1.5rem 0', fontSize: '1rem' }}>Daily Sales (GMV) - Last 30 Days</h3>
                    <div style={{ flex: 1, width: '100%' }}>
                        <ResponsiveContainer width="100%" height="100%">
                            <LineChart data={metrics?.daily_sales || []}>
                                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e5e7eb" />
                                <XAxis dataKey="date" axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: '#6b7280' }} dy={10} />
                                <YAxis axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: '#6b7280' }} dx={-10} />
                                <Tooltip 
                                    contentStyle={{ borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgba(0,0,0,0.1)' }}
                                    formatter={(value) => [`RM ${value}`, 'Sales']}
                                />
                                <Line type="monotone" dataKey="sales" stroke="var(--primary)" strokeWidth={3} dot={false} activeDot={{ r: 6 }} />
                            </LineChart>
                        </ResponsiveContainer>
                    </div>
                </div>

                <div className="card flex-col" style={{ flex: 1, height: '400px' }}>
                    <h3 style={{ margin: '0 0 1.5rem 0', fontSize: '1rem' }}>Top Eco-Categories (Carbon)</h3>
                    <div style={{ flex: 1, width: '100%', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
                        <ResponsiveContainer width="100%" height={220}>
                            <PieChart>
                                <Pie
                                    data={metrics?.category_distribution || []}
                                    cx="50%"
                                    cy="50%"
                                    innerRadius={60}
                                    outerRadius={90}
                                    paddingAngle={2}
                                    dataKey="value"
                                >
                                    {(metrics?.category_distribution || []).map((entry, index) => (
                                        <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                                    ))}
                                </Pie>
                                <Tooltip formatter={(value) => [`${Number(value).toFixed(2)} kg`, 'Carbon Saved']} />
                            </PieChart>
                        </ResponsiveContainer>
                        <div style={{ width: '100%', marginTop: '1rem' }}>
                            {(metrics?.category_distribution || []).slice(0,4).map((entry, index) => (
                                <div key={index} style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px', fontSize: '0.875rem' }}>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                        <div style={{ width: '10px', height: '10px', borderRadius: '50%', background: COLORS[index % COLORS.length] }} />
                                        <span>{entry.name}</span>
                                    </div>
                                    <span style={{ fontWeight: 'bold' }}>{Number(entry.value).toFixed(1)} kg</span>
                                </div>
                            ))}
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Analytics;
