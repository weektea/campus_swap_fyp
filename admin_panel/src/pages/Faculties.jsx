import React, { useState, useEffect } from 'react';
import { Plus, Trash2, Edit, GraduationCap, School } from 'lucide-react';
import api from '../services/api';

const Faculties = () => {
    const [faculties, setFaculties] = useState([]);
    const [loading, setLoading] = useState(true);
    const [currentUser, setCurrentUser] = useState(null);

    // Modals
    const [isAddModalOpen, setIsAddModalOpen] = useState(false);
    const [isEditModalOpen, setIsEditModalOpen] = useState(false);

    // Form States
    const [newCode, setNewCode] = useState('');
    const [newName, setNewName] = useState('');
    const [newActive, setNewActive] = useState(true);

    const [editId, setEditId] = useState(null);
    const [editCode, setEditCode] = useState('');
    const [editName, setEditName] = useState('');
    const [editActive, setEditActive] = useState(true);

    useEffect(() => {
        const userStr = localStorage.getItem('user');
        if (userStr) setCurrentUser(JSON.parse(userStr));
        fetchFaculties();
    }, []);

    const fetchFaculties = async () => {
        setLoading(true);
        try {
            const res = await api.get('/admin/faculties');
            setFaculties(res.data || []);
        } catch (err) {
            console.error('Failed to fetch faculties:', err);
        } finally {
            setLoading(false);
        }
    };

    const handleAddFaculty = async () => {
        try {
            await api.post('/admin/faculties', {
                code: newCode,
                name: newName,
                is_active: newActive
            });
            setIsAddModalOpen(false);
            setNewCode('');
            setNewName('');
            setNewActive(true);
            fetchFaculties();
        } catch (err) {
            alert(err.response?.data?.error || 'Failed to add faculty');
        }
    };

    const openEditModal = (fac) => {
        setEditId(fac.id);
        setEditCode(fac.code);
        setEditName(fac.name);
        setEditActive(fac.is_active !== false);
        setIsEditModalOpen(true);
    };

    const handleEditFaculty = async () => {
        try {
            await api.put(`/admin/faculties/${editId}`, {
                code: editCode,
                name: editName,
                is_active: editActive
            });
            setIsEditModalOpen(false);
            fetchFaculties();
        } catch (err) {
            alert(err.response?.data?.error || 'Failed to update faculty');
        }
    };

    const handleDeleteFaculty = async (id, code) => {
        if (!window.confirm(`Delete faculty '${code}'?`)) return;
        try {
            await api.delete(`/admin/faculties/${id}`);
            fetchFaculties();
        } catch (err) {
            alert(err.response?.data?.error || 'Failed to delete faculty');
        }
    };

    if (loading) return <div className="p-8 text-center text-gray-500">Loading faculties...</div>;

    const isAdmin = currentUser?.role === 'admin';
    const activeCount = faculties.filter(f => f.is_active !== false).length;

    return (
        <div>
            {/* Header section */}
            <div className="flex justify-between items-center mb-8">
                <div className="flex items-center gap-3">
                    <h1 style={{ fontSize: '1.5rem', margin: 0, display: 'flex', alignItems: 'center', gap: '10px' }}>
                        <GraduationCap size={28} color="var(--primary)" /> Campus Faculties Management
                    </h1>
                    <span style={{ fontSize: '0.85rem', padding: '4px 12px', borderRadius: '12px', background: '#eff6ff', color: '#2563eb', fontWeight: 'bold', border: '1px solid #bfdbfe' }}>
                        Total Faculties: {faculties.length}
                    </span>
                    <span style={{ fontSize: '0.85rem', padding: '4px 12px', borderRadius: '12px', background: '#ecfdf5', color: '#059669', fontWeight: 'bold', border: '1px solid #a7f3d0' }}>
                        Active: {activeCount}
                    </span>
                </div>
                {isAdmin && (
                    <button className="btn" onClick={() => setIsAddModalOpen(true)}>
                        <Plus size={18} style={{ marginRight: '4px' }} /> Add Faculty
                    </button>
                )}
            </div>

            {/* Table Card */}
            <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
                <table style={{ margin: 0 }}>
                    <thead>
                        <tr>
                            <th style={{ width: '60px', textAlign: 'center' }}>NO.</th>
                            <th style={{ width: '120px' }}>CODE</th>
                            <th>FULL FACULTY NAME</th>
                            <th style={{ width: '120px' }}>STATUS</th>
                            {isAdmin && <th style={{ textAlign: 'right', width: '120px' }}>ACTIONS</th>}
                        </tr>
                    </thead>
                    <tbody>
                        {faculties.length === 0 ? (
                            <tr>
                                <td colSpan={isAdmin ? 5 : 4} style={{ textAlign: 'center', padding: '3rem', color: '#6b7280' }}>
                                    <School size={40} style={{ margin: '0 auto 8px auto', opacity: 0.3 }} />
                                    <p style={{ margin: 0 }}>No faculties configured yet.</p>
                                </td>
                            </tr>
                        ) : (
                            faculties.map((fac, index) => (
                                <tr key={fac.id}>
                                    <td style={{ textAlign: 'center', fontWeight: 'bold', color: 'var(--text-muted)' }}>{index + 1}</td>
                                    <td>
                                        <span style={{ fontWeight: 'bold', background: '#f3f4f6', padding: '4px 10px', borderRadius: '8px', border: '1px solid #e5e7eb', color: 'var(--primary)' }}>
                                            {fac.code}
                                        </span>
                                    </td>
                                    <td style={{ fontWeight: '600' }}>{fac.name}</td>
                                    <td>
                                        <span style={{
                                            fontSize: '0.75rem',
                                            padding: '2px 8px',
                                            borderRadius: '12px',
                                            fontWeight: 'bold',
                                            background: fac.is_active !== false ? '#dcfce7' : '#fee2e2',
                                            color: fac.is_active !== false ? '#166534' : '#991b1b'
                                        }}>
                                            {fac.is_active !== false ? 'Active' : 'Inactive'}
                                        </span>
                                    </td>
                                    {isAdmin && (
                                        <td style={{ textAlign: 'right' }}>
                                            <button 
                                                style={{ background: 'none', border: 'none', color: 'var(--primary)', cursor: 'pointer', marginRight: '16px' }}
                                                onClick={() => openEditModal(fac)}
                                                title="Edit Faculty"
                                            >
                                                <Edit size={18} />
                                            </button>
                                            <button 
                                                style={{ background: 'none', border: 'none', color: '#dc2626', cursor: 'pointer' }}
                                                onClick={() => handleDeleteFaculty(fac.id, fac.code)}
                                                title="Delete Faculty"
                                            >
                                                <Trash2 size={18} />
                                            </button>
                                        </td>
                                    )}
                                </tr>
                            ))
                        )}
                    </tbody>
                </table>
            </div>

            {/* Modal: Add Faculty */}
            {isAddModalOpen && (
                <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 500 }}>
                    <div className="card" style={{ width: '480px', maxWidth: '95vw', padding: '24px' }}>
                        <h2 style={{ marginTop: 0, marginBottom: '20px', fontSize: '1.25rem', fontWeight: '700' }}>Add New Faculty</h2>
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                            <div>
                                <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: '600', marginBottom: '4px', color: '#4b5563' }}>Faculty Short Code (e.g. FOCS)</label>
                                <input type="text" className="input" value={newCode} onChange={e => setNewCode(e.target.value)} placeholder="e.g. FOCS" style={{ margin: 0 }} />
                            </div>
                            <div>
                                <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: '600', marginBottom: '4px', color: '#4b5563' }}>Full Faculty Name</label>
                                <input type="text" className="input" value={newName} onChange={e => setNewName(e.target.value)} placeholder="e.g. Faculty of Computing and Information Technology" style={{ margin: 0 }} />
                            </div>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                <input type="checkbox" id="add-faculty-active" checked={newActive} onChange={e => setNewActive(e.target.checked)} />
                                <label htmlFor="add-faculty-active" style={{ fontSize: '0.9rem', fontWeight: '600', color: '#4b5563', cursor: 'pointer' }}>Active (Available for Student Profiles)</label>
                            </div>
                        </div>
                        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '24px', borderTop: '1px solid #e5e7eb', paddingTop: '16px' }}>
                            <button className="btn btn-outline" onClick={() => setIsAddModalOpen(false)}>Cancel</button>
                            <button className="btn" onClick={handleAddFaculty} disabled={!newCode || !newName}>Add Faculty</button>
                        </div>
                    </div>
                </div>
            )}

            {/* Modal: Edit Faculty */}
            {isEditModalOpen && (
                <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 500 }}>
                    <div className="card" style={{ width: '480px', maxWidth: '95vw', padding: '24px' }}>
                        <h2 style={{ marginTop: 0, marginBottom: '20px', fontSize: '1.25rem', fontWeight: '700' }}>Edit Faculty</h2>
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                            <div>
                                <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: '600', marginBottom: '4px', color: '#4b5563' }}>Faculty Short Code</label>
                                <input type="text" className="input" value={editCode} onChange={e => setEditCode(e.target.value)} placeholder="e.g. FOCS" style={{ margin: 0 }} />
                            </div>
                            <div>
                                <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: '600', marginBottom: '4px', color: '#4b5563' }}>Full Faculty Name</label>
                                <input type="text" className="input" value={editName} onChange={e => setEditName(e.target.value)} placeholder="e.g. Faculty of Computing and Information Technology" style={{ margin: 0 }} />
                            </div>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                <input type="checkbox" id="edit-faculty-active" checked={editActive} onChange={e => setEditActive(e.target.checked)} />
                                <label htmlFor="edit-faculty-active" style={{ fontSize: '0.9rem', fontWeight: '600', color: '#4b5563', cursor: 'pointer' }}>Active (Available for Student Profiles)</label>
                            </div>
                        </div>
                        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '24px', borderTop: '1px solid #e5e7eb', paddingTop: '16px' }}>
                            <button className="btn btn-outline" onClick={() => setIsEditModalOpen(false)}>Cancel</button>
                            <button className="btn" onClick={handleEditFaculty} disabled={!editCode || !editName}>Save Changes</button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default Faculties;
