import React, { useState, useEffect } from 'react';
import { CheckCircle2, DatabaseBackup } from 'lucide-react';
import api from '../services/api';

const Backup = () => {
    const [backups, setBackups] = useState([]);
    const [loading, setLoading] = useState(true);
    const [triggering, setTriggering] = useState(false);

    useEffect(() => {
        fetchBackups();
    }, []);

    const fetchBackups = async () => {
        try {
            const res = await api.get('/admin/backups');
            setBackups(res.data);
        } catch (err) {
            console.error('Failed to fetch backups', err);
        } finally {
            setLoading(false);
        }
    };

    const handleTriggerBackup = async () => {
        setTriggering(true);
        try {
            await api.post('/admin/backup');
            alert('Manual backup triggered successfully!');
            fetchBackups();
        } catch (err) {
            alert('Failed to trigger backup');
        } finally {
            setTriggering(false);
        }
    };

    const handleRestore = async (id) => {
        if (!window.confirm('Are you sure you want to restore to this point? The system will go offline temporarily.')) return;
        try {
            await api.post(`/admin/restore/${id}`);
            alert('Restore sequence initiated. Please wait...');
        } catch (err) {
            alert('Failed to initiate restore');
        }
    };

    if (loading) return <div className="p-8 text-center text-gray-500">Loading backup history...</div>;

    // Find last auto backup for the banner
    const lastAuto = backups.find(b => b.type === 'Auto');
    const lastAutoText = lastAuto 
        ? `Last automated backup completed at ${new Date(lastAuto.createdAt).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}`
        : 'No automated backups yet.';

    return (
        <div>
            <div className="flex justify-between items-center mb-8">
                <h1 style={{ fontSize: '1.5rem', margin: 0 }}>System Backup & Restore</h1>
            </div>

            {/* Health Banner */}
            <div className="card flex justify-between items-center mb-8" style={{ padding: '24px' }}>
                <div className="flex items-center gap-4">
                    <CheckCircle2 color="#16a34a" size={32} />
                    <div>
                        <div style={{ fontWeight: 'bold', fontSize: '1.1rem', marginBottom: '4px' }}>System Healthy</div>
                        <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem' }}>{lastAutoText}</div>
                    </div>
                </div>
                <button 
                    className="btn flex items-center gap-2" 
                    onClick={handleTriggerBackup}
                    disabled={triggering}
                    style={{ background: '#14532d', padding: '12px 24px', fontSize: '0.9rem' }}
                >
                    <DatabaseBackup size={18} />
                    {triggering ? 'Backing up...' : 'Trigger Manual Backup Now'}
                </button>
            </div>

            {/* History Table */}
            <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
                <div style={{ padding: '20px 24px', borderBottom: '1px solid var(--border)' }}>
                    <h2 style={{ margin: 0, fontSize: '1.1rem' }}>Backup History Logs</h2>
                </div>
                
                <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                    <thead>
                        <tr style={{ borderBottom: '1px solid var(--border)', background: '#f8fafc' }}>
                            <th style={{ padding: '16px 24px', textAlign: 'left', color: 'var(--text-muted)', fontSize: '0.75rem', fontWeight: 'bold', letterSpacing: '1px' }}>TIMESTAMP</th>
                            <th style={{ padding: '16px 24px', textAlign: 'left', color: 'var(--text-muted)', fontSize: '0.75rem', fontWeight: 'bold', letterSpacing: '1px' }}>TYPE</th>
                            <th style={{ padding: '16px 24px', textAlign: 'left', color: 'var(--text-muted)', fontSize: '0.75rem', fontWeight: 'bold', letterSpacing: '1px' }}>SIZE</th>
                            <th style={{ padding: '16px 24px', textAlign: 'left', color: 'var(--text-muted)', fontSize: '0.75rem', fontWeight: 'bold', letterSpacing: '1px' }}>STATUS</th>
                            <th style={{ padding: '16px 24px', textAlign: 'left', color: 'var(--text-muted)', fontSize: '0.75rem', fontWeight: 'bold', letterSpacing: '1px' }}>ACTION</th>
                        </tr>
                    </thead>
                    <tbody>
                        {backups.map((log) => (
                            <tr key={log.id} style={{ borderBottom: '1px solid var(--border)' }}>
                                <td style={{ padding: '16px 24px', fontSize: '0.875rem' }}>
                                    {new Date(log.createdAt).toLocaleString()}
                                </td>
                                <td style={{ padding: '16px 24px' }}>
                                    <span style={{ 
                                        padding: '4px 12px', 
                                        borderRadius: '12px', 
                                        fontSize: '0.75rem', 
                                        fontWeight: 'bold',
                                        background: log.type === 'Auto' ? '#dbeafe' : '#f3e8ff',
                                        color: log.type === 'Auto' ? '#1e40af' : '#6b21a8'
                                    }}>
                                        {log.type}
                                    </span>
                                </td>
                                <td style={{ padding: '16px 24px', fontSize: '0.875rem' }}>{log.size}</td>
                                <td style={{ padding: '16px 24px', fontSize: '0.875rem', color: '#16a34a', fontWeight: 'bold' }}>
                                    {log.status}
                                </td>
                                <td style={{ padding: '16px 24px' }}>
                                    <button 
                                        onClick={() => handleRestore(log.id)}
                                        style={{ 
                                            background: 'white', 
                                            border: '1px solid var(--border)', 
                                            padding: '6px 16px', 
                                            borderRadius: '20px',
                                            fontSize: '0.75rem',
                                            fontWeight: 'bold',
                                            cursor: 'pointer',
                                            color: '#475569'
                                        }}
                                        onMouseOver={(e) => { e.currentTarget.style.borderColor = '#94a3b8'; e.currentTarget.style.color = '#1e293b'; }}
                                        onMouseOut={(e) => { e.currentTarget.style.borderColor = 'var(--border)'; e.currentTarget.style.color = '#475569'; }}
                                    >
                                        Restore Point
                                    </button>
                                </td>
                            </tr>
                        ))}
                        {backups.length === 0 && (
                            <tr>
                                <td colSpan="5" style={{ padding: '24px', textAlign: 'center', color: 'var(--text-muted)' }}>
                                    No backup history found.
                                </td>
                            </tr>
                        )}
                    </tbody>
                </table>
            </div>
        </div>
    );
};

export default Backup;
