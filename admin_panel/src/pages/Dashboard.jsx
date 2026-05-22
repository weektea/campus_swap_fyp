import React from 'react';
import { TrendingUp, TrendingDown, Circle } from 'lucide-react';

const Dashboard = () => {
    return (
        <div>
            {/* Stat Cards */}
            <div className="flex gap-6 mb-8">
                <div className="card flex-1">
                    <div className="flex justify-between items-center mb-4">
                        <span style={{ color: 'var(--text-muted)' }}>Pending Reports</span>
                        <div className="flex items-center gap-2" style={{ color: 'var(--danger)', fontWeight: 'bold' }}>
                            <TrendingUp size={16} />
                            <span>+3</span>
                        </div>
                    </div>
                    <div style={{ fontSize: '2rem', fontWeight: 300 }}>14</div>
                </div>
                
                <div className="card flex-1">
                    <div className="flex justify-between items-center mb-4">
                        <span style={{ color: 'var(--text-muted)' }}>Open Disputes</span>
                    </div>
                    <div style={{ fontSize: '2rem', fontWeight: 300 }}>5</div>
                </div>

                <div className="card flex-1">
                    <div className="flex justify-between items-center mb-4">
                        <span style={{ color: 'var(--text-muted)' }}>My Locked Tasks</span>
                        <Circle size={12} fill="var(--success)" color="var(--success)" />
                    </div>
                    <div style={{ fontSize: '2rem', fontWeight: 300 }}>2</div>
                </div>
            </div>

            {/* Recent Open Tasks Table */}
            <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
                <div style={{ padding: '1.5rem', borderBottom: '1px solid var(--border)' }}>
                    <h2 style={{ margin: 0, fontSize: '1.25rem' }}>Recent Open Tasks</h2>
                </div>
                <table>
                    <thead>
                        <tr>
                            <th>TICKET ID</th>
                            <th>TYPE</th>
                            <th>TARGET</th>
                            <th>SUBMITTED</th>
                            <th>STATUS</th>
                            <th>ACTION</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td style={{ color: 'var(--text-muted)' }}>#REP-102</td>
                            <td style={{ color: 'var(--text-muted)' }}>Fake Item</td>
                            <td style={{ color: 'var(--text-muted)' }}>Listing: Wooden Chair</td>
                            <td style={{ color: 'var(--text-muted)' }}>2 hrs ago</td>
                            <td>
                                <span style={{ padding: '4px 12px', background: '#f3f4f6', borderRadius: '12px', color: 'var(--text-muted)', fontSize: '0.75rem', fontWeight: 'bold' }}>
                                    Open
                                </span>
                            </td>
                            <td>
                                <button className="btn" style={{ padding: '8px 16px', fontSize: '0.875rem' }}>Review</button>
                            </td>
                        </tr>
                        <tr>
                            <td style={{ color: 'var(--text-muted)' }}>#DIS-88</td>
                            <td style={{ color: 'var(--text-muted)' }}>Item not as described</td>
                            <td style={{ color: 'var(--text-muted)' }}>Order #TRX-99</td>
                            <td style={{ color: 'var(--text-muted)' }}>5 hrs ago</td>
                            <td>
                                <span style={{ padding: '4px 12px', background: '#eff6ff', borderRadius: '12px', color: '#1d4ed8', fontSize: '0.75rem', fontWeight: 'bold' }}>
                                    Locked (Alex)
                                </span>
                            </td>
                            <td>
                                <button className="btn" style={{ padding: '8px 16px', fontSize: '0.875rem', background: '#e5e7eb', color: '#4b5563' }} disabled>
                                    Review
                                </button>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    );
};

export default Dashboard;
