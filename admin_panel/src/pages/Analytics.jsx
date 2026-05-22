import React from 'react';
import { Download, Calendar } from 'lucide-react';

const Analytics = () => {
    return (
        <div>
            <div className="flex justify-between items-center mb-8">
                <h1 style={{ fontSize: '1.5rem', margin: 0 }}>System Metrics</h1>
                <div className="flex gap-4">
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
                    <button className="btn flex items-center gap-2">
                        <Download size={16} />
                        Export PDF
                    </button>
                    <button className="btn flex items-center gap-2">
                        <Download size={16} />
                        Export CSV
                    </button>
                </div>
            </div>

            {/* Metric Cards Row */}
            <div className="flex gap-6 mb-8">
                <div className="card flex-1">
                    <div style={{ color: 'var(--text-muted)', marginBottom: '16px' }}>Total Volume</div>
                    <div style={{ fontSize: '1.75rem', fontWeight: 'bold' }}>RM 45,200</div>
                </div>
                <div className="card flex-1">
                    <div style={{ color: 'var(--text-muted)', marginBottom: '16px' }}>Active Users</div>
                    <div style={{ fontSize: '1.75rem', fontWeight: 'bold' }}>3,421</div>
                </div>
                <div className="card flex-1" style={{ background: '#f0fdf4', borderColor: '#bbf7d0' }}>
                    <div style={{ color: '#16a34a', marginBottom: '16px' }}>Platform CO2 Saved</div>
                    <div style={{ fontSize: '1.75rem', fontWeight: 'bold', color: '#15803d' }}>1,250 kg</div>
                </div>
                <div className="card flex-1" style={{ background: '#fef2f2', borderColor: '#fecaca' }}>
                    <div style={{ color: '#dc2626', marginBottom: '16px' }}>Open Disputes</div>
                    <div style={{ fontSize: '1.75rem', fontWeight: 'bold', color: '#b91c1c' }}>14</div>
                </div>
            </div>

            {/* Charts Row */}
            <div className="flex gap-6">
                <div className="card flex-col" style={{ flex: 2, height: '350px' }}>
                    <h3 style={{ margin: '0 0 1.5rem 0', fontSize: '1rem' }}>Daily Transactions</h3>
                    <div style={{ flex: 1, display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between' }}>
                        {[...Array(30)].map((_, i) => (
                            <div 
                                key={i} 
                                style={{ 
                                    width: '12px', 
                                    height: `${Math.floor(Math.random() * 60 + 20)}%`, 
                                    background: 'var(--primary)',
                                    borderRadius: '4px 4px 0 0'
                                }} 
                            />
                        ))}
                    </div>
                    <div className="flex justify-between" style={{ marginTop: '12px', color: 'var(--text-muted)', fontSize: '0.75rem' }}>
                        <span>Day 1</span>
                        <span>Day 15</span>
                        <span>Day 30</span>
                    </div>
                </div>

                <div className="card flex-col" style={{ flex: 1, height: '350px' }}>
                    <h3 style={{ margin: '0 0 1.5rem 0', fontSize: '1rem' }}>Listings by Category</h3>
                    <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        {/* Placeholder CSS donut chart */}
                        <div style={{ 
                            width: '150px', height: '150px', 
                            borderRadius: '50%', 
                            background: 'conic-gradient(#16a34a 0% 40%, #2563eb 40% 75%, #f59e0b 75% 100%)',
                            position: 'relative',
                            display: 'flex', alignItems: 'center', justifyContent: 'center'
                        }}>
                            <div style={{ width: '100px', height: '100px', background: 'white', borderRadius: '50%' }}></div>
                        </div>
                    </div>
                    <div>
                        <div className="flex justify-between items-center mb-2">
                            <div className="flex items-center gap-2">
                                <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: '#16a34a' }}></div>
                                <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Books</span>
                            </div>
                            <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>40%</span>
                        </div>
                        <div className="flex justify-between items-center mb-2">
                            <div className="flex items-center gap-2">
                                <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: '#2563eb' }}></div>
                                <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Electronics</span>
                            </div>
                            <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>35%</span>
                        </div>
                        <div className="flex justify-between items-center">
                            <div className="flex items-center gap-2">
                                <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: '#f59e0b' }}></div>
                                <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Furniture</span>
                            </div>
                            <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>25%</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Analytics;
