import React, { useState, useEffect } from 'react';
import { 
    ShieldAlert, 
    ShieldCheck, 
    AlertTriangle, 
    Plus, 
    Edit2, 
    Trash2, 
    CheckCircle2, 
    XCircle, 
    Play, 
    Search, 
    Filter, 
    Eye, 
    RefreshCw, 
    Sliders, 
    HelpCircle,
    UserX,
    Lock
} from 'lucide-react';
import api from '../services/api';

const Moderation = () => {
    const [activeTab, setActiveTab] = useState('rules'); // 'rules' | 'sandbox' | 'flagged'
    const [rules, setRules] = useState([]);
    const [flaggedItems, setFlaggedItems] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [categoryFilter, setCategoryFilter] = useState('All');
    const [flaggedStatusFilter, setFlaggedStatusFilter] = useState('pending');

    // Rule Modal State
    const [isRuleModalOpen, setIsRuleModalOpen] = useState(false);
    const [editingRule, setEditingRule] = useState(null);
    const [ruleForm, setRuleForm] = useState({
        name: '',
        category: 'privacy',
        match_type: 'keyword',
        pattern: '',
        severity: 'medium',
        action: 'flag',
        is_enabled: true,
        description: ''
    });

    // Sandbox Tester State
    const [testInput, setTestInput] = useState('Bank transfer accepted. Contact me at main library.');
    const [testResult, setTestResult] = useState(null);
    const [testing, setTesting] = useState(false);

    // Review Modal State
    const [resolvingItem, setResolvingItem] = useState(null);
    const [reviewNotes, setReviewNotes] = useState('');
    const [actionLoading, setActionLoading] = useState(false);

    useEffect(() => {
        fetchData();
    }, [activeTab, flaggedStatusFilter]);

    const fetchData = async () => {
        setLoading(true);
        try {
            if (activeTab === 'rules') {
                const res = await api.get('/admin/moderation/rules');
                setRules(res.data || []);
            } else if (activeTab === 'flagged') {
                const res = await api.get(`/admin/moderation/flagged?status=${flaggedStatusFilter}`);
                setFlaggedItems(res.data.data || []);
            }
        } catch (err) {
            console.error('Failed to fetch moderation data:', err);
        } finally {
            setLoading(false);
        }
    };

    // --- Rule Actions ---
    const handleOpenCreateModal = () => {
        setEditingRule(null);
        setRuleForm({
            name: '',
            category: 'privacy',
            match_type: 'keyword',
            pattern: '',
            severity: 'medium',
            action: 'flag',
            is_enabled: true,
            description: ''
        });
        setIsRuleModalOpen(true);
    };

    const handleOpenEditModal = (rule) => {
        setEditingRule(rule);
        setRuleForm({
            name: rule.name || '',
            category: rule.category || 'custom',
            match_type: rule.match_type || 'keyword',
            pattern: rule.pattern || '',
            severity: rule.severity || 'medium',
            action: rule.action || 'flag',
            is_enabled: rule.is_enabled,
            description: rule.description || ''
        });
        setIsRuleModalOpen(true);
    };

    const handleSaveRule = async (e) => {
        e.preventDefault();
        try {
            if (editingRule) {
                await api.put(`/admin/moderation/rules/${editingRule.id}`, ruleForm);
            } else {
                await api.post('/admin/moderation/rules', ruleForm);
            }
            setIsRuleModalOpen(false);
            fetchData();
        } catch (err) {
            alert('Failed to save rule: ' + (err.response?.data?.error || err.message));
        }
    };

    const handleToggleRule = async (rule) => {
        try {
            await api.put(`/admin/moderation/rules/${rule.id}`, { is_enabled: !rule.is_enabled });
            setRules(rules.map(r => r.id === rule.id ? { ...r, is_enabled: !r.is_enabled } : r));
        } catch (err) {
            alert('Failed to toggle rule status.');
        }
    };

    const handleDeleteRule = async (rule) => {
        if (!window.confirm(`Are you sure you want to delete moderation rule "${rule.name}"?`)) return;
        try {
            await api.delete(`/admin/moderation/rules/${rule.id}`);
            setRules(rules.filter(r => r.id !== rule.id));
        } catch (err) {
            alert('Failed to delete rule: ' + (err.response?.data?.error || err.message));
        }
    };

    // --- Sandbox Live Test ---
    const handleRunTest = async (overrideText) => {
        const textToTest = overrideText || testInput;
        setTesting(true);
        try {
            const res = await api.post('/admin/moderation/test', { text: textToTest });
            setTestResult(res.data);
        } catch (err) {
            alert('Test failed: ' + (err.response?.data?.error || err.message));
        } finally {
            setTesting(false);
        }
    };

    // --- Flagged Content Resolution ---
    const handleResolve = async (action) => {
        if (!resolvingItem) return;
        if (action === 'penalized') {
            const confirm = window.confirm(`WARNING: Applying sanction will issue a safety warning to student "${resolvingItem.offender?.username}", deduct 1.0 reputation point, and suspend account if warnings reach 3. Proceed?`);
            if (!confirm) return;
        }

        setActionLoading(true);
        try {
            await api.put(`/admin/moderation/flagged/${resolvingItem.id}/resolve`, {
                resolution_action: action,
                review_notes: reviewNotes
            });
            setResolvingItem(null);
            setReviewNotes('');
            fetchData();
        } catch (err) {
            alert('Resolution failed: ' + (err.response?.data?.error || err.message));
        } finally {
            setActionLoading(false);
        }
    };

    // Helpers for badges
    const getCategoryBadge = (cat) => {
        const map = {
            profanity: { bg: '#fee2e2', color: '#991b1b', label: 'Profanity' },
            privacy: { bg: '#fef3c7', color: '#92400e', label: 'Privacy / PII' },
            off_platform_contact: { bg: '#ffedd5', color: '#c2410c', label: 'Off-Platform' },
            harassment: { bg: '#fce7f3', color: '#9d174d', label: 'Harassment' },
            religious_sensitive: { bg: '#e0e7ff', color: '#3730a3', label: 'Religious/Cultural' },
            scam: { bg: '#fef2f2', color: '#b91c1c', label: 'Scam Risk' },
            custom: { bg: '#f3f4f6', color: '#374151', label: 'Custom' }
        };
        const conf = map[cat] || map.custom;
        return (
            <span style={{ padding: '3px 8px', borderRadius: '6px', fontSize: '0.75rem', fontWeight: 'bold', background: conf.bg, color: conf.color }}>
                {conf.label}
            </span>
        );
    };

    const getSeverityPill = (sev) => {
        const map = {
            critical: { bg: '#991b1b', color: 'white' },
            high: { bg: '#dc2626', color: 'white' },
            medium: { bg: '#f59e0b', color: 'white' },
            low: { bg: '#10b981', color: 'white' }
        };
        const conf = map[sev] || map.low;
        return (
            <span style={{ padding: '2px 8px', borderRadius: '12px', fontSize: '0.7rem', fontWeight: 'bold', background: conf.bg, color: conf.color, textTransform: 'uppercase' }}>
                {sev}
            </span>
        );
    };

    const getActionPill = (act) => {
        const map = {
            block: { bg: '#fee2e2', color: '#dc2626', label: 'BLOCK' },
            mask: { bg: '#e0e7ff', color: '#4338ca', label: 'MASK (***)' },
            flag: { bg: '#fef3c7', color: '#d97706', label: 'FLAG QUEUE' },
            warn: { bg: '#ffedd5', color: '#ea580c', label: 'WARN' },
            allow: { bg: '#dcfce7', color: '#16a34a', label: 'ALLOW' }
        };
        const conf = map[act] || map.allow;
        return (
            <span style={{ padding: '2px 8px', borderRadius: '4px', fontSize: '0.7rem', fontWeight: 'bold', border: `1px solid ${conf.color}`, background: conf.bg, color: conf.color }}>
                {conf.label}
            </span>
        );
    };

    const filteredRules = rules.filter(r => {
        const matchesCat = categoryFilter === 'All' || r.category === categoryFilter;
        const matchesSearch = !searchTerm || r.name.toLowerCase().includes(searchTerm.toLowerCase()) || r.pattern.toLowerCase().includes(searchTerm.toLowerCase());
        return matchesCat && matchesSearch;
    });

    return (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
            {/* Header */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: '1rem' }}>
                <div>
                    <h1 style={{ fontSize: '1.75rem', fontWeight: 'bold', margin: '0 0 4px 0', color: 'var(--text-main)' }}>
                        🛡️ Content Moderation & Privacy Engine
                    </h1>
                    <p style={{ color: 'var(--text-muted)', fontSize: '0.9rem', margin: 0 }}>
                        Database-driven rule orchestration with zero false-positive protection for legitimate campus payment methods.
                    </p>
                </div>
                {activeTab === 'rules' && (
                    <button 
                        className="btn" 
                        onClick={handleOpenCreateModal}
                        style={{ background: 'var(--primary)', color: 'white', display: 'flex', alignItems: 'center', gap: '6px' }}
                    >
                        <Plus size={18} /> Add Moderation Rule
                    </button>
                )}
            </div>

            {/* Navigation Tabs */}
            <div style={{ display: 'flex', borderBottom: '1px solid var(--border)', gap: '1.5rem' }}>
                <button
                    onClick={() => setActiveTab('rules')}
                    style={{
                        padding: '10px 4px',
                        border: 'none',
                        background: 'transparent',
                        fontWeight: 'bold',
                        fontSize: '0.95rem',
                        color: activeTab === 'rules' ? 'var(--primary)' : 'var(--text-muted)',
                        borderBottom: activeTab === 'rules' ? '3px solid var(--primary)' : 'none',
                        cursor: 'pointer',
                        display: 'flex',
                        alignItems: 'center',
                        gap: '8px'
                    }}
                >
                    <Sliders size={18} /> Moderation Rules ({rules.length})
                </button>
                <button
                    onClick={() => { setActiveTab('sandbox'); if (!testResult) handleRunTest(); }}
                    style={{
                        padding: '10px 4px',
                        border: 'none',
                        background: 'transparent',
                        fontWeight: 'bold',
                        fontSize: '0.95rem',
                        color: activeTab === 'sandbox' ? 'var(--primary)' : 'var(--text-muted)',
                        borderBottom: activeTab === 'sandbox' ? '3px solid var(--primary)' : 'none',
                        cursor: 'pointer',
                        display: 'flex',
                        alignItems: 'center',
                        gap: '8px'
                    }}
                >
                    <Play size={18} /> Live Engine Sandbox
                </button>
                <button
                    onClick={() => setActiveTab('flagged')}
                    style={{
                        padding: '10px 4px',
                        border: 'none',
                        background: 'transparent',
                        fontWeight: 'bold',
                        fontSize: '0.95rem',
                        color: activeTab === 'flagged' ? 'var(--primary)' : 'var(--text-muted)',
                        borderBottom: activeTab === 'flagged' ? '3px solid var(--primary)' : 'none',
                        cursor: 'pointer',
                        display: 'flex',
                        alignItems: 'center',
                        gap: '8px'
                    }}
                >
                    <ShieldAlert size={18} /> Review Queue (Flagged Content)
                </button>
            </div>

            {/* TAB 1: MODERATION RULES */}
            {activeTab === 'rules' && (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                    {/* Filters bar */}
                    <div className="card" style={{ padding: '1rem', display: 'flex', gap: '1rem', flexWrap: 'wrap', alignItems: 'center' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flex: 1, minWidth: '220px' }}>
                            <Search size={18} color="var(--text-muted)" />
                            <input 
                                type="text"
                                placeholder="Search rules by keyword or pattern..."
                                className="input"
                                value={searchTerm}
                                onChange={(e) => setSearchTerm(e.target.value)}
                                style={{ margin: 0, width: '100%' }}
                            />
                        </div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                            <Filter size={18} color="var(--text-muted)" />
                            <select 
                                className="input"
                                value={categoryFilter}
                                onChange={(e) => setCategoryFilter(e.target.value)}
                                style={{ margin: 0, appearance: 'auto' }}
                            >
                                <option value="All">All Categories</option>
                                <option value="privacy">Privacy / PII Leaks</option>
                                <option value="off_platform_contact">Off-Platform Redirection</option>
                                <option value="profanity">Profanity & Abuse</option>
                                <option value="harassment">Harassment & Threats</option>
                                <option value="religious_sensitive">Religious / Sensitive</option>
                                <option value="custom">Custom Rules</option>
                            </select>
                        </div>
                    </div>

                    {/* Rules Table */}
                    <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
                        <div style={{ overflowX: 'auto' }}>
                            <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.875rem' }}>
                                <thead>
                                    <tr style={{ background: '#f8fafc', borderBottom: '1px solid var(--border)', textAlign: 'left', color: '#64748b' }}>
                                        <th style={{ padding: '12px 16px' }}>Rule Name & Description</th>
                                        <th style={{ padding: '12px 16px' }}>Category</th>
                                        <th style={{ padding: '12px 16px' }}>Type</th>
                                        <th style={{ padding: '12px 16px' }}>Pattern / Expression</th>
                                        <th style={{ padding: '12px 16px' }}>Severity</th>
                                        <th style={{ padding: '12px 16px' }}>Enforced Action</th>
                                        <th style={{ padding: '12px 16px' }}>Status</th>
                                        <th style={{ padding: '12px 16px', textAlign: 'right' }}>Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {loading ? (
                                        <tr>
                                            <td colSpan="8" style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>
                                                Loading moderation rules...
                                            </td>
                                        </tr>
                                    ) : filteredRules.length === 0 ? (
                                        <tr>
                                            <td colSpan="8" style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>
                                                No moderation rules match criteria.
                                            </td>
                                        </tr>
                                    ) : (
                                        filteredRules.map(rule => (
                                            <tr key={rule.id} style={{ borderBottom: '1px solid var(--border)' }}>
                                                <td style={{ padding: '12px 16px', maxWidth: '240px' }}>
                                                    <div style={{ fontWeight: 'bold', color: 'var(--text-main)' }}>{rule.name}</div>
                                                    {rule.description && (
                                                        <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: '2px' }}>
                                                            {rule.description}
                                                        </div>
                                                    )}
                                                </td>
                                                <td style={{ padding: '12px 16px' }}>
                                                    {getCategoryBadge(rule.category)}
                                                </td>
                                                <td style={{ padding: '12px 16px' }}>
                                                    <code style={{ fontSize: '0.75rem', padding: '2px 4px', background: '#f1f5f9', borderRadius: '4px' }}>
                                                        {rule.match_type}
                                                    </code>
                                                </td>
                                                <td style={{ padding: '12px 16px', maxWidth: '200px' }}>
                                                    <div style={{ fontFamily: 'monospace', fontSize: '0.8rem', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', background: '#f8fafc', padding: '4px 8px', borderRadius: '4px', border: '1px solid #e2e8f0' }} title={rule.pattern}>
                                                        {rule.pattern}
                                                    </div>
                                                </td>
                                                <td style={{ padding: '12px 16px' }}>
                                                    {getSeverityPill(rule.severity)}
                                                </td>
                                                <td style={{ padding: '12px 16px' }}>
                                                    {getActionPill(rule.action)}
                                                </td>
                                                <td style={{ padding: '12px 16px' }}>
                                                    <button 
                                                        onClick={() => handleToggleRule(rule)}
                                                        style={{
                                                            border: 'none',
                                                            background: rule.is_enabled ? '#dcfce7' : '#fee2e2',
                                                            color: rule.is_enabled ? '#16a34a' : '#dc2626',
                                                            padding: '4px 10px',
                                                            borderRadius: '12px',
                                                            fontSize: '0.75rem',
                                                            fontWeight: 'bold',
                                                            cursor: 'pointer'
                                                        }}
                                                    >
                                                        {rule.is_enabled ? 'Active' : 'Disabled'}
                                                    </button>
                                                </td>
                                                <td style={{ padding: '12px 16px', textAlign: 'right' }}>
                                                    <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px' }}>
                                                        <button 
                                                            className="btn btn-outline" 
                                                            onClick={() => handleOpenEditModal(rule)}
                                                            style={{ padding: '4px 8px', height: 'auto', fontSize: '0.75rem' }}
                                                            title="Edit Rule"
                                                        >
                                                            <Edit2 size={14} />
                                                        </button>
                                                        <button 
                                                            className="btn btn-outline" 
                                                            onClick={() => handleDeleteRule(rule)}
                                                            style={{ padding: '4px 8px', height: 'auto', fontSize: '0.75rem', color: 'var(--danger)', borderColor: '#fca5a5' }}
                                                            title="Delete Rule"
                                                        >
                                                            <Trash2 size={14} />
                                                        </button>
                                                    </div>
                                                </td>
                                            </tr>
                                        ))
                                    )}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            )}

            {/* TAB 2: LIVE ENGINE SANDBOX */}
            {activeTab === 'sandbox' && (
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem' }}>
                    {/* Input Panel */}
                    <div className="card" style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                        <h2 style={{ fontSize: '1.15rem', margin: 0 }}>🧪 Moderation Sandbox Tester</h2>
                        <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)', margin: 0 }}>
                            Type sample phrases to test real-time regex matching, privacy detection, and verify that legitimate payment terms are never blocked.
                        </p>

                        <div>
                            <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 'bold', marginBottom: '6px' }}>
                                Quick Test Presets:
                            </label>
                            <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' }}>
                                <button 
                                    className="btn btn-outline"
                                    style={{ padding: '4px 8px', fontSize: '0.75rem' }}
                                    onClick={() => { setTestInput('Bank transfer or TNG accepted. Cash on delivery also ok.'); handleRunTest('Bank transfer or TNG accepted. Cash on delivery also ok.'); }}
                                >
                                    ✅ Legitimate Payment Methods
                                </button>
                                <button 
                                    className="btn btn-outline"
                                    style={{ padding: '4px 8px', fontSize: '0.75rem' }}
                                    onClick={() => { setTestInput('WhatsApp me at 012-3456789 for deal'); handleRunTest('WhatsApp me at 012-3456789 for deal'); }}
                                >
                                    ⚠️ WhatsApp Solicitation
                                </button>
                                <button 
                                    className="btn btn-outline"
                                    style={{ padding: '4px 8px', fontSize: '0.75rem' }}
                                    onClick={() => { setTestInput('This is a fuck bad item shit'); handleRunTest('This is a fuck bad item shit'); }}
                                >
                                    🛑 Profanity Masking
                                </button>
                                <button 
                                    className="btn btn-outline"
                                    style={{ padding: '4px 8px', fontSize: '0.75rem' }}
                                    onClick={() => { setTestInput('My IC number is 010203-14-5678'); handleRunTest('My IC number is 010203-14-5678'); }}
                                >
                                    🔒 Malaysian IC Leak
                                </button>
                            </div>
                        </div>

                        <div>
                            <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 'bold', marginBottom: '6px' }}>
                                Input Text:
                            </label>
                            <textarea 
                                className="input" 
                                rows="5" 
                                value={testInput} 
                                onChange={(e) => setTestInput(e.target.value)}
                                style={{ resize: 'vertical', fontFamily: 'sans-serif' }}
                            />
                        </div>

                        <button 
                            className="btn" 
                            onClick={() => handleRunTest()} 
                            disabled={testing}
                            style={{ background: 'var(--primary)', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px' }}
                        >
                            <Play size={16} /> {testing ? 'Evaluating Engine...' : 'Run Moderation Analysis'}
                        </button>
                    </div>

                    {/* Results Panel */}
                    <div className="card" style={{ display: 'flex', flexDirection: 'column', gap: '1rem', background: '#f8fafc' }}>
                        <h2 style={{ fontSize: '1.15rem', margin: 0 }}>📊 Real-Time Diagnostic Output</h2>
                        
                        {testResult ? (
                            <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                                {/* Primary Verdict Card */}
                                <div style={{ 
                                    padding: '1rem', 
                                    borderRadius: '10px', 
                                    border: '1px solid',
                                    background: testResult.isBlocked ? '#fef2f2' : (testResult.isFlagged ? '#fffbeb' : '#f0fdf4'),
                                    borderColor: testResult.isBlocked ? '#fecaca' : (testResult.isFlagged ? '#fde68a' : '#bbf7d0')
                                }}>
                                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
                                        <span style={{ fontWeight: 'bold', fontSize: '1.1rem', color: testResult.isBlocked ? '#dc2626' : (testResult.isFlagged ? '#d97706' : '#16a34a') }}>
                                            {testResult.isBlocked ? '🚫 BLOCKED BY POLICY' : (testResult.isFlagged ? '⚠️ FLAGGED FOR ACTION' : '✅ SAFE / ALLOWED')}
                                        </span>
                                        {getActionPill(testResult.action)}
                                    </div>
                                    <div style={{ fontSize: '0.85rem', color: '#475569' }}>
                                        Highest Severity: {getSeverityPill(testResult.severity)} | Categories: {testResult.matchedCategories.length > 0 ? testResult.matchedCategories.join(', ') : 'None'}
                                    </div>
                                </div>

                                {/* Sanitized Output */}
                                <div>
                                    <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 'bold', color: '#64748b', marginBottom: '4px' }}>
                                        SANITIZED DELIVERED TEXT:
                                    </label>
                                    <div style={{ padding: '10px', background: 'white', borderRadius: '8px', border: '1px solid #e2e8f0', fontFamily: 'monospace', fontSize: '0.85rem' }}>
                                        {testResult.sanitizedText}
                                    </div>
                                </div>

                                {/* Client Feedback Notice */}
                                {testResult.feedbackMessage && (
                                    <div>
                                        <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 'bold', color: '#64748b', marginBottom: '4px' }}>
                                            CLIENT NOTIFICATION / SNACKBAR FEEDBACK:
                                        </label>
                                        <div style={{ padding: '10px', background: '#eff6ff', borderRadius: '8px', border: '1px solid #bfdbfe', color: '#1e40af', fontSize: '0.85rem' }}>
                                            {testResult.feedbackMessage}
                                        </div>
                                    </div>
                                )}

                                {/* Matched Rules */}
                                <div>
                                    <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 'bold', color: '#64748b', marginBottom: '4px' }}>
                                        MATCHED RULES ({testResult.matchedRules.length}):
                                    </label>
                                    {testResult.matchedRules.length === 0 ? (
                                        <div style={{ fontSize: '0.85rem', color: '#64748b', fontStyle: 'italic' }}>
                                            No forbidden rules triggered. Text passes safety thresholds.
                                        </div>
                                    ) : (
                                        <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
                                            {testResult.matchedRules.map((m, idx) => (
                                                <div key={idx} style={{ padding: '8px', background: 'white', borderRadius: '6px', border: '1px solid #e2e8f0', fontSize: '0.8rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                                    <div>
                                                        <strong>{m.name}</strong> <span style={{ color: '#64748b' }}>({m.category})</span>
                                                        <div style={{ color: '#dc2626', fontSize: '0.75rem', marginTop: '2px' }}>
                                                            Match: "{m.matchedSubstring}"
                                                        </div>
                                                    </div>
                                                    <div style={{ display: 'flex', gap: '6px' }}>
                                                        {getSeverityPill(m.severity)}
                                                        {getActionPill(m.action)}
                                                    </div>
                                                </div>
                                            ))}
                                        </div>
                                    )}
                                </div>
                            </div>
                        ) : (
                            <div style={{ textAlign: 'center', padding: '3rem', color: 'var(--text-muted)' }}>
                                Enter text on the left and click "Run Moderation Analysis" to inspect results.
                            </div>
                        )}
                    </div>
                </div>
            )}

            {/* TAB 3: FLAGGED CONTENT REVIEW QUEUE */}
            {activeTab === 'flagged' && (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                    {/* Status filter bar */}
                    <div className="card" style={{ padding: '1rem', display: 'flex', gap: '1rem', alignItems: 'center', justifyContent: 'space-between' }}>
                        <div style={{ display: 'flex', gap: '8px' }}>
                            {['pending', 'approved', 'dismissed', 'penalized', 'All'].map(st => (
                                <button
                                    key={st}
                                    className={`btn ${flaggedStatusFilter === st ? 'btn-primary' : 'btn-outline'}`}
                                    style={{ padding: '6px 12px', fontSize: '0.8rem', textTransform: 'capitalize' }}
                                    onClick={() => setFlaggedStatusFilter(st)}
                                >
                                    {st === 'penalized' ? '⚠️ Penalized' : st}
                                </button>
                            ))}
                        </div>
                        <div style={{ fontSize: '0.85rem', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: '4px' }}>
                            <Lock size={14} color="#10b981" /> Strict Privacy Mode: Full conversations locked; only masked snippets visible.
                        </div>
                    </div>

                    {/* Flagged Queue Table */}
                    <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
                        <div style={{ overflowX: 'auto' }}>
                            <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.875rem' }}>
                                <thead>
                                    <tr style={{ background: '#f8fafc', borderBottom: '1px solid var(--border)', textAlign: 'left', color: '#64748b' }}>
                                        <th style={{ padding: '12px 16px' }}>Student Profile</th>
                                        <th style={{ padding: '12px 16px' }}>Category</th>
                                        <th style={{ padding: '12px 16px' }}>Triggered Rule</th>
                                        <th style={{ padding: '12px 16px' }}>Privacy-Preserved Snippet</th>
                                        <th style={{ padding: '12px 16px' }}>Action Taken</th>
                                        <th style={{ padding: '12px 16px' }}>Review Status</th>
                                        <th style={{ padding: '12px 16px', textAlign: 'right' }}>Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {loading ? (
                                        <tr>
                                            <td colSpan="7" style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>
                                                Loading review queue...
                                            </td>
                                        </tr>
                                    ) : flaggedItems.length === 0 ? (
                                        <tr>
                                            <td colSpan="7" style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>
                                                No flagged items found under "{flaggedStatusFilter}".
                                            </td>
                                        </tr>
                                    ) : (
                                        flaggedItems.map(item => (
                                            <tr key={item.id} style={{ borderBottom: '1px solid var(--border)' }}>
                                                <td style={{ padding: '12px 16px' }}>
                                                    <div style={{ fontWeight: 'bold' }}>{item.offender?.full_name || 'Unknown'}</div>
                                                    <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                                                        @{item.offender?.username} • Warns: <span style={{ color: item.offender?.warning_count >= 2 ? '#dc2626' : 'inherit', fontWeight: 'bold' }}>{item.offender?.warning_count || 0}/3</span>
                                                    </div>
                                                </td>
                                                <td style={{ padding: '12px 16px' }}>
                                                    {getCategoryBadge(item.category)}
                                                </td>
                                                <td style={{ padding: '12px 16px' }}>
                                                    <div style={{ fontWeight: '500' }}>{item.matched_rule_name}</div>
                                                    {getSeverityPill(item.severity)}
                                                </td>
                                                <td style={{ padding: '12px 16px', maxWidth: '280px' }}>
                                                    <div style={{ background: '#f8fafc', padding: '6px 10px', borderRadius: '6px', border: '1px solid #e2e8f0', fontSize: '0.8rem', fontStyle: 'italic', color: '#334155' }}>
                                                        {item.matched_snippet || '(No snippet stored)'}
                                                    </div>
                                                </td>
                                                <td style={{ padding: '12px 16px' }}>
                                                    {getActionPill(item.action_taken)}
                                                </td>
                                                <td style={{ padding: '12px 16px' }}>
                                                    <span style={{ 
                                                        padding: '3px 8px', 
                                                        borderRadius: '4px', 
                                                        fontSize: '0.75rem', 
                                                        fontWeight: 'bold',
                                                        background: item.review_status === 'pending' ? '#fef3c7' : (item.review_status === 'penalized' ? '#fee2e2' : '#dcfce7'),
                                                        color: item.review_status === 'pending' ? '#b45309' : (item.review_status === 'penalized' ? '#991b1b' : '#15803d')
                                                    }}>
                                                        {item.review_status.toUpperCase()}
                                                    </span>
                                                </td>
                                                <td style={{ padding: '12px 16px', textAlign: 'right' }}>
                                                    {item.review_status === 'pending' ? (
                                                        <button 
                                                            className="btn btn-primary"
                                                            style={{ padding: '4px 10px', fontSize: '0.75rem' }}
                                                            onClick={() => { setResolvingItem(item); setReviewNotes(''); }}
                                                        >
                                                            Triage Incident
                                                        </button>
                                                    ) : (
                                                        <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                                                            {item.reviewer ? `By ${item.reviewer.username}` : 'Resolved'}
                                                        </span>
                                                    )}
                                                </td>
                                            </tr>
                                        ))
                                    )}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            )}

            {/* MODAL: ADD / EDIT RULE */}
            {isRuleModalOpen && (
                <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000, padding: '1rem' }}>
                    <div className="card" style={{ width: '100%', maxWidth: '560px', background: 'white', padding: '1.5rem', maxHeight: '90vh', overflowY: 'auto' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.25rem', borderBottom: '1px solid var(--border)', paddingBottom: '0.75rem' }}>
                            <h2 style={{ margin: 0, fontSize: '1.25rem' }}>
                                {editingRule ? 'Edit Moderation Rule' : 'Create New Moderation Rule'}
                            </h2>
                            <button className="btn btn-outline" style={{ padding: '4px 8px', height: 'auto' }} onClick={() => setIsRuleModalOpen(false)}>
                                <XCircle size={18} />
                            </button>
                        </div>

                        <form onSubmit={handleSaveRule} style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                            <div>
                                <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 'bold', marginBottom: '4px' }}>Rule Name *</label>
                                <input 
                                    type="text" 
                                    className="input" 
                                    required 
                                    placeholder="e.g. Phone Number Detector" 
                                    value={ruleForm.name} 
                                    onChange={(e) => setRuleForm({ ...ruleForm, name: e.target.value })}
                                />
                            </div>

                            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                                <div>
                                    <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 'bold', marginBottom: '4px' }}>Category *</label>
                                    <select 
                                        className="input" 
                                        value={ruleForm.category} 
                                        onChange={(e) => setRuleForm({ ...ruleForm, category: e.target.value })}
                                        style={{ appearance: 'auto' }}
                                    >
                                        <option value="privacy">Privacy / PII</option>
                                        <option value="off_platform_contact">Off-Platform Contact</option>
                                        <option value="profanity">Profanity & Abuse</option>
                                        <option value="harassment">Harassment & Threat</option>
                                        <option value="religious_sensitive">Religious / Sensitive</option>
                                        <option value="scam">Scam Risk</option>
                                        <option value="custom">Custom</option>
                                    </select>
                                </div>
                                <div>
                                    <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 'bold', marginBottom: '4px' }}>Matching Type *</label>
                                    <select 
                                        className="input" 
                                        value={ruleForm.match_type} 
                                        onChange={(e) => setRuleForm({ ...ruleForm, match_type: e.target.value })}
                                        style={{ appearance: 'auto' }}
                                    >
                                        <option value="keyword">Keyword List (Comma-separated)</option>
                                        <option value="phrase">Exact Phrase</option>
                                        <option value="regex">Regular Expression (Regex)</option>
                                        <option value="pattern">Pattern Detector</option>
                                    </select>
                                </div>
                            </div>

                            <div>
                                <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 'bold', marginBottom: '4px' }}>
                                    Matching Pattern / Keywords *
                                </label>
                                <textarea 
                                    className="input" 
                                    rows="3" 
                                    required 
                                    placeholder={ruleForm.match_type === 'keyword' ? 'word1, word2, word3' : '\\b(?:regex)\\b'} 
                                    value={ruleForm.pattern} 
                                    onChange={(e) => setRuleForm({ ...ruleForm, pattern: e.target.value })}
                                    style={{ fontFamily: 'monospace' }}
                                />
                            </div>

                            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                                <div>
                                    <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 'bold', marginBottom: '4px' }}>Severity Level *</label>
                                    <select 
                                        className="input" 
                                        value={ruleForm.severity} 
                                        onChange={(e) => setRuleForm({ ...ruleForm, severity: e.target.value })}
                                        style={{ appearance: 'auto' }}
                                    >
                                        <option value="low">Low</option>
                                        <option value="medium">Medium</option>
                                        <option value="high">High</option>
                                        <option value="critical">Critical</option>
                                    </select>
                                </div>
                                <div>
                                    <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 'bold', marginBottom: '4px' }}>Enforced Action *</label>
                                    <select 
                                        className="input" 
                                        value={ruleForm.action} 
                                        onChange={(e) => setRuleForm({ ...ruleForm, action: e.target.value })}
                                        style={{ appearance: 'auto' }}
                                    >
                                        <option value="flag">Flag for Review Queue</option>
                                        <option value="mask">Mask (Replace with ***)</option>
                                        <option value="block">Block Delivery Immediately</option>
                                        <option value="warn">Warn User Notice</option>
                                        <option value="allow">Allow (Whitelist Bypass)</option>
                                    </select>
                                </div>
                            </div>

                            <div>
                                <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 'bold', marginBottom: '4px' }}>Description / Moderator Guidance</label>
                                <input 
                                    type="text" 
                                    className="input" 
                                    placeholder="Explain why this rule exists..." 
                                    value={ruleForm.description} 
                                    onChange={(e) => setRuleForm({ ...ruleForm, description: e.target.value })}
                                />
                            </div>

                            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                <input 
                                    type="checkbox" 
                                    id="ruleEnabled" 
                                    checked={ruleForm.is_enabled} 
                                    onChange={(e) => setRuleForm({ ...ruleForm, is_enabled: e.target.checked })} 
                                />
                                <label htmlFor="ruleEnabled" style={{ fontSize: '0.85rem', fontWeight: 'bold', cursor: 'pointer' }}>
                                    Enable this rule immediately across platform
                                </label>
                            </div>

                            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '1rem' }}>
                                <button type="button" className="btn btn-outline" onClick={() => setIsRuleModalOpen(false)}>Cancel</button>
                                <button type="submit" className="btn btn-primary" style={{ background: 'var(--primary)' }}>Save Rule</button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* MODAL: TRIAGE FLAGGED INCIDENT */}
            {resolvingItem && (
                <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000, padding: '1rem' }}>
                    <div className="card" style={{ width: '100%', maxWidth: '520px', background: 'white', padding: '1.5rem' }}>
                        <h2 style={{ margin: '0 0 1rem 0', fontSize: '1.25rem' }}>Triage Flagged Content #{resolvingItem.id.substring(0, 8)}</h2>
                        
                        <div style={{ background: '#f8fafc', padding: '12px', borderRadius: '8px', marginBottom: '1rem', border: '1px solid #e2e8f0', fontSize: '0.85rem' }}>
                            <div><strong>Student:</strong> {resolvingItem.offender?.full_name} (@{resolvingItem.offender?.username})</div>
                            <div><strong>Violated Rule:</strong> {resolvingItem.matched_rule_name} ({resolvingItem.category})</div>
                            <div style={{ marginTop: '6px' }}><strong>Masked Snippet:</strong></div>
                            <div style={{ fontStyle: 'italic', color: '#b91c1c', marginTop: '2px' }}>
                                "{resolvingItem.matched_snippet}"
                            </div>
                        </div>

                        <div style={{ marginBottom: '1.25rem' }}>
                            <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 'bold', marginBottom: '4px' }}>Internal Triage Notes</label>
                            <textarea 
                                className="input" 
                                rows="3" 
                                placeholder="Add notes on your resolution decision..." 
                                value={reviewNotes} 
                                onChange={(e) => setReviewNotes(e.target.value)} 
                            />
                        </div>

                        <div style={{ display: 'flex', justifyContent: 'space-between', gap: '8px', flexWrap: 'wrap' }}>
                            <button className="btn btn-outline" onClick={() => setResolvingItem(null)}>Cancel</button>
                            <div style={{ display: 'flex', gap: '8px' }}>
                                <button 
                                    className="btn btn-outline" 
                                    disabled={actionLoading}
                                    onClick={() => handleResolve('dismissed')}
                                    style={{ color: '#64748b' }}
                                >
                                    Dismiss False Alarm
                                </button>
                                <button 
                                    className="btn" 
                                    disabled={actionLoading}
                                    onClick={() => handleResolve('approved')}
                                    style={{ background: 'var(--primary)', color: 'white' }}
                                >
                                    Mark Reviewed
                                </button>
                                <button 
                                    className="btn" 
                                    disabled={actionLoading}
                                    onClick={() => handleResolve('penalized')}
                                    style={{ background: 'var(--danger)', color: 'white' }}
                                >
                                    ⚠️ Apply Sanction
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default Moderation;
