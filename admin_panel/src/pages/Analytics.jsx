// =============================================================================
// TODO (WIP): Section 4 "Growth & Predictive Analytics" charts are not yet
// fully wired up. The following backend data fields are still missing / need
// to be verified on the /admin/metrics and /admin/analytics endpoints:
//   - growth_labels / growth_data        → Monthly User Growth line chart
//   - earnings_labels / earnings_actual  → Earnings bar chart
//   - earnings_prediction / prediction_labels / prediction_values → Trend line
//   - carbon_by_category                 → Carbon Savings by Category pie
//   - order_type_breakdown               → Sale vs Rent split pie
//   - anomaly_logs                       → Anomaly Behavior Logs table
// Until these are returned correctly, Section 4 will render empty charts.
// =============================================================================
import React, { useState, useEffect } from 'react';
import { Calendar, Download, Printer, Users, BarChart3, ShieldAlert, Award } from 'lucide-react';
import { LineChart, Line, BarChart, Bar, ComposedChart, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import api from '../services/api';


const Analytics = () => {
    const [metrics, setMetrics] = useState(null);
    const [loading, setLoading] = useState(true);
    const [range, setRange] = useState('last30'); // 'last30', 'quarter', 'semester', 'all'
    const [startDate, setStartDate] = useState(() => {
        const d = new Date();
        d.setDate(d.getDate() - 30);
        return d.toISOString().split('T')[0];
    });
    const [endDate, setEndDate] = useState(() => {
        return new Date().toISOString().split('T')[0];
    });

    const fetchMetrics = async (selectedRange) => {
        setLoading(true);
        try {
            const [metricsRes, analyticsRes, onboardingRes] = await Promise.all([
                api.get(`/admin/metrics?range=${selectedRange}`),
                api.get('/admin/analytics'),
                api.get('/admin/analytics/onboarding').catch(() => ({ data: {} }))
            ]);
            setMetrics({ ...metricsRes.data, ...analyticsRes.data, onboarding: onboardingRes.data });
        } catch (err) {
            console.error('Failed to fetch metrics', err);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        if (range !== 'custom') {
            fetchMetrics(range);
        }
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

    const handleExportEnvironmentalCSV = async () => {
        if (!startDate || !endDate) {
            alert('Please select both start and end dates.');
            return;
        }
        try {
            const res = await api.get(`/admin/export-report?startDate=${startDate}&endDate=${endDate}`, { responseType: 'blob' });
            const url = window.URL.createObjectURL(new Blob([res.data]));
            const link = document.createElement('a');
            link.href = url;
            link.setAttribute('download', `Environmental_Impact_Report_${startDate}_to_${endDate}.csv`);
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            window.URL.revokeObjectURL(url);
        } catch (err) {
            console.error(err);
            alert('Failed to export environmental CSV report.');
        }
    };

    const handleExportPDF = () => {
        window.print();
    };

    const handleUnifiedExportCSV = () => {
        if (range === 'custom') {
            handleExportEnvironmentalCSV();
        } else {
            handleExportCSV();
        }
    };

    if (loading) return <div className="p-8 text-center text-gray-500">Loading platform reports...</div>;

    const COLORS = ['#0d503c', '#2563eb', '#d97706', '#dc2626', '#8b5cf6'];

    // FYP Charts Data
    const growthData = (metrics?.growth_labels || []).map((label, idx) => ({
        name: label,
        registrations: metrics.growth_data?.[idx] || 0
    }));

    const actualEarnings = metrics?.earnings_actual || [];
    const predValues = metrics?.prediction_values || [];
    const earningsLabels = metrics?.earnings_labels || [];
    const predLabels = metrics?.prediction_labels || [];

    const combinedEarningsData = [];
    earningsLabels.forEach((label, idx) => {
        combinedEarningsData.push({ name: label, actual: actualEarnings[idx] || 0, prediction: null });
    });
    predLabels.forEach((label, idx) => {
        combinedEarningsData.push({
            name: label,
            actual: idx === 0 && actualEarnings.length > 0 ? actualEarnings[actualEarnings.length - 1] : null,
            prediction: predValues[idx] || 0
        });
    });

    const orderTypeData = [
        { name: 'Sale', value: metrics?.order_type_breakdown?.sale || 0 },
        { name: 'Rent', value: metrics?.order_type_breakdown?.rent || 0 }
    ];

    return (
        <div>
            {/* Print Stylesheet Injection */}
            <style dangerouslySetInnerHTML={{
                __html: `
                .print-domain-section {
                    margin-bottom: 3.5rem;
                }
                .mb-8 {
                    margin-bottom: 2rem;
                }
                .mb-6 {
                    margin-bottom: 1.5rem;
                }
                .mb-4 {
                    margin-bottom: 1rem;
                }
                .mt-6 {
                    margin-top: 1.5rem;
                }
                .mt-4 {
                    margin-top: 1rem;
                }
                .flex-1 {
                    flex: 1 1 0%;
                }
                .flex-wrap {
                    flex-wrap: wrap;
                }
                .gap-3 {
                    gap: 0.75rem;
                }
                .gap-8 {
                    gap: 2rem;
                }
                .dashboard-grid-3 {
                    display: grid;
                    grid-template-columns: repeat(3, 1fr);
                    gap: 1.5rem;
                }
                .dashboard-grid-4 {
                    display: grid;
                    grid-template-columns: repeat(4, 1fr);
                    gap: 1.5rem;
                }
                .analytics-grid-2 {
                    display: grid;
                    grid-template-columns: 1fr 1fr;
                    gap: 1.5rem;
                    width: 100%;
                }
                .analytics-grid-2 > div {
                    min-width: 0;
                }
                .chart-container-card {
                    background: var(--card-bg);
                    border: 1px solid var(--border);
                    border-radius: 16px;
                    padding: 1.5rem;
                    box-shadow: 0 1px 3px rgba(0,0,0,0.02);
                    transition: transform 0.2s, box-shadow 0.2s;
                    min-width: 0;
                    overflow: hidden;
                    position: relative;
                }
                .chart-container-card:hover {
                    box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05), 0 4px 6px -2px rgba(0, 0, 0, 0.02);
                }
                .chart-title {
                    font-size: 0.95rem;
                    font-weight: 700;
                    color: var(--text-main);
                    margin: 0 0 4px 0;
                    display: flex;
                    align-items: center;
                    gap: 8px;
                }
                .chart-subtitle {
                    font-size: 0.75rem;
                    color: var(--text-muted);
                    margin: 0 0 1.25rem 0;
                }
                .stat-pill {
                    display: inline-flex;
                    align-items: center;
                    gap: 6px;
                    padding: 3px 8px;
                    background: rgba(13, 80, 60, 0.08);
                    color: var(--primary);
                    border-radius: 6px;
                    font-size: 0.75rem;
                    font-weight: 600;
                }
                .stat-value {
                    font-size: 1.75rem;
                    font-weight: 800;
                    color: var(--text-main);
                    margin-top: 4px;
                }
                .anomaly-badge {
                    display: inline-block;
                    padding: 2px 8px;
                    background: #fee2e2;
                    color: #dc2626;
                    border-radius: 6px;
                    font-size: 0.725rem;
                    font-weight: 600;
                }
                .custom-legend-item {
                    display: flex;
                    align-items: center;
                    gap: 10px;
                    padding: 8px 12px;
                    border-radius: 8px;
                    background: #f9fafb;
                    border: 1px solid var(--border);
                }
                @media (max-width: 1024px) {
                    .dashboard-grid-3 {
                        grid-template-columns: repeat(2, 1fr);
                    }
                    .dashboard-grid-4 {
                        grid-template-columns: repeat(2, 1fr);
                    }
                    .analytics-grid-2 {
                        grid-template-columns: 1fr;
                    }
                }
                @media (max-width: 640px) {
                    .dashboard-grid-3 {
                        grid-template-columns: 1fr;
                    }
                    .dashboard-grid-4 {
                        grid-template-columns: 1fr;
                    }
                }
                @media print {
                    * {
                        -webkit-print-color-adjust: exact !important;
                        print-color-adjust: exact !important;
                    }
                    @page {
                        margin: 12mm 15mm;
                        size: portrait;
                    }
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
                        color: #1f2937 !important;
                        font-size: 10pt !important;
                        line-height: 1.4;
                    }
                    .print-report-header {
                        display: block !important;
                        text-align: left;
                        margin-bottom: 2rem;
                        border-bottom: 3px double #0d503c;
                        padding-bottom: 1.25rem;
                    }
                    .print-report-header h1 {
                        color: #0d503c !important;
                        margin: 0 0 0.4rem 0;
                        font-size: 20pt;
                        font-weight: 800;
                        letter-spacing: -0.5px;
                    }
                    .print-report-header p {
                        margin: 0;
                        font-size: 9.5pt;
                        color: #4b5563;
                    }
                    .print-report-footer {
                        display: block !important;
                        position: fixed;
                        bottom: 0;
                        left: 0;
                        right: 0;
                        text-align: center;
                        font-size: 8pt;
                        color: #9ca3af;
                        border-top: 1px solid #e5e7eb;
                        padding-top: 6px;
                    }
                    .print-domain-section {
                        page-break-inside: avoid;
                        break-inside: avoid;
                        margin-bottom: 2rem !important;
                        border: 1px solid #d1d5db !important;
                        border-radius: 10px;
                        padding: 1.25rem;
                        background: white !important;
                    }
                    .print-domain-title {
                        border-bottom: 2px solid #0d503c !important;
                        color: #0d503c !important;
                        padding-bottom: 0.5rem;
                        margin-bottom: 1rem;
                        font-size: 13pt;
                        font-weight: 700;
                    }
                    .card, .chart-container-card {
                        box-shadow: none !important;
                        border: 1px solid #e5e7eb !important;
                        page-break-inside: avoid;
                        break-inside: avoid;
                    }
                    .print-grid-3 {
                        display: grid !important;
                        grid-template-columns: repeat(3, 1fr) !important;
                        gap: 0.85rem !important;
                    }
                    .print-grid-4 {
                        display: grid !important;
                        grid-template-columns: repeat(4, 1fr) !important;
                        gap: 0.85rem !important;
                    }
                    .print-grid-2, .analytics-grid-2 {
                        display: grid !important;
                        grid-template-columns: 1fr 1fr !important;
                        gap: 1rem !important;
                    }
                    .print-flex-row {
                        display: flex !important;
                        flex-direction: row !important;
                        gap: 1rem !important;
                    }
                    .print-flex-child {
                        flex: 1 !important;
                    }
                    svg {
                        max-width: 100% !important;
                    }
                }
                .print-report-header, .print-report-footer {
                    display: none;
                }
            `}} />

            {/* Print Header */}
            <div className="print-report-header">
                <h1>Campus Swap Platform Performance & Sustainability Report</h1>
                <p>Generated on: {new Date().toLocaleDateString()} | Reporting Period: {getRangeLabel()}</p>
            </div>

            {/* Screen Action Bar */}
            <div className="flex justify-between items-center mb-8 no-print" style={{ flexWrap: 'wrap', gap: '16px', borderBottom: '1px solid var(--border)', paddingBottom: '1.5rem' }}>
                <div>
                    <h1 style={{ fontSize: '1.75rem', margin: 0, fontWeight: 'bold', color: 'var(--primary)' }}>Platform Performance & Analytics</h1>
                    <p style={{ margin: '4px 0 0 0', fontSize: '0.875rem', color: 'var(--text-muted)' }}>Monitor platform activity, user ecology, and export performance reports.</p>
                </div>
                <div className="flex items-center gap-4" style={{ flexWrap: 'wrap' }}>
                    {/* Time Range Filter Selector */}
                    <div style={{ display: 'flex', alignItems: 'center', background: 'white', border: '1px solid var(--border)', borderRadius: '8px', padding: '6px 12px' }}>
                        <Calendar size={18} color="var(--text-muted)" style={{ marginRight: '8px' }} />
                        <select
                            value={range}
                            onChange={(e) => setRange(e.target.value)}
                            style={{ border: 'none', background: 'transparent', outline: 'none', color: 'var(--text-main)', fontSize: '0.9rem', cursor: 'pointer', fontWeight: '500' }}
                        >
                            <option value="last30">Last 30 Days (Summary)</option>
                            <option value="quarter">Last Quarter (Summary)</option>
                            <option value="semester">Academic Semester (Summary)</option>
                            <option value="all">All Time (Summary)</option>
                            <option value="custom">Custom Date Range (Detailed Environmental)</option>
                        </select>
                    </div>

                    {/* Custom Date Pickers (Shown inline only when Custom Date Range is selected) */}
                    {range === 'custom' && (
                        <div className="flex items-center gap-3" style={{ background: 'rgba(13, 80, 60, 0.04)', padding: '6px 12px', borderRadius: '8px', border: '1px dashed rgba(13, 80, 60, 0.2)' }}>
                            <div className="flex items-center gap-2">
                                <span style={{ fontSize: '0.8rem', color: 'var(--primary)', fontWeight: '600' }}>Start</span>
                                <input 
                                    type="date" 
                                    className="input" 
                                    style={{ margin: 0, padding: '4px 8px', width: 'auto', fontSize: '0.8rem', height: '32px' }} 
                                    value={startDate} 
                                    onChange={(e) => setStartDate(e.target.value)} 
                                />
                            </div>
                            <div className="flex items-center gap-2">
                                <span style={{ fontSize: '0.8rem', color: 'var(--primary)', fontWeight: '600' }}>End</span>
                                <input 
                                    type="date" 
                                    className="input" 
                                    style={{ margin: 0, padding: '4px 8px', width: 'auto', fontSize: '0.8rem', height: '32px' }} 
                                    value={endDate} 
                                    onChange={(e) => setEndDate(e.target.value)} 
                                />
                            </div>
                        </div>
                    )}

                    <div className="flex gap-2">
                        {/* Print PDF Button */}
                        <button className="btn btn-outline flex items-center gap-2" onClick={handleExportPDF} style={{ padding: '0.6rem 1.2rem', fontSize: '0.9rem', height: '42px' }}>
                            <Printer size={16} />
                            <span>Print PDF</span>
                        </button>

                        {/* Export CSV Button (Unified Action) */}
                        <button className="btn flex items-center gap-2" onClick={handleUnifiedExportCSV} style={{ padding: '0.6rem 1.2rem', fontSize: '0.9rem', height: '42px' }}>
                            <Download size={16} />
                            <span>Export CSV</span>
                        </button>
                    </div>
                </div>
            </div>

            {/* SECTION 1: USER ECOLOGY */}
            <div className="print-domain-section mb-8">
                <h2 className="print-domain-title" style={{ fontSize: '1.2rem', margin: '0 0 1rem 0', display: 'flex', alignItems: 'center', gap: '8px', color: 'var(--primary)', borderBottom: '2px solid var(--border)', paddingBottom: '8px' }}>
                    <Users size={20} />
                    <span>User Ecology</span>
                </h2>
                <div className="dashboard-grid-3 print-grid-3">
                    <div className="card flex-1">
                        <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '8px' }}>New Registrations</div>
                        <div className="stat-value">{metrics?.new_registrations || 0}</div>
                        <div style={{ color: 'var(--text-muted)', fontSize: '0.75rem', marginTop: '4px' }}>Via campus email domain in range</div>
                    </div>
                    <div className="card flex-1">
                        <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '8px' }}>Active Users</div>
                        <div className="stat-value" style={{ color: 'var(--success)' }}>{metrics?.active_users || 0}</div>
                        <div style={{ color: 'var(--text-muted)', fontSize: '0.75rem', marginTop: '4px' }}>Current unbanned users</div>
                    </div>
                    <div className="card flex-1">
                        <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '8px' }}>Total Registered Users</div>
                        <div className="stat-value">{metrics?.total_users || 0}</div>
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
                <div className="dashboard-grid-3 mb-6 print-grid-3">
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
                        <div className="stat-value">{metrics?.completed_transactions || 0}</div>
                        <div style={{ color: 'var(--text-muted)', fontSize: '0.75rem', marginTop: '4px' }}>Physically exchanged listings</div>
                    </div>
                </div>

                {/* Donut Chart and Data Table */}
                <div className="flex gap-6 print-flex-row" style={{ flexWrap: 'wrap' }}>
                    <div className="card flex-col print-flex-child" style={{ flex: 1, display: 'flex', alignItems: 'center', minWidth: '300px' }}>
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
                    <div className="card flex-col print-flex-child" style={{ flex: 1.5, minWidth: '300px' }}>
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

            {/* ONBOARDING & EXPLICIT INTEREST ANALYTICS */}
            <div className="print-domain-section mb-8">
                <h2 className="print-domain-title" style={{ fontSize: '1.2rem', margin: '0 0 1rem 0', display: 'flex', alignItems: 'center', gap: '8px', color: 'var(--primary)', borderBottom: '2px solid var(--border)', paddingBottom: '8px' }}>
                    <Users size={20} />
                    <span>Onboarding & Explicit Preference Elicitation</span>
                </h2>
                <div className="dashboard-grid-2 mb-6" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem' }}>
                    {/* Doughnut Chart: Student Intent Distribution */}
                    <div className="card flex-col" style={{ height: '320px' }}>
                        <h3 style={{ margin: '0 0 0.5rem 0', fontSize: '0.95rem', fontWeight: 'bold' }}>Student Platform Intent Distribution</h3>
                        <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginBottom: '1rem' }}>Primary goal selected during 1st-time user onboarding</p>
                        <div style={{ flex: 1, width: '100%' }}>
                            <ResponsiveContainer width="100%" height={210}>
                                <PieChart>
                                    <Pie
                                        data={metrics?.onboarding?.intent_distribution || [
                                            { name: 'Buy', count: 0 },
                                            { name: 'Rent', count: 0 },
                                            { name: 'Sell', count: 0 },
                                            { name: 'Browse', count: 0 }
                                        ]}
                                        cx="50%"
                                        cy="50%"
                                        innerRadius={45}
                                        outerRadius={75}
                                        paddingAngle={5}
                                        dataKey="count"
                                    >
                                        {(metrics?.onboarding?.intent_distribution || []).map((entry, index) => (
                                            <Cell key={`intent-cell-${index}`} fill={COLORS[index % COLORS.length]} />
                                        ))}
                                    </Pie>
                                    <Tooltip formatter={(value, name) => [`${value} students`, name]} />
                                    <Legend iconType="circle" wrapperStyle={{ fontSize: '11px' }} />
                                </PieChart>
                            </ResponsiveContainer>
                        </div>
                    </div>

                    {/* Bar Chart: Top Selected Interest Categories */}
                    <div className="card flex-col" style={{ height: '320px' }}>
                        <h3 style={{ margin: '0 0 0.5rem 0', fontSize: '0.95rem', fontWeight: 'bold' }}>Top Onboarding Interest Categories</h3>
                        <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginBottom: '1rem' }}>Used by ML Cold-Start engine for Day 1 personalization</p>
                        <div style={{ flex: 1, width: '100%' }}>
                            <ResponsiveContainer width="100%" height={210}>
                                <BarChart data={(metrics?.onboarding?.top_categories || []).slice(0, 6)} layout="vertical">
                                    <CartesianGrid strokeDasharray="3 3" horizontal={false} stroke="#e5e7eb" />
                                    <XAxis type="number" axisLine={false} tickLine={false} tick={{ fontSize: 10, fill: '#6b7280' }} />
                                    <YAxis dataKey="name" type="category" width={110} axisLine={false} tickLine={false} tick={{ fontSize: 10, fill: '#6b7280' }} />
                                    <Tooltip formatter={(value) => [`${value} selections`, 'Popularity']} />
                                    <Bar dataKey="count" fill="#0d503c" radius={[0, 6, 6, 0]} barSize={16} />
                                </BarChart>
                            </ResponsiveContainer>
                        </div>
                    </div>
                </div>
            </div>

            {/* SECTION 3: TRANSACTIONAL HEALTH */}
            <div className="print-domain-section mb-8">
                <h2 className="print-domain-title" style={{ fontSize: '1.2rem', margin: '0 0 1rem 0', display: 'flex', alignItems: 'center', gap: '8px', color: 'var(--primary)', borderBottom: '2px solid var(--border)', paddingBottom: '8px' }}>
                    <BarChart3 size={20} />
                    <span>Transactional Health</span>
                </h2>
                <div className="dashboard-grid-4 mb-6 print-grid-4">
                    <div className="card flex-1">
                        <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '8px' }}>GMV Volume</div>
                        <div className="stat-value">RM {metrics?.gmv || 0}</div>
                        <div style={{ color: 'var(--text-muted)', fontSize: '0.75rem', marginTop: '4px' }}>Total trade value in period</div>
                    </div>
                    <div className="card flex-1">
                        <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '8px' }}>Successful Trades</div>
                        <div className="stat-value">{metrics?.completed_transactions || 0}</div>
                        <div style={{ color: 'var(--text-muted)', fontSize: '0.75rem', marginTop: '4px' }}>Trades completed successfully</div>
                    </div>
                    <div className="card flex-1" style={{ background: '#fef2f2', borderColor: '#fecaca' }}>
                        <div style={{ color: '#dc2626', fontSize: '0.875rem', marginBottom: '8px', fontWeight: 'bold' }}>Active Disputes</div>
                        <div className="stat-value" style={{ color: '#b91c1c' }}>{metrics?.active_disputes || 0}</div>
                        <div style={{ color: '#b91c1c', fontSize: '0.75rem', marginTop: '4px' }}>Strictly New or Investigating</div>
                    </div>
                    <div className="card flex-1" style={{ background: '#fef2f2', borderColor: '#fecaca' }}>
                        <div style={{ color: '#dc2626', fontSize: '0.875rem', marginBottom: '8px', fontWeight: 'bold' }}>Suspended Accounts</div>
                        <div className="stat-value" style={{ color: '#b91c1c' }}>{metrics?.suspended_users || 0}</div>
                        <div style={{ color: '#b91c1c', fontSize: '0.75rem', marginTop: '4px' }}>Banned due to policy violation</div>
                    </div>
                </div>

                {/* Sales Chart */}
                <div className="card flex-col" style={{ height: '280px' }}>
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

            {/* SECTION 4: GROWTH & PREDICTIVE ANALYTICS */}
            <div className="print-domain-section mb-8">
                <h2 className="print-domain-title" style={{ fontSize: '1.2rem', margin: '0 0 1.5rem 0', display: 'flex', alignItems: 'center', gap: '8px', color: 'var(--primary)', borderBottom: '2px solid var(--border)', paddingBottom: '8px' }}>
                    <BarChart3 size={20} />
                    <span>Growth & Predictive Analytics</span>
                </h2>

                <div className="analytics-grid-2">
                    {/* Left Column: Charts */}
                    <div className="flex flex-col gap-6">
                        {/* Monthly User Growth */}
                        <div className="chart-container-card" style={{ height: '330px', display: 'flex', flexDirection: 'column' }}>
                            <h3 className="chart-title">📈 Monthly User Growth</h3>
                            <p className="chart-subtitle">Monthly sign-ups of new user accounts</p>
                            <div style={{ flex: 1, width: '100%', height: '220px', minWidth: 0, position: 'relative' }}>
                                <ResponsiveContainer width="100%" height="100%">
                                    <LineChart data={growthData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                                        <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e5e7eb" />
                                        <XAxis dataKey="name" tick={{ fontSize: 10, fill: '#6b7280' }} tickLine={false} axisLine={false} />
                                        <YAxis tick={{ fontSize: 10, fill: '#6b7280' }} tickLine={false} axisLine={false} />
                                        <Tooltip 
                                            contentStyle={{ borderRadius: '8px', border: 'none', boxShadow: '0 4px 12px rgba(0,0,0,0.08)', background: '#ffffff', fontFamily: 'Outfit, sans-serif' }}
                                        />
                                        <Line type="monotone" dataKey="registrations" name="New Registrations" stroke="#0d503c" strokeWidth={3} dot={{ r: 4, strokeWidth: 2, fill: '#ffffff' }} activeDot={{ r: 6 }} />
                                    </LineChart>
                                </ResponsiveContainer>
                            </div>
                        </div>

                        {/* Revenue & Predictive Projection */}
                        <div className="chart-container-card" style={{ height: '330px', display: 'flex', flexDirection: 'column' }}>
                            <h3 className="chart-title">💸 Revenue & Predictive Projection</h3>
                            <p className="chart-subtitle">Actual monthly earnings and linear regression trend projection</p>
                            <div style={{ flex: 1, width: '100%', height: '220px', minWidth: 0, position: 'relative' }}>
                                <ResponsiveContainer width="100%" height="100%">
                                    <ComposedChart data={combinedEarningsData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                                        <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e5e7eb" />
                                        <XAxis dataKey="name" tick={{ fontSize: 10, fill: '#6b7280' }} tickLine={false} axisLine={false} />
                                        <YAxis tick={{ fontSize: 10, fill: '#6b7280' }} tickLine={false} axisLine={false} />
                                        <Tooltip 
                                            contentStyle={{ borderRadius: '8px', border: 'none', boxShadow: '0 4px 12px rgba(0,0,0,0.08)', background: '#ffffff', fontFamily: 'Outfit, sans-serif' }}
                                        />
                                        <Legend wrapperStyle={{ fontSize: '0.75rem', marginTop: '10px' }} />
                                        <Bar dataKey="actual" name="Earnings (RM)" fill="#0d503c" radius={[4, 4, 0, 0]} barSize={35} />
                                        <Line type="monotone" dataKey="prediction" name="Projected Trend" stroke="#d97706" strokeDasharray="5 5" strokeWidth={2.5} dot={{ r: 4, strokeWidth: 2, fill: '#ffffff' }} />
                                    </ComposedChart>
                                </ResponsiveContainer>
                            </div>
                        </div>
                    </div>

                    {/* Right Column: Split & Anomaly Table */}
                    <div className="flex flex-col gap-6">
                        {/* Transaction Type Split */}
                        <div className="chart-container-card" style={{ height: '330px', display: 'flex', flexDirection: 'column' }}>
                            <h3 className="chart-title">🔄 Transaction Type Breakdown</h3>
                            <p className="chart-subtitle">Ratio of direct sales vs rentals across the platform</p>
                            
                            <div style={{ display: 'flex', alignItems: 'center', height: '100%', gap: '16px' }}>
                                <div style={{ flex: 1, height: '180px', minWidth: 0, position: 'relative' }}>
                                    <ResponsiveContainer width="100%" height="100%">
                                        <PieChart>
                                            <Pie 
                                                data={orderTypeData} 
                                                cx="50%" 
                                                cy="50%" 
                                                innerRadius={50}
                                                outerRadius={70} 
                                                paddingAngle={3}
                                                dataKey="value" 
                                                nameKey="name"
                                            >
                                                <Cell fill="#0d503c" />
                                                <Cell fill="#8b5cf6" />
                                            </Pie>
                                            <Tooltip 
                                                contentStyle={{ borderRadius: '8px', border: 'none', boxShadow: '0 4px 12px rgba(0,0,0,0.08)' }}
                                            />
                                        </PieChart>
                                    </ResponsiveContainer>
                                </div>
                                <div style={{ flex: 1.1, display: 'flex', flexDirection: 'column', gap: '12px' }}>
                                    {(() => {
                                        const saleCount = metrics?.order_type_breakdown?.sale || 0;
                                        const rentCount = metrics?.order_type_breakdown?.rent || 0;
                                        const totalCount = saleCount + rentCount;
                                        const salePercent = totalCount > 0 ? ((saleCount / totalCount) * 100).toFixed(1) : 0;
                                        const rentPercent = totalCount > 0 ? ((rentCount / totalCount) * 100).toFixed(1) : 0;
                                        return (
                                            <>
                                                <div className="custom-legend-item">
                                                    <div style={{ width: '12px', height: '12px', borderRadius: '50%', background: '#0d503c' }} />
                                                    <div style={{ flex: 1 }}>
                                                        <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Sales</div>
                                                        <div style={{ fontSize: '1rem', fontWeight: 'bold' }}>{saleCount} <span style={{ fontSize: '0.75rem', fontWeight: 'normal', color: 'var(--text-muted)' }}>({salePercent}%)</span></div>
                                                    </div>
                                                </div>
                                                <div className="custom-legend-item">
                                                    <div style={{ width: '12px', height: '12px', borderRadius: '50%', background: '#8b5cf6' }} />
                                                    <div style={{ flex: 1 }}>
                                                        <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Rentals</div>
                                                        <div style={{ fontSize: '1rem', fontWeight: 'bold' }}>{rentCount} <span style={{ fontSize: '0.75rem', fontWeight: 'normal', color: 'var(--text-muted)' }}>({rentPercent}%)</span></div>
                                                    </div>
                                                </div>
                                            </>
                                        );
                                    })()}
                                </div>
                            </div>
                        </div>

                        {/* Anomaly Behavior Logs */}
                        <div className="chart-container-card" style={{ height: '330px', display: 'flex', flexDirection: 'column' }}>
                            <h3 className="chart-title" style={{ color: 'var(--danger)' }}>
                                <ShieldAlert size={18} />
                                <span>Security & Anomaly Logs</span>
                            </h3>
                            <p className="chart-subtitle">Recent automated alerts flagged for suspicious user actions</p>
                            <div style={{ flex: 1, overflowY: 'auto', border: '1px solid var(--border)', borderRadius: '8px' }}>
                                <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.8rem' }}>
                                    <thead style={{ position: 'sticky', top: 0, zIndex: 1, background: '#f9fafb' }}>
                                        <tr>
                                            <th style={{ padding: '8px 12px', fontSize: '0.75rem', borderBottom: '1px solid var(--border)' }}>User</th>
                                            <th style={{ padding: '8px 12px', fontSize: '0.75rem', borderBottom: '1px solid var(--border)' }}>Event</th>
                                            <th style={{ padding: '8px 12px', fontSize: '0.75rem', borderBottom: '1px solid var(--border)', textAlign: 'right' }}>Time</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {(metrics?.anomaly_logs || []).map((log, idx) => (
                                            <tr key={idx}>
                                                <td style={{ padding: '8px 12px', fontWeight: '600', borderBottom: '1px solid var(--border)' }}>{log.username}</td>
                                                <td style={{ padding: '8px 12px', borderBottom: '1px solid var(--border)' }}>
                                                    <span className="anomaly-badge">
                                                        {log.action.replace('ANOMALY: ', '')}
                                                    </span>
                                                </td>
                                                <td style={{ padding: '8px 12px', color: 'var(--text-muted)', textAlign: 'right', borderBottom: '1px solid var(--border)' }}>{new Date(log.timestamp).toLocaleTimeString()}</td>
                                            </tr>
                                        ))}
                                        {(!metrics?.anomaly_logs || metrics.anomaly_logs.length === 0) && (
                                            <tr>
                                                <td colSpan="3" style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>
                                                    No security anomalies recorded.
                                                </td>
                                            </tr>
                                        )}
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            {/* Print Footer */}
            <div className="print-report-footer">
                Campus Swap Platform Official Analytics & Sustainability Report — Internal Confidential
            </div>
        </div>
    );
};

export default Analytics;
