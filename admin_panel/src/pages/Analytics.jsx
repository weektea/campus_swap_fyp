import React, { useState, useEffect } from 'react';
import { Calendar, Download, Printer, Users, BarChart3, ShieldAlert, Award } from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import api from '../services/api';

const Analytics = () => {
    const [metrics, setMetrics] = useState(null);
    const [loading, setLoading] = useState(true);
    const [range, setRange] = useState('last30'); // 'last30', 'quarter', 'semester', 'all'

    const fetchMetrics = async (selectedRange) => {
        setLoading(true);
        try {
            const res = await api.get(`/admin/metrics?range=${selectedRange}`);
            setMetrics(res.data);
        } catch (err) {
            console.error('Failed to fetch metrics', err);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchMetrics(range);
    }, [range]);

    const getRangeLabel = () => {
        switch (range) {
            case 'quarter': return 'Last Quarter (90 Days)';
            case 'semester': return 'Academic Semester (180 Days)';
            case 'all': return 'All Time';
            default: return 'Last 30 Days';
        }
    };

    const handleExportCSV = () => {
        if (!metrics) return;

        const csvRows = [
            ['Platform Performance & Sustainability Report'],
            [`Generated Date,${new Date().toLocaleDateString()}`],
            [`Reporting Period,${getRangeLabel()}`],
            [],
            ['Domain,Metric,Value,Unit/Details'],

            // User Ecology
            ['User Ecology', 'New Registrations', metrics.new_registrations, 'users registered in period'],
            ['User Ecology', 'Active Users', metrics.active_users, 'currently active'],
            ['User Ecology', 'Total Users', metrics.total_users, 'total registered'],

            // Environmental Impact
            ['Environmental Impact', 'Total Carbon Saved', `${Number(metrics.carbon_saved_kg).toFixed(2)}`, 'kg CO2e'],
            ['Environmental Impact', 'Top Eco-Category', `${metrics.top_eco_category} (${metrics.top_eco_category_percentage || 0}%)`, 'highest reduction contributor'],

            // Transactional Health
            ['Transactional Health', 'Total Successful Orders', metrics.completed_transactions, 'completed orders'],
            ['Transactional Health', 'Gross Merchandise Volume (GMV)', `RM ${metrics.gmv}`, 'total sales volume'],
            ['Transactional Health', 'Active Disputes', metrics.active_disputes, 'strictly New/Investigating disputes'],
            ['Transactional Health', 'Suspended Accounts', metrics.suspended_users, 'total accounts deactivated'],
            [],
            ['Category Carbon Contribution'],
            ['Category Name', 'Carbon Saved (kg CO2e)']
        ];

        (metrics.category_distribution || []).forEach(item => {
            csvRows.push([item.name, Number(item.value).toFixed(2)]);
        });

        const csvContent = csvRows.map(row => row.map(val => `"${val}"`).join(',')).join('\n');
        const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.setAttribute('href', url);
        link.setAttribute('download', `Campus_Swap_Sustainability_Report_${range}.csv`);
        link.style.visibility = 'hidden';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    };

    const handleExportPDF = () => {
        window.print();
    };

    if (loading) return <div className="p-8 text-center text-gray-500">Loading platform reports...</div>;

    const COLORS = ['#0d503c', '#2563eb', '#d97706', '#dc2626', '#8b5cf6'];

    return (
        <div>
            {/* Print Stylesheet Injection */}
            <style dangerouslySetInnerHTML={{
                __html: `
                @media print {
                    aside.sidebar,
                    main.main-content > header,
                    .no-print,
                    button,
                    select {
                        display: none !important;
                    }
                    main.main-content {
                        margin-left: 0 !important;
                        padding: 0 !important;
                        width: 100% !important;
                        min-height: auto !important;
                        background: white !important;
                        color: black !important;
                    }
                    .page-container {
                        padding: 0 !important;
                        margin: 0 !important;
                    }
                    body {
                        background-color: white !important;
                        color: black !important;
                        font-size: 12pt !important;
                    }
                    .print-report-header {
                        display: block !important;
                        text-align: center;
                        margin-bottom: 2rem;
                        border-bottom: 3px double #0d503c;
                        padding-bottom: 1rem;
                    }
                    .print-report-header h1 {
                        color: #0d503c !important;
                        margin: 0 0 0.5rem 0;
                        font-size: 24pt;
                    }
                    .print-report-header p {
                        margin: 0;
                        font-size: 10pt;
                        color: #4b5563;
                    }
                    .print-domain-section {
                        page-break-inside: avoid;
                        margin-bottom: 2.5rem;
                        border: 1px solid #d1d5db !important;
                        border-radius: 8px;
                        padding: 1.5rem;
                        background: white !important;
                    }
                    .print-domain-title {
                        border-bottom: 2px solid #0d503c !important;
                        color: #0d503c !important;
                        padding-bottom: 0.5rem;
                        margin-bottom: 1rem;
                        font-size: 14pt;
                        font-weight: bold;
                    }
                    .card {
                        box-shadow: none !important;
                        border: 1px solid #e5e7eb !important;
                        background: white !important;
                        page-break-inside: avoid;
                    }
                    .print-grid-3 {
                        display: grid !important;
                        grid-template-columns: repeat(3, 1fr) !important;
                        gap: 1rem !important;
                    }
                    .print-grid-4 {
                        display: grid !important;
                        grid-template-columns: repeat(4, 1fr) !important;
                        gap: 1rem !important;
                    }
                    .print-flex-row {
                        display: flex !important;
                        flex-direction: row !important;
                        gap: 1.5rem !important;
                    }
                    .print-flex-child {
                        flex: 1 !important;
                    }
                }
                .print-report-header {
                    display: none;
                }
            `}} />

            {/* Print Header */}
            <div className="print-report-header">
                <h1>Campus Swap Platform Performance & Sustainability Report</h1>
                <p>Generated on: {new Date().toLocaleDateString()} | Reporting Period: {getRangeLabel()}</p>
            </div>

            {/* Screen Action Bar */}
            <div className="flex justify-between items-center mb-8 no-print">
                <h1 style={{ fontSize: '1.5rem', margin: 0, fontWeight: 'bold', color: 'var(--primary)' }}>Platform Performance & Sustainability Report</h1>
                <div className="flex gap-4 items-center">
                    {/* Time Range Filter Selector */}
                    <div style={{ display: 'flex', alignItems: 'center', background: 'white', border: '1px solid var(--border)', borderRadius: '8px', padding: '4px 12px' }}>
                        <Calendar size={18} color="var(--text-muted)" style={{ marginRight: '8px' }} />
                        <select
                            value={range}
                            onChange={(e) => setRange(e.target.value)}
                            style={{ border: 'none', background: 'transparent', outline: 'none', color: 'var(--text-main)', fontSize: '0.9rem', cursor: 'pointer', padding: '4px 0' }}
                        >
                            <option value="last30">Last 30 Days</option>
                            <option value="quarter">Last Quarter (90 Days)</option>
                            <option value="semester">Academic Semester (180 Days)</option>
                            <option value="all">All Time</option>
                        </select>
                    </div>

                    {/* Export PDF Button */}
                    <button className="btn btn-outline flex items-center gap-2" onClick={handleExportPDF} style={{ padding: '0.5rem 1rem', fontSize: '0.9rem' }}>
                        <Printer size={16} />
                        <span>Export PDF</span>
                    </button>

                    {/* Export CSV Button */}
                    <button className="btn flex items-center gap-2" onClick={handleExportCSV} style={{ padding: '0.5rem 1rem', fontSize: '0.9rem' }}>
                        <Download size={16} />
                        <span>Export CSV</span>
                    </button>
                </div>
            </div>

            {/* SECTION 1: USER ECOLOGY */}
            <div className="print-domain-section mb-8">
                <h2 className="print-domain-title" style={{ fontSize: '1.2rem', margin: '0 0 1rem 0', display: 'flex', alignItems: 'center', gap: '8px', color: 'var(--primary)', borderBottom: '2px solid var(--border)', paddingBottom: '8px' }}>
                    <Users size={20} />
                    <span>User Ecology</span>
                </h2>
                <div className="flex gap-6 print-grid-3">
                    <div className="card flex-1">
                        <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '8px' }}>New Registrations</div>
                        <div style={{ fontSize: '1.75rem', fontWeight: 'bold' }}>{metrics?.new_registrations || 0}</div>
                        <div style={{ color: 'var(--text-muted)', fontSize: '0.75rem', marginTop: '4px' }}>Via campus email domain in range</div>
                    </div>
                    <div className="card flex-1">
                        <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '8px' }}>Active Users</div>
                        <div style={{ fontSize: '1.75rem', fontWeight: 'bold', color: 'var(--success)' }}>{metrics?.active_users || 0}</div>
                        <div style={{ color: 'var(--text-muted)', fontSize: '0.75rem', marginTop: '4px' }}>Current unbanned users</div>
                    </div>
                    <div className="card flex-1">
                        <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '8px' }}>Total Registered Users</div>
                        <div style={{ fontSize: '1.75rem', fontWeight: 'bold' }}>{metrics?.total_users || 0}</div>
                        <div style={{ color: 'var(--text-muted)', fontSize: '0.75rem', marginTop: '4px' }}>All-time total platform users</div>
                    </div>
                </div>
            </div>

            {/* SECTION 2: ENVIRONMENTAL IMPACT */}
            <div className="print-domain-section mb-8">
                <h2 className="print-domain-title" style={{ fontSize: '1.2rem', margin: '0 0 1rem 0', display: 'flex', alignItems: 'center', gap: '8px', color: 'var(--primary)', borderBottom: '2px solid var(--border)', paddingBottom: '8px' }}>
                    <Award size={20} />
                    <span>Environmental Impact</span>
                </h2>
                <div className="flex gap-6 mb-6 print-grid-3">
                    <div className="card flex-1" style={{ background: '#f0fdf4', borderColor: '#bbf7d0' }}>
                        <div style={{ color: '#16a34a', fontSize: '0.875rem', marginBottom: '8px', fontWeight: 'bold' }}>Total Carbon Saved</div>
                        <div style={{ fontSize: '1.75rem', fontWeight: 'bold', color: '#15803d' }}>
                            {metrics?.carbon_saved_kg ? Number(metrics.carbon_saved_kg).toFixed(2) : 0} kg CO2e
                        </div>
                        <div style={{ color: '#15803d', fontSize: '0.75rem', marginTop: '4px' }}>Avoided emissions from reuses</div>
                    </div>
                    <div className="card flex-1" style={{ background: '#f0fdf4', borderColor: '#bbf7d0' }}>
                        <div style={{ color: '#16a34a', fontSize: '0.875rem', marginBottom: '8px', fontWeight: 'bold' }}>Top Eco-Category</div>
                        <div style={{ fontSize: '1.4rem', fontWeight: 'bold', color: '#15803d', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                            {metrics?.top_eco_category || 'N/A'}
                        </div>
                        <div style={{ color: '#15803d', fontSize: '0.75rem', marginTop: '8px', fontWeight: 'bold' }}>
                            Contribution: {metrics?.top_eco_category_percentage || 0}%
                        </div>
                    </div>
                    <div className="card flex-1">
                        <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '8px' }}>Items Reused</div>
                        <div style={{ fontSize: '1.75rem', fontWeight: 'bold' }}>{metrics?.completed_transactions || 0}</div>
                        <div style={{ color: 'var(--text-muted)', fontSize: '0.75rem', marginTop: '4px' }}>Physically exchanged listings</div>
                    </div>
                </div>

                {/* Donut Chart and Data Table */}
                <div className="flex gap-6 print-flex-row">
                    <div className="card flex-col print-flex-child" style={{ flex: 1, display: 'flex', alignItems: 'center' }}>
                        <h3 style={{ margin: '0 0 1rem 0', fontSize: '0.9rem', width: '100%', textAlign: 'left' }}>Carbon Reduction Distribution</h3>
                        <ResponsiveContainer width="100%" height={180}>
                            <PieChart>
                                <Pie
                                    data={metrics?.category_distribution || []}
                                    cx="50%"
                                    cy="50%"
                                    innerRadius={50}
                                    outerRadius={75}
                                    paddingAngle={2}
                                    dataKey="value"
                                >
                                    {(metrics?.category_distribution || []).map((entry, index) => (
                                        <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                                    ))}
                                </Pie>
                                <Tooltip formatter={(value) => [`${Number(value).toFixed(2)} kg CO2e`, 'Carbon Saved']} />
                            </PieChart>
                        </ResponsiveContainer>
                    </div>
                    <div className="card flex-col print-flex-child" style={{ flex: 1.5 }}>
                        <h3 style={{ margin: '0 0 1rem 0', fontSize: '0.9rem' }}>Sustainability Metric Breakdown</h3>
                        <table style={{ width: '100%' }}>
                            <thead>
                                <tr>
                                    <th style={{ padding: '8px 12px' }}>Category</th>
                                    <th style={{ padding: '8px 12px', textAlign: 'right' }}>Carbon Savings</th>
                                </tr>
                            </thead>
                            <tbody>
                                {(metrics?.category_distribution || []).map((entry, index) => (
                                    <tr key={index}>
                                        <td style={{ padding: '8px 12px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                                            <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: COLORS[index % COLORS.length] }} />
                                            {entry.name}
                                        </td>
                                        <td style={{ padding: '8px 12px', textAlign: 'right', fontWeight: 'bold' }}>{Number(entry.value).toFixed(1)} kg CO2e</td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

            {/* SECTION 3: TRANSACTIONAL HEALTH */}
            <div className="print-domain-section mb-8">
                <h2 className="print-domain-title" style={{ fontSize: '1.2rem', margin: '0 0 1rem 0', display: 'flex', alignItems: 'center', gap: '8px', color: 'var(--primary)', borderBottom: '2px solid var(--border)', paddingBottom: '8px' }}>
                    <BarChart3 size={20} />
                    <span>Transactional Health</span>
                </h2>
                <div className="flex gap-6 mb-6 print-grid-4">
                    <div className="card flex-1">
                        <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '8px' }}>GMV Volume</div>
                        <div style={{ fontSize: '1.6rem', fontWeight: 'bold' }}>RM {metrics?.gmv || 0}</div>
                        <div style={{ color: 'var(--text-muted)', fontSize: '0.75rem', marginTop: '4px' }}>Total trade value in period</div>
                    </div>
                    <div className="card flex-1">
                        <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '8px' }}>Successful Trades</div>
                        <div style={{ fontSize: '1.6rem', fontWeight: 'bold' }}>{metrics?.completed_transactions || 0}</div>
                        <div style={{ color: 'var(--text-muted)', fontSize: '0.75rem', marginTop: '4px' }}>Trades completed successfully</div>
                    </div>
                    <div className="card flex-1" style={{ background: '#fef2f2', borderColor: '#fecaca' }}>
                        <div style={{ color: '#dc2626', fontSize: '0.875rem', marginBottom: '8px', fontWeight: 'bold' }}>Active Disputes</div>
                        <div style={{ fontSize: '1.6rem', fontWeight: 'bold', color: '#b91c1c' }}>{metrics?.active_disputes || 0}</div>
                        <div style={{ color: '#b91c1c', fontSize: '0.75rem', marginTop: '4px' }}>Strictly New or Investigating</div>
                    </div>
                    <div className="card flex-1" style={{ background: '#fef2f2', borderColor: '#fecaca' }}>
                        <div style={{ color: '#dc2626', fontSize: '0.875rem', marginBottom: '8px', fontWeight: 'bold' }}>Suspended Accounts</div>
                        <div style={{ fontSize: '1.6rem', fontWeight: 'bold', color: '#b91c1c' }}>{metrics?.suspended_users || 0}</div>
                        <div style={{ color: '#b91c1c', fontSize: '0.75rem', marginTop: '4px' }}>Banned due to policy violation</div>
                    </div>
                </div>

                {/* Sales Chart (Hidden on print to preserve A4 structure if necessary, or kept clean) */}
                <div className="card flex-col no-print" style={{ height: '280px' }}>
                    <h3 style={{ margin: '0 0 1rem 0', fontSize: '0.9rem' }}>GMV Sales Trend (RM)</h3>
                    <div style={{ flex: 1, width: '100%' }}>
                        <ResponsiveContainer width="100%" height={220}>
                            <LineChart data={metrics?.daily_sales || []}>
                                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e5e7eb" />
                                <XAxis dataKey="date" axisLine={false} tickLine={false} tick={{ fontSize: 10, fill: '#6b7280' }} dy={10} />
                                <YAxis axisLine={false} tickLine={false} tick={{ fontSize: 10, fill: '#6b7280' }} dx={-10} />
                                <Tooltip
                                    contentStyle={{ borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgba(0,0,0,0.1)' }}
                                    formatter={(value) => [`RM ${value}`, 'Sales']}
                                />
                                <Line type="monotone" dataKey="sales" stroke="#0d503c" strokeWidth={2.5} dot={false} activeDot={{ r: 5 }} />
                            </LineChart>
                        </ResponsiveContainer>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Analytics;
