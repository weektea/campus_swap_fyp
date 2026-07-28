import React, { useState, useEffect } from 'react';
import { useParams, useNavigate, useLocation } from 'react-router-dom';
import { ArrowLeft, Edit, Trash2, Box, Info, UserX } from 'lucide-react';
import api from '../services/api';

const UserDetail = () => {
    const { id } = useParams();
    const navigate = useNavigate();
    const location = useLocation();
    const fromReportId = location.state?.fromReportId;

    const [user, setUser] = useState(null);
    const [activeListings, setActiveListings] = useState([]);
    const [loading, setLoading] = useState(true);
    
    // Auth context
    const [currentUser, setCurrentUser] = useState(null);
    
    // Edit state
    const [editRole, setEditRole] = useState('student');
    const [editIsActive, setEditIsActive] = useState(true);

    useEffect(() => {
        const userStr = localStorage.getItem('user');
        if (userStr) {
            setCurrentUser(JSON.parse(userStr));
        }
        fetchUserDetails();
    }, [id]);

    const fetchUserDetails = async () => {
        setLoading(true);
        try {
            const res = await api.get(`/admin/users/${id}`);
            setUser(res.data.user);
            setActiveListings(res.data.activeListings || []);
            setEditRole(res.data.user.role);
            setEditIsActive(res.data.user.is_active);
        } catch (err) {
            console.error('Failed to fetch user details', err);
            alert('Error loading user data');
        } finally {
            setLoading(false);
        }
    };

    const handleUpdateUser = async () => {
        try {
            await api.put(`/admin/users/${user.id}`, {
                role: editRole,
                is_active: editIsActive
            });
            alert('User updated successfully');
            fetchUserDetails();
        } catch (err) {
            alert(err.response?.data?.error || 'Failed to update user');
        }
    };

    const handleDeleteUser = async () => {
        if (!window.confirm('Are you sure you want to deactivate this user account?')) return;
        
        try {
            await api.delete(`/admin/users/${user.id}`);
            navigate('/users');
        } catch (err) {
            alert(err.response?.data?.error || 'Failed to deactivate user');
        }
    };

    if (loading) return <div className="p-8 text-center text-gray-500">Loading user details...</div>;
    if (!user) return <div className="p-8 text-center text-red-500">User not found.</div>;

    const isAdmin = currentUser?.role === 'admin';
    const canEdit = isAdmin && (user.role !== 'admin' || currentUser.id === user.id);

    return (
        <div>
            {fromReportId && (
                <div style={{ background: '#eff6ff', border: '1px solid #bfdbfe', borderRadius: '12px', padding: '12px 16px', marginBottom: '1.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <div style={{ color: '#1e40af', fontWeight: 'bold', fontSize: '0.9rem' }}>
                        🛡️ Inspecting student profile from Report Ticket REP-{fromReportId}
                    </div>
                    <button 
                        className="btn" 
                        style={{ background: '#2563eb', color: 'white', border: 'none', padding: '6px 14px', fontSize: '0.85rem', display: 'flex', alignItems: 'center', gap: '6px' }}
                        onClick={() => navigate('/reports', { state: { selectedId: fromReportId } })}
                    >
                        <ArrowLeft size={16} /> Return to Report Ticket
                    </button>
                </div>
            )}

            <div className="flex items-center gap-4 mb-8">
                <button onClick={() => fromReportId ? navigate('/reports', { state: { selectedId: fromReportId } }) : navigate('/users')} className="btn" style={{ background: '#f3f4f6', color: '#374151', padding: '8px' }}>
                    <ArrowLeft size={20} />
                </button>
                <h1 style={{ fontSize: '1.5rem', margin: 0 }}>User Profile Details</h1>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                {/* Left Column: Info */}
                <div className="card">
                    <h2 style={{ marginTop: 0, display: 'flex', alignItems: 'center', gap: '8px' }}><Info size={20} /> User Information</h2>
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 2fr', gap: '16px', marginTop: '24px' }}>
                        <div style={{ color: 'var(--text-muted)', fontWeight: 'bold' }}>ID</div>
                        <div>{user.id}</div>
                        
                        <div style={{ color: 'var(--text-muted)', fontWeight: 'bold' }}>Full Name</div>
                        <div>{user.full_name || 'N/A'}</div>

                        <div style={{ color: 'var(--text-muted)', fontWeight: 'bold' }}>Email</div>
                        <div>{user.email}</div>

                        <div style={{ color: 'var(--text-muted)', fontWeight: 'bold' }}>Student ID</div>
                        <div>{user.university_id || 'N/A'}</div>

                        <div style={{ color: 'var(--text-muted)', fontWeight: 'bold' }}>Phone</div>
                        <div>{user.phone_number || 'N/A'}</div>

                        <div style={{ color: 'var(--text-muted)', fontWeight: 'bold' }}>Faculty</div>
                        <div>{user.faculty || 'N/A'}</div>

                        <div style={{ color: 'var(--text-muted)', fontWeight: 'bold' }}>Year of Study</div>
                        <div>{user.year_of_study || 'N/A'}</div>

                        <div style={{ color: 'var(--text-muted)', fontWeight: 'bold' }}>Bio</div>
                        <div>{user.bio || 'N/A'}</div>

                        <div style={{ color: 'var(--text-muted)', fontWeight: 'bold' }}>Reputation</div>
                        <div>{user.reputation_score} / 5.0 ({user.total_reviews} reviews)</div>

                        <div style={{ color: 'var(--text-muted)', fontWeight: 'bold' }}>Verification</div>
                        <div>
                            {user.is_verified ? (
                                <span style={{ padding: '4px 8px', background: '#dcfce7', borderRadius: '8px', color: '#16a34a', fontSize: '0.75rem', fontWeight: 'bold' }}>
                                    Verified Student
                                </span>
                            ) : (
                                <span style={{ padding: '4px 8px', background: '#f3f4f6', borderRadius: '8px', color: '#6b7280', fontSize: '0.75rem', fontWeight: 'bold' }}>
                                    Unverified
                                </span>
                            )}
                        </div>

                        <div style={{ color: 'var(--text-muted)', fontWeight: 'bold' }}>Flagged / Suspicious</div>
                        <div>
                            {user.is_flagged ? (
                                <span style={{ padding: '4px 8px', background: '#fee2e2', borderRadius: '8px', color: '#dc2626', fontSize: '0.75rem', fontWeight: 'bold' }}>
                                    ⚠️ Flagged: {user.flag_reason || 'Suspicious Activity'}
                                </span>
                            ) : (
                                <span style={{ padding: '4px 8px', background: '#f3f4f6', borderRadius: '8px', color: '#6b7280', fontSize: '0.75rem', fontWeight: 'bold' }}>
                                    Clear / Not Flagged
                                </span>
                            )}
                        </div>

                        <div style={{ color: 'var(--text-muted)', fontWeight: 'bold' }}>Warning Count</div>
                        <div>{user.warning_count || 0} / 3 (suspended at 3)</div>

                        <div style={{ color: 'var(--text-muted)', fontWeight: 'bold' }}>Carbon Saved</div>
                        <div>{user.total_carbon_saved} kg CO2e</div>

                        <div style={{ color: 'var(--text-muted)', fontWeight: 'bold' }}>Followers</div>
                        <div>{user.follower_count || 0}</div>

                        <div style={{ color: 'var(--text-muted)', fontWeight: 'bold' }}>Following</div>
                        <div>{user.following_count || 0}</div>
                    </div>
                </div>

                {/* Right Column: Actions & Listings */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
                    <div className="card">
                        <h2 style={{ marginTop: 0, display: 'flex', alignItems: 'center', gap: '8px' }}><Edit size={20} /> Administration</h2>
                        
                        {isAdmin ? (
                            <div style={{ marginTop: '24px' }}>
                                <div style={{ marginBottom: '16px' }}>
                                    <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-muted)' }}>Role</label>
                                    <select 
                                        className="input" 
                                        value={editRole} 
                                        onChange={(e) => setEditRole(e.target.value)}
                                        style={{ width: '100%' }}
                                        disabled={!canEdit}
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
                                        disabled={!canEdit}
                                    >
                                        <option value="active">Active</option>
                                        <option value="banned">Banned / Suspended</option>
                                    </select>
                                </div>
                                
                                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                                    {isAdmin && user.role !== 'admin' ? (
                                        <button className="btn" style={{ background: '#fef2f2', color: '#dc2626', border: '1px solid #fca5a5', display: 'flex', alignItems: 'center', gap: '8px' }} onClick={handleDeleteUser}>
                                            <UserX size={16} /> Deactivate User
                                        </button>
                                    ) : <div></div>}
                                    <button className="btn" style={{ background: 'var(--primary)' }} onClick={handleUpdateUser} disabled={!canEdit}>
                                        Save Changes
                                    </button>
                                </div>
                            </div>
                        ) : (
                            <div style={{ padding: '16px', background: '#fef3c7', color: '#92400e', borderRadius: '8px', marginTop: '16px' }}>
                                Moderators cannot change user roles or status. Please contact an Administrator.
                            </div>
                        )}

                        <div style={{ 
                            padding: '16px', 
                            background: '#f8fafc', 
                            border: '1px solid #e2e8f0', 
                            borderRadius: '12px', 
                            marginTop: '24px' 
                        }}>
                            <span style={{ display: 'block', color: 'var(--primary)', fontWeight: 'bold', fontSize: '0.85rem', marginBottom: '12px' }}>
                                Verification, Flagging & Warnings
                            </span>
                            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                                <button 
                                    className="btn" 
                                    style={{ 
                                        background: user.is_verified ? '#f1f5f9' : '#dcfce7', 
                                        color: user.is_verified ? '#475569' : '#16a34a',
                                        border: '1px solid ' + (user.is_verified ? '#cbd5e1' : '#bbf7d0'),
                                        padding: '8px 12px',
                                        fontWeight: 'bold',
                                        justifyContent: 'center',
                                        display: 'flex'
                                    }}
                                    onClick={async () => {
                                        try {
                                            const res = await api.patch(`/admin/users/${user.id}/verify`);
                                            alert(res.data.message);
                                            fetchUserDetails();
                                        } catch (err) {
                                            alert(err.response?.data?.error || 'Verification failed');
                                        }
                                    }}
                                >
                                    {user.is_verified ? 'Revoke Verification Status' : 'Approve / Verify Student Credential'}
                                </button>
                                <button 
                                    className="btn" 
                                    style={{ 
                                        background: user.is_flagged ? '#f1f5f9' : '#fee2e2', 
                                        color: user.is_flagged ? '#475569' : '#dc2626',
                                        border: '1px solid ' + (user.is_flagged ? '#cbd5e1' : '#fecaca'),
                                        padding: '8px 12px',
                                        fontWeight: 'bold',
                                        justifyContent: 'center',
                                        display: 'flex'
                                    }}
                                    onClick={async () => {
                                        const reason = user.is_flagged ? null : window.prompt('Enter flag reason:', 'Suspicious Behavior');
                                        if (!user.is_flagged && reason === null) return;
                                        try {
                                            const res = await api.patch(`/admin/users/${user.id}/flag`, {
                                                is_flagged: !user.is_flagged,
                                                reason: reason
                                             });
                                             alert(res.data.message);
                                             fetchUserDetails();
                                        } catch (err) {
                                             alert(err.response?.data?.error || 'Flagging failed');
                                        }
                                    }}
                                >
                                    {user.is_flagged ? 'Unflag User / Dismiss Flag' : 'Flag User as Suspicious'}
                                </button>
                                <button 
                                    className="btn" 
                                    style={{ 
                                        background: '#fef3c7', 
                                        color: '#d97706',
                                        border: '1px solid #fde68a',
                                        padding: '8px 12px',
                                        fontWeight: 'bold',
                                        justifyContent: 'center',
                                        display: 'flex'
                                    }}
                                    onClick={async () => {
                                        if (!window.confirm('Send a formal warning to this user? Accumulating 3 warnings results in automatic suspension.')) return;
                                        try {
                                            const res = await api.post(`/admin/users/${user.id}/warn`);
                                             alert(res.data.message + (res.data.isSuspended ? ' (User suspended!)' : ''));
                                             fetchUserDetails();
                                        } catch (err) {
                                             alert(err.response?.data?.error || 'Warning failed');
                                        }
                                    }}
                                >
                                    Send Warning to Student ({user.warning_count || 0} warning(s))
                                </button>
                            </div>
                        </div>
                    </div>

                    <div className="card">
                        <h2 style={{ marginTop: 0, display: 'flex', alignItems: 'center', gap: '8px' }}><Box size={20} /> Active Listings ({activeListings.length})</h2>
                        {activeListings.length > 0 ? (
                            <ul style={{ listStyle: 'none', padding: 0, marginTop: '16px' }}>
                                {activeListings.map(listing => (
                                    <li key={listing.id} style={{ padding: '12px', borderBottom: '1px solid var(--border)', display: 'flex', justifyContent: 'space-between' }}>
                                        <div>
                                            <div style={{ fontWeight: 'bold' }}>{listing.title}</div>
                                            <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Posted: {new Date(listing.createdAt).toLocaleDateString()}</div>
                                        </div>
                                        <div style={{ color: 'var(--primary)', fontWeight: 'bold' }}>RM {listing.price}</div>
                                    </li>
                                ))}
                            </ul>
                        ) : (
                            <div style={{ padding: '16px', textAlign: 'center', color: 'var(--text-muted)' }}>
                                No active listings.
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
};

export default UserDetail;
