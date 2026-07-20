import React, { useState, useEffect } from 'react';
import { Settings, Shield, Activity, HardDrive, Cpu, RefreshCw, Save, CheckCircle2, AlertTriangle, FileText, Database } from 'lucide-react';
import api from '../services/api';

const System = () => {
    const [activeTab, setActiveTab] = useState('diagnostics');
    const [health, setHealth] = useState(null);
    const [healthLoading, setHealthLoading] = useState(true);
    
    // Configurations State
    const [configs, setConfigs] = useState({});
    const [configsLoading, setConfigsLoading] = useState(true);
    const [saveConfigStatus, setSaveConfigStatus] = useState(null);

    // Policy Editor State
    const [policyType, setPolicyType] = useState('TERMS');
    const [policyContent, setPolicyContent] = useState('');
    const [policyVersion, setPolicyVersion] = useState('1.0.0');
    const [policyLoading, setPolicyLoading] = useState(false);
    const [savePolicyStatus, setSavePolicyStatus] = useState(null);

    // Fetch Health Stats
    const fetchHealth = async () => {
        setHealthLoading(true);
        try {
            const res = await api.get('/admin/system/health');
            setHealth(res.data);
        } catch (e) {
            console.error('Failed to fetch system health', e);
        } finally {
            setHealthLoading(false);
        }
    };

    // Fetch Configs
    const fetchConfigs = async () => {
        setConfigsLoading(true);
        try {
            const res = await api.get('/admin/system/settings');
            const configMap = {};
            res.data.forEach(c => {
                configMap[c.key] = { value: c.value, description: c.description };
            });
            setConfigs(configMap);
        } catch (e) {
            console.error('Failed to fetch configurations', e);
        } finally {
            setConfigsLoading(false);
        }
    };

    // Fetch Policy by current selected type
    const fetchPolicy = async (type) => {
        setPolicyLoading(true);
        setSavePolicyStatus(null);
        try {
            const res = await api.get(`/policies/${type}`);
            setPolicyContent(res.data.content);
            setPolicyVersion(res.data.version);
        } catch (e) {
            console.error('Failed to fetch policy', e);
        } finally {
            setPolicyLoading(false);
        }
    };

    useEffect(() => {
        fetchHealth();
        fetchConfigs();
        fetchPolicy(policyType);
    }, []);

    // Fetch policy on change of type
    const handlePolicyTypeChange = (e) => {
        const type = e.target.value;
        setPolicyType(type);
        fetchPolicy(type);
    };

    // Save Configurations
    const handleSaveConfigs = async (e) => {
        e.preventDefault();
        setSaveConfigStatus(null);
        try {
            const payload = {};
            Object.keys(configs).forEach(k => {
                payload[k] = configs[k].value;
            });
            await api.put('/admin/system/settings', { settings: payload });
            setSaveConfigStatus({ success: true, message: 'Settings saved successfully!' });
            setTimeout(() => setSaveConfigStatus(null), 3000);
        } catch (err) {
            console.error('Failed to save settings', err);
            setSaveConfigStatus({ success: false, message: err.response?.data?.error || 'Failed to save settings.' });
        }
    };

    const handleConfigValueChange = (key, val) => {
        setConfigs(prev => ({
            ...prev,
            [key]: {
                ...prev[key],
                value: val
            }
        }));
    };

    // Save Platform Policy
    const handleSavePolicy = async (e) => {
        e.preventDefault();
        setSavePolicyStatus(null);
        try {
            const res = await api.put(`/admin/system/policies/${policyType}`, {
                content: policyContent,
                version: policyVersion
            });
            setSavePolicyStatus({ success: true, message: `Successfully published version ${policyVersion}!` });
            setTimeout(() => setSavePolicyStatus(null), 3000);
        } catch (err) {
            console.error('Failed to publish policy', err);
            setSavePolicyStatus({ success: false, message: err.response?.data?.error || 'Failed to publish policy.' });
        }
    };

    return (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
            <style dangerouslySetInnerHTML={{
                __html: `
                .tab-btn {
                    padding: 10px 20px;
                    border: none;
                    background: transparent;
                    color: var(--text-muted);
                    font-size: 0.95rem;
                    font-weight: 600;
                    cursor: pointer;
                    border-bottom: 2px solid transparent;
                    transition: all 0.2s ease;
                }
                .tab-btn.active {
                    color: var(--primary);
                    border-bottom-color: var(--primary);
                }
                .tab-btn:hover {
                    color: var(--primary);
                }
                .diagnostics-grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
                    gap: 1.5rem;
                }
                .config-row {
                    display: flex;
                    align-items: center;
                    justify-content: space-between;
                    padding: 1.25rem 0;
                    border-bottom: 1px solid var(--border);
                }
                .config-row:last-child {
                    border-bottom: none;
                }
                .policy-textarea {
                    width: 100%;
                    min-height: 250px;
                    font-family: 'Courier New', Courier, monospace;
                    padding: 1rem;
                    border-radius: 8px;
                    border: 1px solid var(--border);
                    resize: vertical;
                    font-size: 0.9rem;
                    line-height: 1.5;
                    box-sizing: border-box;
                }
                .policy-textarea:focus {
                    outline: 2px solid var(--primary);
                }
                .badge-healthy {
                    background: #dcfce7;
                    color: #16a34a;
                    padding: 4px 10px;
                    border-radius: 6px;
                    font-weight: 700;
                    font-size: 0.75rem;
                }
                .badge-error {
                    background: #fee2e2;
                    color: #dc2626;
                    padding: 4px 10px;
                    border-radius: 6px;
                    font-weight: 700;
                    font-size: 0.75rem;
                }
                @keyframes spin {
                    from { transform: rotate(0deg); }
                    to { transform: rotate(360deg); }
                }
                .spin-animation {
                    animation: spin 1s linear infinite;
                }
            `}} />

            {/* Header */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid var(--border)', paddingBottom: '1.5rem' }}>
                <div>
                    <h1 style={{ fontSize: '1.75rem', margin: 0, fontWeight: 'bold', color: 'var(--primary)', display: 'flex', alignItems: 'center', gap: '10px' }}>
                        <Settings size={28} />
                        <span>System Settings & Management</span>
                    </h1>
                    <p style={{ margin: '4px 0 0 0', fontSize: '0.875rem', color: 'var(--text-muted)' }}>
                        Oversight suite to monitor system diagnostics, configure parameters, and edit user policies.
                    </p>
                </div>
            </div>

            {/* Navigation Tabs */}
            <div style={{ display: 'flex', borderBottom: '1px solid var(--border)', gap: '1rem', marginTop: '-1rem' }}>
                <button 
                    className={`tab-btn ${activeTab === 'diagnostics' ? 'active' : ''}`}
                    onClick={() => setActiveTab('diagnostics')}
                >
                    System Health & Diagnostics
                </button>
                <button 
                    className={`tab-btn ${activeTab === 'configs' ? 'active' : ''}`}
                    onClick={() => setActiveTab('configs')}
                >
                    Platform Configurations
                </button>
                <button 
                    className={`tab-btn ${activeTab === 'policies' ? 'active' : ''}`}
                    onClick={() => setActiveTab('policies')}
                >
                    Policy & Guidelines Editor
                </button>
            </div>

            {/* Tab Contents */}
            <div style={{ minHeight: '400px' }}>
                {/* 1. Health Tab */}
                {activeTab === 'diagnostics' && (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                            <h3 style={{ margin: 0, fontSize: '1.1rem', fontWeight: 'bold', color: 'var(--text-main)' }}>Backend Node Server Metrics</h3>
                            <button className="btn btn-outline flex items-center gap-2" onClick={fetchHealth} disabled={healthLoading} style={{ height: '36px', padding: '0 0.75rem' }}>
                                <RefreshCw size={14} className={healthLoading ? 'spin-animation' : ''} />
                                <span>{healthLoading ? 'Refetching...' : 'Refresh Diagnostics'}</span>
                            </button>
                        </div>

                        {healthLoading && !health ? (
                            <div style={{ textAlign: 'center', padding: '4rem', color: 'var(--text-muted)' }}>
                                <RefreshCw size={24} className="spin-animation" style={{ margin: '0 auto 1rem auto' }} />
                                <span>Loading health diagnostics...</span>
                            </div>
                        ) : health ? (
                            <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
                                {/* KPI diagnostics grid */}
                                <div className="diagnostics-grid">
                                    <div className="card" style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                                        <div style={{ background: '#eff6ff', color: '#2563eb', padding: '0.75rem', borderRadius: '12px' }}>
                                            <Database size={24} />
                                        </div>
                                        <div style={{ flex: 1 }}>
                                            <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: '500' }}>Database Status</div>
                                            <div style={{ marginTop: '4px' }}>
                                                <span className={health.db_status === 'healthy' ? 'badge-healthy' : 'badge-error'}>
                                                    {health.db_status === 'healthy' ? 'Healthy (SELECT 1 OK)' : 'Database Error'}
                                                </span>
                                            </div>
                                        </div>
                                    </div>

                                    <div className="card" style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                                        <div style={{ background: '#faf5ff', color: '#8b5cf6', padding: '0.75rem', borderRadius: '12px' }}>
                                            <Cpu size={24} />
                                        </div>
                                        <div style={{ flex: 1 }}>
                                            <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: '500' }}>Server Uptime</div>
                                            <div style={{ fontSize: '1.05rem', fontWeight: 'bold', color: 'var(--text-main)', marginTop: '4px' }}>{health.uptime}</div>
                                        </div>
                                    </div>

                                    <div className="card" style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                                        <div style={{ background: '#f0fdf4', color: '#16a34a', padding: '0.75rem', borderRadius: '12px' }}>
                                            <HardDrive size={24} />
                                        </div>
                                        <div style={{ flex: 1 }}>
                                            <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: '500' }}>Memory Heap Used</div>
                                            <div style={{ fontSize: '1.05rem', fontWeight: 'bold', color: 'var(--text-main)', marginTop: '4px' }}>{health.memory_usage.heapUsed}</div>
                                            <div style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>Total allocated: {health.memory_usage.heapTotal}</div>
                                        </div>
                                    </div>

                                    <div className="card" style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                                        <div style={{ background: '#fff7ed', color: '#ea580c', padding: '0.75rem', borderRadius: '12px' }}>
                                            <Activity size={24} />
                                        </div>
                                        <div style={{ flex: 1 }}>
                                            <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: '500' }}>Active Sessions</div>
                                            <div style={{ fontSize: '1.25rem', fontWeight: '800', color: 'var(--primary)', marginTop: '4px' }}>{health.active_sessions}</div>
                                            <div style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>Active JWT in 1hr</div>
                                        </div>
                                    </div>
                                </div>

                                {/* Raw diagnostics stats card */}
                                <div className="card">
                                    <h4 style={{ margin: '0 0 1rem 0', fontSize: '0.95rem', fontWeight: 'bold', color: 'var(--text-main)' }}>Detailed Diagnostics Payload</h4>
                                    <div style={{ background: '#f8fafc', border: '1px solid var(--border)', borderRadius: '8px', padding: '1rem' }}>
                                        <pre style={{ margin: 0, fontSize: '0.825rem', color: '#334155', overflowX: 'auto', fontFamily: 'Courier New, monospace' }}>
                                            {JSON.stringify(health, null, 4)}
                                        </pre>
                                    </div>
                                    <div style={{ marginTop: '8px', fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                                        Diagnostics snapshot recorded at {new Date(health.timestamp).toLocaleString()}
                                    </div>
                                </div>
                            </div>
                        ) : (
                            <div style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>
                                <span>No health snapshot fetched.</span>
                            </div>
                        )}
                    </div>
                )}

                {/* 2. Configs Tab */}
                {activeTab === 'configs' && (
                    <div className="card" style={{ padding: '2rem' }}>
                        <h3 style={{ margin: '0 0 1.5rem 0', fontSize: '1.1rem', fontWeight: 'bold', color: 'var(--primary)' }}>Edit Platform Parameters</h3>

                        {saveConfigStatus && (
                            <div style={{
                                padding: '1rem',
                                borderRadius: '8px',
                                border: '1px solid',
                                background: saveConfigStatus.success ? '#f0fdf4' : '#fef2f2',
                                borderColor: saveConfigStatus.success ? '#bbf7d0' : '#fecaca',
                                color: saveConfigStatus.success ? '#15803d' : '#b91c1c',
                                marginBottom: '1.5rem',
                                display: 'flex',
                                alignItems: 'center',
                                gap: '8px',
                                fontSize: '0.875rem'
                            }}>
                                {saveConfigStatus.success ? <CheckCircle2 size={16} /> : <AlertTriangle size={16} />}
                                <span>{saveConfigStatus.message}</span>
                            </div>
                        )}

                        {configsLoading ? (
                            <div style={{ padding: '3rem', textAlign: 'center', color: 'var(--text-muted)' }}>
                                <RefreshCw className="spin-animation" size={24} style={{ margin: '0 auto 1rem auto' }} />
                                <span>Loading system configurations...</span>
                            </div>
                        ) : (
                            <form onSubmit={handleSaveConfigs} style={{ display: 'flex', flexDirection: 'column' }}>
                                <div style={{ display: 'flex', flexDirection: 'column' }}>
                                    {Object.keys(configs).map((k) => (
                                        <div className="config-row" key={k}>
                                            <div style={{ flex: 1, paddingRight: '2rem' }}>
                                                <div style={{ fontWeight: 'bold', color: 'var(--text-main)', fontSize: '0.9rem' }}>{k}</div>
                                                <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: '2px' }}>{configs[k].description}</div>
                                            </div>
                                            <div>
                                                {configs[k].value === 'true' || configs[k].value === 'false' ? (
                                                    <select
                                                        value={configs[k].value}
                                                        onChange={(e) => handleConfigValueChange(k, e.target.value)}
                                                        className="input"
                                                        style={{ width: '150px', marginBottom: 0, height: '38px', padding: '0 8px' }}
                                                    >
                                                        <option value="true">Enabled (True)</option>
                                                        <option value="false">Disabled (False)</option>
                                                    </select>
                                                ) : (
                                                    <input
                                                        type="text"
                                                        value={configs[k].value}
                                                        onChange={(e) => handleConfigValueChange(k, e.target.value)}
                                                        className="input"
                                                        style={{ width: '220px', marginBottom: 0, height: '38px', boxSizing: 'border-box' }}
                                                    />
                                                )}
                                            </div>
                                        </div>
                                    ))}
                                </div>

                                <button type="submit" className="btn flex items-center justify-center gap-2 mt-8" style={{ alignSelf: 'flex-end', height: '44px', padding: '0 2rem' }}>
                                    <Save size={16} />
                                    <span>Save Platform Configurations</span>
                                </button>
                            </form>
                        )}
                    </div>
                )}

                {/* 3. Policies Tab */}
                {activeTab === 'policies' && (
                    <div className="card" style={{ padding: '2rem', display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
                            <div>
                                <h3 style={{ margin: 0, fontSize: '1.1rem', fontWeight: 'bold', color: 'var(--primary)' }}>Policy & Terms Publisher</h3>
                                <p style={{ margin: '4px 0 0 0', fontSize: '0.8rem', color: 'var(--text-muted)' }}>Publish updated terms instantly to the Flutter mobile app.</p>
                            </div>

                            <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                                <select 
                                    className="input"
                                    style={{ width: '240px', marginBottom: 0, height: '38px', padding: '0 8px' }}
                                    value={policyType}
                                    onChange={handlePolicyTypeChange}
                                >
                                    <option value="TERMS">Terms of Service</option>
                                    <option value="PRIVACY">Privacy Policy</option>
                                    <option value="COMMUNITY_RULES">Community Guidelines</option>
                                </select>
                            </div>
                        </div>

                        {savePolicyStatus && (
                            <div style={{
                                padding: '1rem',
                                borderRadius: '8px',
                                border: '1px solid',
                                background: savePolicyStatus.success ? '#f0fdf4' : '#fef2f2',
                                borderColor: savePolicyStatus.success ? '#bbf7d0' : '#fecaca',
                                color: savePolicyStatus.success ? '#15803d' : '#b91c1c',
                                display: 'flex',
                                alignItems: 'center',
                                gap: '8px',
                                fontSize: '0.875rem'
                            }}>
                                {savePolicyStatus.success ? <CheckCircle2 size={16} /> : <AlertTriangle size={16} />}
                                <span>{savePolicyStatus.message}</span>
                            </div>
                        )}

                        {policyLoading ? (
                            <div style={{ padding: '4rem', textAlign: 'center', color: 'var(--text-muted)' }}>
                                <RefreshCw className="spin-animation" size={24} style={{ margin: '0 auto 1rem auto' }} />
                                <span>Loading policy text details...</span>
                            </div>
                        ) : (
                            <form onSubmit={handleSavePolicy} style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                                <div style={{ display: 'flex', gap: '1.5rem', alignItems: 'center' }}>
                                    <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
                                        <label style={{ fontSize: '0.8rem', fontWeight: 'bold', color: 'var(--text-main)' }}>Policy Version</label>
                                        <input 
                                            type="text" 
                                            value={policyVersion}
                                            onChange={(e) => setPolicyVersion(e.target.value)}
                                            placeholder="e.g. 1.0.2"
                                            className="input"
                                            style={{ width: '150px', marginBottom: 0, height: '38px', boxSizing: 'border-box' }}
                                            required
                                        />
                                    </div>
                                    <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', alignSelf: 'flex-end', paddingBottom: '10px' }}>
                                        We support formatting policy content using standard Markdown headers and lists.
                                    </div>
                                </div>

                                <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
                                    <label style={{ fontSize: '0.8rem', fontWeight: 'bold', color: 'var(--text-main)' }}>Markdown Content Editor</label>
                                    <textarea 
                                        value={policyContent}
                                        onChange={(e) => setPolicyContent(e.target.value)}
                                        className="policy-textarea"
                                        placeholder="Write policy terms in markdown..."
                                        required
                                    />
                                </div>

                                <button type="submit" className="btn flex items-center justify-center gap-2 mt-4" style={{ alignSelf: 'flex-end', height: '44px', padding: '0 2rem' }}>
                                    <FileText size={16} />
                                    <span>Publish Updated Policy</span>
                                </button>
                            </form>
                        )}
                    </div>
                )}
            </div>
        </div>
    );
};

export default System;
