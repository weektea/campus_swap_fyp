import React, { useState, useEffect } from 'react';
import { Search, Edit, UserPlus, Trash2 } from 'lucide-react';
import api from '../services/api';

const Users = () => {
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [filterStatus, setFilterStatus] = useState('All');
    
    // Auth context
    const [currentUser, setCurrentUser] = useState(null);

    // Modal state for Edit
    const [selectedUser, setSelectedUser] = useState(null);
    const [isEditModalOpen, setIsEditModalOpen] = useState(false);
    const [editRole, setEditRole] = useState('student');
    const [editIsActive, setEditIsActive] = useState(true);

    // Modal state for Add
    const [isAddModalOpen, setIsAddModalOpen] = useState(false);
    const [newUserForm, setNewUserForm] = useState({
        email: '',
        full_name: '',
        password: '',
        role: 'student'
    });

    useEffect(() => {
        const userStr = localStorage.getItem('user');
        if (userStr) {
            setCurrentUser(JSON.parse(userStr));
        }
        fetchUsers();
    }, []);

    const fetchUsers = async () => {
        setLoading(true);
        try {
            const res = await api.get('/admin/users');
            setUsers(res.data);
        } catch (err) {
            console.error('Failed to fetch users', err);
        } finally {
            setLoading(false);
        }
    };

    const handleManageClick = (user) => {
        setSelectedUser(user);
        setEditRole(user.role);
        setEditIsActive(user.is_active);
        setIsEditModalOpen(true);
    };

    const handleUpdateUser = async () => {
        if (!selectedUser) return;
        try {
            await api.put(`/admin/users/${selectedUser.id}`, {
                role: editRole,
                is_active: editIsActive
            });
            setIsEditModalOpen(false);
            fetchUsers(); // Refresh
        } catch (err) {
            alert(err.response?.data?.error || 'Failed to update user');
        }
    };

    const handleDeleteUser = async () => {
        if (!selectedUser) return;
        if (!window.confirm('Are you sure you want to permanently delete this user?')) return;
        
        try {
            await api.delete(`/admin/users/${selectedUser.id}`);
            setIsEditModalOpen(false);
            fetchUsers();
        } catch (err) {
            alert(err.response?.data?.error || 'Failed to delete user');
        }
    };

    const handleAddUser = async () => {
        if (!newUserForm.email) return alert('Email is required');
        try {
            await api.post('/admin/users', newUserForm);
            setIsAddModalOpen(false);
            setNewUserForm({ email: '', full_name: '', password: '', role: 'student' });
            fetchUsers();
        } catch (err) {
            alert(err.response?.data?.error || 'Failed to create user');
        }
    };

    const filteredUsers = users.filter(u => {
        const matchSearch = (u.full_name || '').toLowerCase().includes(searchTerm.toLowerCase()) || 
                            (u.email || '').toLowerCase().includes(searchTerm.toLowerCase());
        const matchStatus = filterStatus === 'All' ? true : 
                            (filterStatus === 'Active' ? u.is_active : !u.is_active);
        return matchSearch && matchStatus;
    });

    if (loading) return <div className="p-8 text-center text-gray-500">Loading users...</div>;

    return (
        <div>
            <div className="flex justify-between items-center mb-8">
                <h1 style={{ fontSize: '1.5rem', margin: 0 }}>User Directory</h1>
                <div className="flex gap-4 items-center">
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
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            style={{ border: 'none', background: 'transparent', outline: 'none', width: '100%' }}
                        />
                    </div>
                    <select 
                        className="input" 
                        style={{ width: '150px', marginBottom: 0 }}
                        value={filterStatus}
                        onChange={(e) => setFilterStatus(e.target.value)}
                    >
                        <option value="All">All Status</option>
                        <option value="Active">Active</option>
                        <option value="Banned">Banned</option>
                    </select>
                    {currentUser?.role === 'admin' && (
                        <button 
                            className="btn flex items-center gap-2" 
                            onClick={() => setIsAddModalOpen(true)}
                        >
                            <UserPlus size={18} /> Add User
                        </button>
                    )}
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
                            <th>STATUS</th>
                            <th>ACTIONS</th>
                        </tr>
                    </thead>
                    <tbody>
                        {filteredUsers.map(user => (
                            <tr key={user.id}>
                                <td style={{ color: 'var(--text-muted)' }}>{user.id.substring(0,8)}</td>
                                <td>
                                    <div>{user.full_name || 'No Name'}</div>
                                    <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{user.email}</div>
                                </td>
                                <td>
                                    <span style={{ 
                                        padding: '4px 8px', 
                                        background: user.role === 'admin' ? '#fee2e2' : user.role === 'moderator' ? '#e0e7ff' : '#f3f4f6', 
                                        borderRadius: '4px', 
                                        color: user.role === 'admin' ? '#991b1b' : user.role === 'moderator' ? '#3730a3' : '#374151', 
                                        fontSize: '0.75rem', 
                                        fontWeight: 'bold',
                                        textTransform: 'capitalize'
                                    }}>
                                        {user.role}
                                    </span>
                                </td>
                                <td style={{ color: 'var(--primary)', fontWeight: 'bold' }}>{user.eco_score || 0}</td>
                                <td>
                                    {user.is_active ? (
                                        <span style={{ padding: '4px 12px', background: '#dcfce7', borderRadius: '12px', color: '#16a34a', fontSize: '0.75rem', fontWeight: 'bold' }}>
                                            Active
                                        </span>
                                    ) : (
                                        <span style={{ padding: '4px 12px', background: '#fee2e2', borderRadius: '12px', color: '#dc2626', fontSize: '0.75rem', fontWeight: 'bold' }}>
                                            Banned
                                        </span>
                                    )}
                                </td>
                                <td>
                                    <button 
                                        onClick={() => handleManageClick(user)}
                                        style={{ background: 'none', border: 'none', color: 'var(--primary)', fontWeight: 'bold', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '4px' }}
                                    >
                                        <Edit size={14} /> Manage
                                    </button>
                                </td>
                            </tr>
                        ))}
                        {filteredUsers.length === 0 && (
                            <tr>
                                <td colSpan="6" style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>No users found.</td>
                            </tr>
                        )}
                    </tbody>
                </table>
            </div>

            {/* Edit Modal */}
            {isEditModalOpen && selectedUser && (
                <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 50 }}>
                    <div className="card" style={{ width: '400px', background: 'white' }}>
                        <h2 style={{ marginTop: 0 }}>Manage User</h2>
                        <div style={{ marginBottom: '16px' }}>
                            <strong>{selectedUser.email}</strong>
                        </div>
                        
                        {currentUser?.role === 'admin' ? (
                            <>
                                <div style={{ marginBottom: '16px' }}>
                                    <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-muted)' }}>Role</label>
                                    <select 
                                        className="input" 
                                        value={editRole} 
                                        onChange={(e) => setEditRole(e.target.value)}
                                        style={{ width: '100%' }}
                                        disabled={selectedUser.role === 'admin' && currentUser.id !== selectedUser.id}
                                    >
                                        <option value="student">Student</option>
                                        <option value="moderator">Moderator</option>
                                        <option value="admin">Admin</option>
                                    </select>
                                </div>
                                <div style={{ marginBottom: '24px' }}>
                                    <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-muted)' }}>Account Status</label>
                                    <select 
                                        className="input" 
                                        value={editIsActive ? 'active' : 'banned'} 
                                        onChange={(e) => setEditIsActive(e.target.value === 'active')}
                                        style={{ width: '100%' }}
                                        disabled={selectedUser.role === 'admin' && currentUser.id !== selectedUser.id}
                                    >
                                        <option value="active">Active</option>
                                        <option value="banned">Banned / Suspended</option>
                                    </select>
                                </div>
                            </>
                        ) : (
                            <div style={{ padding: '16px', background: '#fef3c7', color: '#92400e', borderRadius: '8px', marginBottom: '16px' }}>
                                Moderators cannot change user roles or status. Please contact an Administrator.
                            </div>
                        )}

                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                            {currentUser?.role === 'admin' && selectedUser.role !== 'admin' ? (
                                <button className="btn" style={{ background: '#fef2f2', color: '#dc2626', border: '1px solid #fca5a5' }} onClick={handleDeleteUser}>
                                    <Trash2 size={16} /> Delete
                                </button>
                            ) : <div></div>}

                            <div style={{ display: 'flex', gap: '12px' }}>
                                <button className="btn" style={{ background: '#e5e7eb', color: '#374151' }} onClick={() => setIsEditModalOpen(false)}>Cancel</button>
                                {currentUser?.role === 'admin' && (
                                    <button className="btn" style={{ background: 'var(--primary)' }} onClick={handleUpdateUser}>Save Changes</button>
                                )}
                            </div>
                        </div>
                    </div>
                </div>
            )}

            {/* Add User Modal */}
            {isAddModalOpen && (
                <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 50 }}>
                    <div className="card" style={{ width: '400px', background: 'white' }}>
                        <h2 style={{ marginTop: 0 }}>Add New User</h2>
                        
                        <div style={{ marginBottom: '16px' }}>
                            <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-muted)' }}>Email</label>
                            <input 
                                type="email"
                                className="input" 
                                value={newUserForm.email}
                                onChange={(e) => setNewUserForm({...newUserForm, email: e.target.value})}
                                style={{ width: '100%' }}
                                placeholder="Email address"
                            />
                        </div>

                        <div style={{ marginBottom: '16px' }}>
                            <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-muted)' }}>Full Name</label>
                            <input 
                                type="text"
                                className="input" 
                                value={newUserForm.full_name}
                                onChange={(e) => setNewUserForm({...newUserForm, full_name: e.target.value})}
                                style={{ width: '100%' }}
                                placeholder="Full Name"
                            />
                        </div>

                        <div style={{ marginBottom: '16px' }}>
                            <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-muted)' }}>Temporary Password</label>
                            <input 
                                type="password"
                                className="input" 
                                value={newUserForm.password}
                                onChange={(e) => setNewUserForm({...newUserForm, password: e.target.value})}
                                style={{ width: '100%' }}
                                placeholder="Defaults to password123"
                            />
                        </div>
                        
                        <div style={{ marginBottom: '24px' }}>
                            <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-muted)' }}>Role</label>
                            <select 
                                className="input" 
                                value={newUserForm.role}
                                onChange={(e) => setNewUserForm({...newUserForm, role: e.target.value})}
                                style={{ width: '100%' }}
                            >
                                <option value="student">Student</option>
                                <option value="moderator">Moderator</option>
                                <option value="admin">Admin</option>
                            </select>
                        </div>

                        <div style={{ display: 'flex', gap: '12px', justifyContent: 'flex-end' }}>
                            <button className="btn" style={{ background: '#e5e7eb', color: '#374151' }} onClick={() => setIsAddModalOpen(false)}>Cancel</button>
                            <button className="btn" style={{ background: 'var(--primary)' }} onClick={handleAddUser}>Create User</button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default Users;
