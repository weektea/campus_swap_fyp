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
import * as XLSX from 'xlsx';
import React, { useState, useEffect } from 'react';
import { 
    Calendar, Download, Printer, Users, BarChart3, ShieldAlert, Award,
    CheckSquare, Square, FileSpreadsheet, FileText, X, Layers, ShoppingBag, 
    CreditCard, AlertTriangle, Headset, Compass, RefreshCw
} from 'lucide-react';
import { LineChart, Line, BarChart, Bar, ComposedChart, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import api from '../services/api';

const DATASETS_CONFIG = [
    { id: 'summary', label: 'Platform Summary & ESG Impact', icon: BarChart3, desc: 'Overall platform stats, user counts, carbon savings, GMV', color: '#10b981' },
    { id: 'users', label: 'User Directory & Verification Status', icon: Users, desc: 'User accounts, emails, roles, status, verification, reputation', color: '#3b82f6' },
    { id: 'listings', label: 'Marketplace Listings & Inventory', icon: ShoppingBag, desc: 'All items, categories, price/rates, sale vs rent, seller details', color: '#f59e0b' },
    { id: 'transactions', label: 'Orders & Financial Transactions Log', icon: CreditCard, desc: 'Completed & active orders, payment methods, meetup locations, carbon saved', color: '#8b5cf6' },
    { id: 'reports', label: 'Violations & Listing Reports Log', icon: AlertTriangle, desc: 'User report tickets, violation reasons, reported products, resolution status', color: '#ef4444' },
    { id: 'disputes', label: 'Trade Disputes Audit Log', icon: ShieldAlert, desc: 'Arbitrated trade disputes, claims, evidence notes, resolutions', color: '#dc2626' },
    { id: 'tickets', label: 'Customer Support Tickets & Helpdesk', icon: Headset, desc: 'Customer support tickets, priorities, admin assignment, resolution log', color: '#06b6d4' },
    { id: 'onboarding', label: 'User Intent & Onboarding Analytics', icon: Compass, desc: 'User goals (Buy/Rent), preferred categories, onboarding status', color: '#ec4899' },
];

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

    // Unified Export Data Center State
    const [isExportModalOpen, setIsExportModalOpen] = useState(false);
    const [selectedDatasets, setSelectedDatasets] = useState(['summary', 'users', 'listings', 'transactions', 'reports', 'disputes', 'tickets', 'onboarding']);
    const [isExporting, setIsExporting] = useState(false);
    const [exportProgressText, setExportProgressText] = useState('');


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

    const downloadCSVBlob = (csvRows, filename) => {
        const csvContent = csvRows.map(row => row.map(val => `"${String(val).replace(/"/g, '""')}"`).join(',')).join('\n');
        const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = filename;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        URL.revokeObjectURL(url);
    };

    const handleExportUsersCSVInAnalytics = async () => {
        try {
            const res = await api.get('/admin/users');
            const data = res.data || [];
            const csvRows = [
                ['ID', 'Full Name', 'Username', 'Email', 'Role', 'Status', 'Reputation Score', 'Warnings', 'Verified', 'Created At']
            ];
            data.forEach(u => {
                csvRows.push([
                    u.id,
                    u.full_name || '',
                    u.username || '',
                    u.email || '',
                    u.role || '',
                    (u.is_active !== false && u.status !== 'suspended') ? 'Active' : 'Banned/Suspended',
                    u.reputation_score !== undefined && u.reputation_score !== null ? Number(u.reputation_score).toFixed(1) : '5.0',
                    u.warning_count || 0,
                    u.is_verified ? 'Yes' : 'No',
                    u.createdAt ? new Date(u.createdAt).toLocaleString() : ''
                ]);
            });
            downloadCSVBlob(csvRows, `Campus_Swap_Users_Directory_${new Date().toISOString().slice(0, 10)}.csv`);
        } catch (err) {
            console.error(err);
            alert('Failed to export Users CSV.');
        }
    };

    const handleExportListingsCSVInAnalytics = async () => {
        try {
            const res = await api.get('/admin/listings');
            const data = res.data || [];
            const csvRows = [
                ['Listing ID', 'Title', 'Category', 'Subcategory', 'Type', 'Price/Rental Rate', 'Seller Name', 'Seller Email', 'Status', 'Condition', 'Posted Date']
            ];
            data.forEach(item => {
                csvRows.push([
                    item.id,
                    item.title || '',
                    item.categoryModel?.name || 'General',
                    item.subcategoryModel?.name || '',
                    item.type || 'Sale',
                    item.type === 'Rent' ? `RM ${item.rental_price_per_day}/day` : `RM ${item.price}`,
                    item.seller?.full_name || '',
                    item.seller?.email || '',
                    item.status || '',
                    item.condition || '',
                    item.createdAt ? new Date(item.createdAt).toLocaleString() : ''
                ]);
            });
            downloadCSVBlob(csvRows, `Campus_Swap_Listings_Report_${new Date().toISOString().slice(0, 10)}.csv`);
        } catch (err) {
            console.error(err);
            alert('Failed to export Listings CSV.');
        }
    };

    const handleExportTransactionsCSVInAnalytics = async () => {
        try {
            const res = await api.get('/admin/transactions');
            const data = res.data || [];
            const csvRows = [
                ['Order ID', 'Product Title', 'Type', 'Amount (RM)', 'Buyer Name', 'Buyer Email', 'Seller Name', 'Seller Email', 'Status', 'Meetup Location', 'Carbon Savings (kg)', 'Created At']
            ];
            data.forEach(t => {
                csvRows.push([
                    t.id,
                    t.product?.title || 'Unknown Item',
                    t.type || 'Sale',
                    t.amount || t.agreed_price || '0.00',
                    t.buyer?.full_name || '',
                    t.buyer?.email || '',
                    t.seller?.full_name || '',
                    t.seller?.email || '',
                    t.status || '',
                    t.meetup_location || t.meetup_zone?.name || 'TBD',
                    t.carbon_saved_kg || '0.00',
                    t.createdAt ? new Date(t.createdAt).toLocaleString() : ''
                ]);
            });
            downloadCSVBlob(csvRows, `Campus_Swap_Transactions_Report_${new Date().toISOString().slice(0, 10)}.csv`);
        } catch (err) {
            console.error(err);
            alert('Failed to export Transactions CSV.');
        }
    };

    const toggleSelectDataset = (id) => {
        if (selectedDatasets.includes(id)) {
            setSelectedDatasets(selectedDatasets.filter(item => item !== id));
        } else {
            setSelectedDatasets([...selectedDatasets, id]);
        }
    };

    const toggleSelectAllDatasets = () => {
        if (selectedDatasets.length === DATASETS_CONFIG.length) {
            setSelectedDatasets([]);
        } else {
            setSelectedDatasets(DATASETS_CONFIG.map(d => d.id));
        }
    };

    const handleExportToExcelWorkbook = async () => {
        if (selectedDatasets.length === 0) {
            alert('Please select at least one dataset to export.');
            return;
        }

        setIsExporting(true);
        setExportProgressText('Preparing Excel workbook compilation...');

        try {
            const workbook = XLSX.utils.book_new();

            for (const datasetId of selectedDatasets) {
                if (datasetId === 'summary') {
                    setExportProgressText('Processing Platform Summary & ESG...');
                    const summaryRows = [
                        { Category: 'User Ecology', Metric: 'New Registrations', Value: metrics?.new_registrations || 0, Notes: 'In period' },
                        { Category: 'User Ecology', Metric: 'Active Users', Value: metrics?.active_users || 0, Notes: 'Current active users' },
                        { Category: 'User Ecology', Metric: 'Total Registered Users', Value: metrics?.total_users || 0, Notes: 'All-time platform' },
                        { Category: 'Environmental Impact', Metric: 'Total Carbon Saved (kg CO2e)', Value: Number(metrics?.carbon_saved_kg || 0).toFixed(2), Notes: 'Avoided emissions' },
                        { Category: 'Environmental Impact', Metric: 'Top Eco-Category', Value: `${metrics?.top_eco_category || 'N/A'} (${metrics?.top_eco_category_percentage || 0}%)`, Notes: 'Highest contributor' },
                        { Category: 'Transactions', Metric: 'Completed Orders', Value: metrics?.completed_transactions || 0, Notes: 'Successful transactions' },
                        { Category: 'Transactions', Metric: 'GMV (RM)', Value: metrics?.gmv || '0.00', Notes: 'Gross Merchandise Volume' },
                        { Category: 'Trust & Safety', Metric: 'Active Disputes', Value: metrics?.active_disputes || 0, Notes: 'Ongoing disputes' },
                        { Category: 'Trust & Safety', Metric: 'Suspended Users', Value: metrics?.suspended_users || 0, Notes: 'Deactivated accounts' },
                    ];

                    if (metrics?.category_distribution) {
                        metrics.category_distribution.forEach(c => {
                            summaryRows.push({
                                Category: 'Carbon by Category',
                                Metric: c.name,
                                Value: `${Number(c.value).toFixed(2)} kg`,
                                Notes: 'Avoided emissions'
                            });
                        });
                    }

                    const ws = XLSX.utils.json_to_sheet(summaryRows);
                    XLSX.utils.book_append_sheet(workbook, ws, 'Summary & ESG');

                } else if (datasetId === 'users') {
                    setExportProgressText('Fetching User Directory...');
                    const res = await api.get('/admin/users');
                    const users = (res.data || []).map(u => ({
                        'User ID': u.id,
                        'Full Name': u.full_name || '',
                        'Username': u.username || '',
                        'Email': u.email || '',
                        'Role': u.role || '',
                        'Status': (u.is_active !== false && u.status !== 'suspended') ? 'Active' : 'Banned/Suspended',
                        'Reputation Score': u.reputation_score !== undefined ? Number(u.reputation_score).toFixed(1) : '5.0',
                        'Warning Count': u.warning_count || 0,
                        'Verified': u.is_verified ? 'Yes' : 'No',
                        'Joined Date': u.createdAt ? new Date(u.createdAt).toLocaleString() : ''
                    }));
                    const ws = XLSX.utils.json_to_sheet(users.length > 0 ? users : [{ 'Status': 'No users found' }]);
                    XLSX.utils.book_append_sheet(workbook, ws, 'User Directory');

                } else if (datasetId === 'listings') {
                    setExportProgressText('Fetching Marketplace Listings...');
                    const res = await api.get('/admin/listings');
                    const listings = (res.data || []).map(item => ({
                        'Listing ID': item.id,
                        'Title': item.title || '',
                        'Category': item.categoryModel?.name || item.category || 'General',
                        'Subcategory': item.subcategoryModel?.name || item.subCategoryName || '',
                        'Type': item.type || 'Sale',
                        'Price/Rate (RM)': item.type === 'Rent' ? `${item.rental_price_per_day}/day` : item.price,
                        'Seller Name': item.seller?.full_name || '',
                        'Seller Email': item.seller?.email || '',
                        'Status': item.status || '',
                        'Condition': item.condition || '',
                        'Posted Date': item.createdAt ? new Date(item.createdAt).toLocaleString() : ''
                    }));
                    const ws = XLSX.utils.json_to_sheet(listings.length > 0 ? listings : [{ 'Status': 'No listings found' }]);
                    XLSX.utils.book_append_sheet(workbook, ws, 'Marketplace Listings');

                } else if (datasetId === 'transactions') {
                    setExportProgressText('Fetching Orders & Transactions...');
                    const res = await api.get('/admin/transactions');
                    const txs = (res.data || []).map(t => ({
                        'Order ID': t.id,
                        'Product Title': t.product?.title || 'Unknown Item',
                        'Type': t.type || 'Sale',
                        'Amount (RM)': t.amount || t.agreed_price || '0.00',
                        'Buyer Name': t.buyer?.full_name || '',
                        'Buyer Email': t.buyer?.email || '',
                        'Seller Name': t.seller?.full_name || '',
                        'Seller Email': t.seller?.email || '',
                        'Status': t.status || '',
                        'Meetup Location': t.meetup_location || t.meetup_zone?.name || 'TBD',
                        'Carbon Savings (kg)': t.carbon_saved_kg || '0.00',
                        'Order Date': t.createdAt ? new Date(t.createdAt).toLocaleString() : ''
                    }));
                    const ws = XLSX.utils.json_to_sheet(txs.length > 0 ? txs : [{ 'Status': 'No transactions found' }]);
                    XLSX.utils.book_append_sheet(workbook, ws, 'Transactions Log');

                } else if (datasetId === 'reports') {
                    setExportProgressText('Fetching Violations & Reports...');
                    const res = await api.get('/admin/reports');
                    const reports = (res.data || []).map(r => ({
                        'Report ID': r.id,
                        'Reporter Name': r.reporter?.full_name || '',
                        'Reported Item/User': r.product?.title || r.reportedUser?.full_name || 'N/A',
                        'Reason': r.reason || '',
                        'Category': r.category || '',
                        'Status': r.status || 'Pending',
                        'Created Date': r.createdAt ? new Date(r.createdAt).toLocaleString() : ''
                    }));
                    const ws = XLSX.utils.json_to_sheet(reports.length > 0 ? reports : [{ 'Status': 'No reports found' }]);
                    XLSX.utils.book_append_sheet(workbook, ws, 'Violations Log');

                } else if (datasetId === 'disputes') {
                    setExportProgressText('Fetching Trade Disputes...');
                    const res = await api.get('/admin/disputes');
                    const disputes = (res.data || []).map(d => ({
                        'Dispute ID': d.id,
                        'Transaction ID': d.transaction_id || '',
                        'Buyer Name': d.buyer?.full_name || '',
                        'Seller Name': d.seller?.full_name || '',
                        'Reason': d.reason || '',
                        'Amount (RM)': d.disputed_amount || '0.00',
                        'Status': d.status || '',
                        'Resolution Note': d.resolution_notes || '',
                        'Created Date': d.createdAt ? new Date(d.createdAt).toLocaleString() : ''
                    }));
                    const ws = XLSX.utils.json_to_sheet(disputes.length > 0 ? disputes : [{ 'Status': 'No disputes found' }]);
                    XLSX.utils.book_append_sheet(workbook, ws, 'Trade Disputes');

                } else if (datasetId === 'tickets') {
                    setExportProgressText('Fetching Support Tickets...');
                    const res = await api.get('/admin/tickets');
                    const tickets = (res.data || []).map(t => ({
                        'Ticket ID': t.id,
                        'User Name': t.user?.full_name || '',
                        'Email': t.user?.email || '',
                        'Subject': t.subject || '',
                        'Category': t.category || '',
                        'Priority': t.priority || 'Normal',
                        'Status': t.status || '',
                        'Assigned Admin': t.assignedAdmin?.full_name || 'Unassigned',
                        'Created Date': t.createdAt ? new Date(t.createdAt).toLocaleString() : ''
                    }));
                    const ws = XLSX.utils.json_to_sheet(tickets.length > 0 ? tickets : [{ 'Status': 'No tickets found' }]);
                    XLSX.utils.book_append_sheet(workbook, ws, 'Support Tickets');

                } else if (datasetId === 'onboarding') {
                    setExportProgressText('Fetching Onboarding Analytics...');
                    const res = await api.get('/admin/analytics/onboarding');
                    const data = res.data || {};
                    const onboardingRows = [
                        { Metric: 'Total Registered Users', Value: data.total_users || 0 },
                        { Metric: 'Completed Onboarding Users', Value: data.total_onboarded_users || 0 },
                    ];
                    if (data.intent_distribution) {
                        onboardingRows.push(
                            { Metric: 'Intent: Buy Only', Value: data.intent_distribution.Buy || 0 },
                            { Metric: 'Intent: Rent Only', Value: data.intent_distribution.Rent || 0 },
                            { Metric: 'Intent: Both Buy & Rent', Value: data.intent_distribution.Both || 0 }
                        );
                    }
                    if (data.top_categories) {
                        data.top_categories.forEach(c => {
                            onboardingRows.push({ Metric: `Preferred Category: ${c.name}`, Value: `${c.count} users` });
                        });
                    }
                    const ws = XLSX.utils.json_to_sheet(onboardingRows);
                    XLSX.utils.book_append_sheet(workbook, ws, 'Onboarding Analytics');
                }
            }

            const dateStr = new Date().toISOString().slice(0, 10);
            XLSX.writeFile(workbook, `CampusSwap_Master_Export_${dateStr}.xlsx`);
            setIsExportModalOpen(false);
        } catch (err) {
            console.error('Multi-Tab Excel Export Error:', err);
            alert('Failed to generate multi-sheet Excel export.');
        } finally {
            setIsExporting(false);
            setExportProgressText('');
        }
    };

    const handleExportSelectedCSVs = async () => {
        if (selectedDatasets.length === 0) {
            alert('Please select at least one dataset.');
            return;
        }

        setIsExporting(true);
        setExportProgressText('Downloading individual CSV reports...');

        try {
            for (const id of selectedDatasets) {
                if (id === 'summary') handleExportCSV();
                else if (id === 'users') await handleExportUsersCSVInAnalytics();
                else if (id === 'listings') await handleExportListingsCSVInAnalytics();
                else if (id === 'transactions') await handleExportTransactionsCSVInAnalytics();
                else if (id === 'environmental' && range === 'custom') await handleExportEnvironmentalCSV();
            }
            setIsExportModalOpen(false);
        } catch (err) {
            console.error(err);
        } finally {
            setIsExporting(false);
            setExportProgressText('');
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
                        margin: 10mm 12mm;
                        size: A4 portrait;
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
                        background: white !important;
                        color: #1f2937 !important;
                    }
                    .page-container {
                        padding: 0 !important;
                        margin: 0 !important;
                    }
                    body {
                        background-color: white !important;
                        color: #1f2937 !important;
                        font-size: 9.5pt !important;
                    }
                    .print-report-header {
                        display: flex !important;
                        justify-content: space-between;
                        align-items: flex-end;
                        margin-bottom: 1.25rem !important;
                        border-bottom: 2px solid #0d503c !important;
                        padding-bottom: 0.5rem !important;
                    }
                    .print-report-header h1 {
                        color: #0d503c !important;
                        margin: 0 0 0.2rem 0;
                        font-size: 16pt;
                        font-weight: 800;
                    }
                    .print-report-header p {
                        margin: 0;
                        font-size: 8.5pt;
                        color: #4b5563;
                    }
                    .print-report-footer {
                        display: flex !important;
                        justify-content: space-between;
                        position: fixed;
                        bottom: 0;
                        left: 0;
                        right: 0;
                        font-size: 8pt;
                        color: #9ca3af;
                        border-top: 1px solid #e5e7eb;
                        padding-top: 6px;
                        background: white;
                    }
                    .print-domain-section {
                        margin-bottom: 1.5rem !important;
                        border: 1px solid #e5e7eb !important;
                        border-radius: 12px;
                        padding: 1rem !important;
                        background: white !important;
                        page-break-inside: avoid;
                        break-inside: avoid;
                    }
                    .print-domain-title {
                        border-bottom: 2px solid #0d503c !important;
                        color: #0d503c !important;
                        padding-bottom: 0.4rem;
                        margin-bottom: 1rem;
                        font-size: 12pt;
                        font-weight: 700;
                    }

                    /* Small Metric KPI Cards (Numbers) stay side-by-side */
                    .print-grid-3 {
                        display: grid !important;
                        grid-template-columns: repeat(3, 1fr) !important;
                        gap: 0.75rem !important;
                    }
                    .print-grid-4 {
                        display: grid !important;
                        grid-template-columns: repeat(4, 1fr) !important;
                        gap: 0.75rem !important;
                    }

                    /* All Chart Cards & Tables STACK VERTICALLY (Full Width, No Squishing) */
                    .dashboard-grid-2,
                    .analytics-grid-2 {
                        display: flex !important;
                        flex-direction: column !important;
                        gap: 1.25rem !important;
                        width: 100% !important;
                    }
                    .print-flex-row {
                        display: flex !important;
                        flex-direction: column !important;
                        gap: 1.25rem !important;
                        width: 100% !important;
                    }

                    .card, .chart-container-card, .print-flex-child {
                        box-shadow: none !important;
                        border: 1px solid #e5e7eb !important;
                        background: white !important;
                        width: 100% !important;
                        max-width: 100% !important;
                        min-width: 100% !important;
                        box-sizing: border-box !important;
                        page-break-inside: avoid;
                        break-inside: avoid;
                    }

                    /* Hide scrollbars elegantly */
                    ::-webkit-scrollbar {
                        display: none !important;
                    }
                    * {
                        scrollbar-width: none !important;
                    }
                }
                .print-report-header, .print-report-footer {
                    display: none;
                }
            `}} />

            {/* Print Header */}
            <div className="print-report-header">
                <div>
                    <h1>Campus Swap Platform Performance Report</h1>
                    <p>TAR UMT Official Analytics & Sustainability Audit</p>
                </div>
                <div style={{ textAlign: 'right' }}>
                    <p style={{ fontWeight: 'bold', color: '#0d503c', margin: 0 }}>Period: {getRangeLabel()}</p>
                    <p style={{ margin: 0, fontSize: '8pt', color: '#6b7280' }}>Date: {new Date().toLocaleDateString()} {new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</p>
                </div>
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

                        {/* Unified Data Export Center Button */}
                        <button 
                            className="btn" 
                            onClick={() => setIsExportModalOpen(true)}
                            style={{ 
                                padding: '0.6rem 1.25rem', 
                                fontSize: '0.9rem', 
                                height: '42px', 
                                background: 'linear-gradient(135deg, #0d503c 0%, #059669 100%)', 
                                color: 'white', 
                                border: 'none', 
                                borderRadius: '8px', 
                                cursor: 'pointer', 
                                fontWeight: 'bold',
                                display: 'flex',
                                alignItems: 'center',
                                gap: '8px',
                                boxShadow: '0 4px 12px rgba(5, 150, 105, 0.25)'
                            }}
                        >
                            <Download size={18} />
                            <span>Export Data Center</span>
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
                <span>TAR UMT Campus Swap System Report</span>
                <span>Confidential — Internal Administrative Audit</span>
                <span>Generated by System Administrator</span>
            </div>

            {/* Unified Export Data Center Modal */}
            {isExportModalOpen && (
                <div style={{
                    position: 'fixed',
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    background: 'rgba(0,0,0,0.65)',
                    backdropFilter: 'blur(5px)',
                    zIndex: 2000,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    padding: '1.5rem'
                }}>
                    <div style={{
                        background: 'white',
                        borderRadius: '20px',
                        width: '100%',
                        maxWidth: '880px',
                        maxHeight: '90vh',
                        overflow: 'hidden',
                        display: 'flex',
                        flexDirection: 'column',
                        boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.3)',
                        animation: 'fadeIn 0.2s ease-in-out'
                    }}>
                        {/* Modal Header */}
                        <div style={{
                            padding: '1.25rem 1.75rem',
                            background: 'linear-gradient(135deg, #0d503c 0%, #047857 100%)',
                            color: 'white',
                            display: 'flex',
                            justifyContent: 'space-between',
                            alignItems: 'center'
                        }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                                <div style={{ padding: '8px', borderRadius: '10px', background: 'rgba(255,255,255,0.15)' }}>
                                    <FileSpreadsheet size={26} color="white" />
                                </div>
                                <div>
                                    <h2 style={{ margin: 0, fontSize: '1.25rem', fontWeight: '800', color: 'white' }}>
                                        Unified Data Export Center
                                    </h2>
                                    <p style={{ margin: 0, fontSize: '0.825rem', opacity: 0.9, color: '#d1fae5' }}>
                                        Select datasets to compile into a single multi-tab Excel (.xlsx) workbook or individual CSVs
                                    </p>
                                </div>
                            </div>
                            <button 
                                onClick={() => !isExporting && setIsExportModalOpen(false)}
                                style={{ background: 'transparent', border: 'none', color: 'white', cursor: 'pointer', opacity: 0.85, padding: '4px' }}
                            >
                                <X size={24} />
                            </button>
                        </div>

                        {/* Modal Body: Checkbox Options Grid */}
                        <div style={{ padding: '1.5rem 1.75rem', overflowY: 'auto', flex: 1, background: '#f8fafc' }}>
                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.25rem', flexWrap: 'wrap', gap: '0.5rem' }}>
                                <span style={{ fontSize: '0.925rem', fontWeight: '700', color: 'var(--text-main)' }}>
                                    Select Datasets to Include ({selectedDatasets.length} of {DATASETS_CONFIG.length} selected):
                                </span>
                                <button 
                                    onClick={toggleSelectAllDatasets}
                                    style={{ background: 'transparent', border: 'none', color: 'var(--primary)', fontWeight: '700', fontSize: '0.875rem', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '6px' }}
                                >
                                    {selectedDatasets.length === DATASETS_CONFIG.length ? <Square size={16} /> : <CheckSquare size={16} />}
                                    <span>{selectedDatasets.length === DATASETS_CONFIG.length ? 'Deselect All' : 'Select All'}</span>
                                </button>
                            </div>

                            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(380px, 1fr))', gap: '1rem' }}>
                                {DATASETS_CONFIG.map((item) => {
                                    const IconComponent = item.icon;
                                    const isSelected = selectedDatasets.includes(item.id);
                                    return (
                                        <div 
                                            key={item.id}
                                            onClick={() => toggleSelectDataset(item.id)}
                                            style={{
                                                padding: '1rem 1.25rem',
                                                borderRadius: '14px',
                                                border: `2px solid ${isSelected ? item.color : '#e2e8f0'}`,
                                                background: isSelected ? 'white' : '#f1f5f9',
                                                boxShadow: isSelected ? '0 4px 12px rgba(0,0,0,0.05)' : 'none',
                                                cursor: 'pointer',
                                                transition: 'all 0.2s ease',
                                                display: 'flex',
                                                alignItems: 'flex-start',
                                                gap: '12px'
                                            }}
                                        >
                                            <div style={{ marginTop: '2px', color: isSelected ? item.color : '#94a3b8' }}>
                                                {isSelected ? <CheckSquare size={22} /> : <Square size={22} />}
                                            </div>
                                            <div style={{ flex: 1 }}>
                                                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '4px' }}>
                                                    <IconComponent size={18} color={item.color} />
                                                    <span style={{ fontWeight: '700', fontSize: '0.95rem', color: isSelected ? '#0f172a' : '#475569' }}>
                                                        {item.label}
                                                    </span>
                                                </div>
                                                <p style={{ margin: 0, fontSize: '0.825rem', color: '#64748b', lineHeight: '1.35' }}>
                                                    {item.desc}
                                                </p>
                                            </div>
                                        </div>
                                    );
                                })}
                            </div>
                        </div>

                        {/* Modal Footer: Action Buttons */}
                        <div style={{ padding: '1.25rem 1.75rem', background: 'white', borderTop: '1px solid #e2e8f0', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
                            <div style={{ fontSize: '0.85rem', color: '#64748b', display: 'flex', alignItems: 'center', gap: '8px' }}>
                                {isExporting && (
                                    <>
                                        <RefreshCw size={18} className="spin" color="var(--primary)" />
                                        <span style={{ fontWeight: '700', color: 'var(--primary)' }}>{exportProgressText}</span>
                                    </>
                                )}
                            </div>

                            <div style={{ display: 'flex', gap: '12px' }}>
                                <button 
                                    onClick={handleExportSelectedCSVs}
                                    disabled={isExporting || selectedDatasets.length === 0}
                                    className="btn btn-secondary"
                                    style={{ display: 'flex', alignItems: 'center', gap: '8px', padding: '0.7rem 1.25rem', fontWeight: '600', borderRadius: '10px' }}
                                >
                                    <FileText size={18} />
                                    <span>Export Separate CSVs</span>
                                </button>

                                <button 
                                    onClick={handleExportToExcelWorkbook}
                                    disabled={isExporting || selectedDatasets.length === 0}
                                    className="btn btn-primary"
                                    style={{ 
                                        display: 'flex', 
                                        alignItems: 'center', 
                                        gap: '8px', 
                                        padding: '0.7rem 1.5rem', 
                                        fontWeight: '700',
                                        background: 'linear-gradient(135deg, #15803d 0%, #16a34a 100%)',
                                        border: 'none',
                                        borderRadius: '10px',
                                        boxShadow: '0 4px 14px rgba(22, 163, 74, 0.35)'
                                    }}
                                >
                                    <FileSpreadsheet size={18} />
                                    <span>Export Multi-Tab Excel (.xlsx)</span>
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default Analytics;

