import React from 'react';
import { Search } from 'lucide-react';

const Users = () => {
    return (
        <div>
            <div className="flex justify-between items-center mb-8">
                <h1 style={{ fontSize: '1.5rem', margin: 0 }}>User Directory</h1>
                <div className="flex gap-4">
                    <div style={{ 
                        display: 'flex', alignItems: 'center', 
                        background: 'white', 
                        border: '1px solid var(--border)',
                        borderRadius: '8px',
                        padding: '8px 16px',
                        width: '250px'
                    }}>
                        <Search size={18} color="var(--text-muted)" style={{ marginRight: '8px' }} />
                        <input 
                            type="text" 
                            placeholder="Search users..." 
                            style={{ border: 'none', background: 'transparent', outline: 'none', width: '100%' }}
                        />
                    </div>
                    <select className="input" style={{ width: '150px', marginBottom: 0 }}>
                        <option>All Status</option>
                        <option>Active</option>
                        <option>Banned</option>
                    </select>
                </div>
            </div>

            <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
                <table>
                    <thead>
                        <tr>
                            <th>USER ID</th>
                            <th>NAME/EMAIL</th>
                            <th>ROLE</th>
                            <th>ECO-SCORE</th>
                            <th>REPORTS AGAINST</th>
                            <th>STATUS</th>
                            <th>ACTIONS</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td style={{ color: 'var(--text-muted)' }}>USR-1024</td>
                            <td>
                                <div>Sarah Chen</div>
                                <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>sarah.chen@university.edu</div>
                            </td>
                            <td style={{ color: 'var(--text-muted)' }}>Student</td>
                            <td style={{ color: 'var(--primary)', fontWeight: 'bold' }}>85</td>
                            <td style={{ color: 'var(--text-muted)' }}>0</td>
                            <td>
                                <span style={{ padding: '4px 12px', background: '#dcfce7', borderRadius: '12px', color: '#16a34a', fontSize: '0.75rem', fontWeight: 'bold' }}>
                                    Active
                                </span>
                            </td>
                            <td>
                                <button style={{ background: 'none', border: 'none', color: 'var(--primary)', fontWeight: 'bold', cursor: 'pointer' }}>View Details</button>
                            </td>
                        </tr>
                        <tr>
                            <td style={{ color: 'var(--text-muted)' }}>USR-0892</td>
                            <td>
                                <div>Mark Johnson</div>
                                <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>mark.j@university.edu</div>
                            </td>
                            <td style={{ color: 'var(--text-muted)' }}>Student</td>
                            <td style={{ color: 'var(--primary)', fontWeight: 'bold' }}>25</td>
                            <td style={{ color: 'var(--danger)', fontWeight: 'bold' }}>7</td>
                            <td>
                                <span style={{ padding: '4px 12px', background: '#fee2e2', borderRadius: '12px', color: '#dc2626', fontSize: '0.75rem', fontWeight: 'bold' }}>
                                    Banned
                                </span>
                            </td>
                            <td>
                                <button style={{ background: 'none', border: 'none', color: 'var(--primary)', fontWeight: 'bold', cursor: 'pointer' }}>View Details</button>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    );
};

export default Users;
