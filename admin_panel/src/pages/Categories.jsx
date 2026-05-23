import React, { useState, useEffect } from 'react';
import { Plus, Trash2, ChevronDown, ChevronRight, MapPin } from 'lucide-react';
import api from '../services/api';

const Categories = () => {
    const [categories, setCategories] = useState([]);
    const [zones, setZones] = useState([]);
    const [loading, setLoading] = useState(true);
    const [currentUser, setCurrentUser] = useState(null);
    const [expandedCats, setExpandedCats] = useState({});

    // Modals
    const [isAddCatModalOpen, setIsAddCatModalOpen] = useState(false);
    const [isAddSubModalOpen, setIsAddSubModalOpen] = useState(false);
    const [isAddZoneModalOpen, setIsAddZoneModalOpen] = useState(false);

    // Form States
    const [newCatName, setNewCatName] = useState('');
    const [newCatCarbon, setNewCatCarbon] = useState('');
    
    const [selectedParentId, setSelectedParentId] = useState(null);
    const [newSubName, setNewSubName] = useState('');
    const [newSubCarbon, setNewSubCarbon] = useState('');

    const [newZoneName, setNewZoneName] = useState('');
    const [newZoneDesc, setNewZoneDesc] = useState('');
    const [newZoneLat, setNewZoneLat] = useState('');
    const [newZoneLng, setNewZoneLng] = useState('');

    useEffect(() => {
        const userStr = localStorage.getItem('user');
        if (userStr) setCurrentUser(JSON.parse(userStr));
        fetchData();
    }, []);

    const fetchData = async () => {
        setLoading(true);
        try {
            const [catRes, zoneRes] = await Promise.all([
                api.get('/admin/categories'),
                api.get('/admin/zones')
            ]);
            setCategories(catRes.data);
            setZones(zoneRes.data);
        } catch (err) {
            console.error(err);
        } finally {
            setLoading(false);
        }
    };

    const toggleExpand = (id) => {
        setExpandedCats(prev => ({ ...prev, [id]: !prev[id] }));
    };

    // Category Handlers
    const handleAddCategory = async () => {
        try {
            await api.post('/admin/categories', {
                name: newCatName,
                carbon_conversion_factor: parseFloat(newCatCarbon) || 0.0
            });
            setIsAddCatModalOpen(false);
            setNewCatName('');
            setNewCatCarbon('');
            fetchData();
        } catch (err) {
            alert(err.response?.data?.error || 'Failed to add category');
        }
    };

    const handleDeleteCategory = async (id, name) => {
        const confirmName = prompt(`WARNING: Type "${name}" to delete this category.`);
        if (confirmName !== name) return;
        try {
            await api.delete(`/admin/categories/${id}`);
            fetchData();
        } catch (err) {
            alert(err.response?.data?.error || 'Failed to delete category');
        }
    };

    // SubCategory Handlers
    const openAddSubModal = (catId) => {
        setSelectedParentId(catId);
        setIsAddSubModalOpen(true);
    };

    const handleAddSubCategory = async () => {
        try {
            await api.post('/admin/subcategories', {
                category_id: selectedParentId,
                name: newSubName,
                carbon_conversion_factor: parseFloat(newSubCarbon) || 0.0
            });
            setIsAddSubModalOpen(false);
            setNewSubName('');
            setNewSubCarbon('');
            setExpandedCats(prev => ({ ...prev, [selectedParentId]: true }));
            fetchData();
        } catch (err) {
            alert(err.response?.data?.error || 'Failed to add subcategory');
        }
    };

    const handleDeleteSubCategory = async (id, name) => {
        if (!window.confirm(`Are you sure you want to delete subcategory "${name}"?`)) return;
        try {
            await api.delete(`/admin/subcategories/${id}`);
            fetchData();
        } catch (err) {
            alert(err.response?.data?.error || 'Failed to delete subcategory');
        }
    };

    // Zone Handlers
    const handleAddZone = async () => {
        try {
            await api.post('/admin/zones', {
                name: newZoneName,
                description: newZoneDesc,
                latitude: newZoneLat,
                longitude: newZoneLng,
                is_active: true
            });
            setIsAddZoneModalOpen(false);
            setNewZoneName('');
            setNewZoneDesc('');
            setNewZoneLat('');
            setNewZoneLng('');
            fetchData();
        } catch (err) {
            alert(err.response?.data?.error || 'Failed to add zone');
        }
    };

    const handleDeleteZone = async (id) => {
        if (!window.confirm('Delete this safe zone?')) return;
        try {
            await api.delete(`/admin/zones/${id}`);
            fetchData();
        } catch (err) {
            alert('Failed to delete zone');
        }
    };

    if (loading) return <div className="p-8 text-center text-gray-500">Loading data...</div>;

    const isAdmin = currentUser?.role === 'admin';

    return (
        <div>
            <div className="flex justify-between items-center mb-8">
                <h1 style={{ fontSize: '1.5rem', margin: 0 }}>Categories & Safe Zones</h1>
            </div>

            <div style={{ display: 'flex', gap: '2rem' }}>
                {/* Categories & Subcategories */}
                <div style={{ flex: 2 }}>
                    <div className="flex justify-between items-center mb-4">
                        <h2 style={{ margin: 0, fontSize: '1.25rem' }}>Product Categories</h2>
                        {isAdmin && (
                            <button className="btn" onClick={() => setIsAddCatModalOpen(true)}>
                                <Plus size={18} style={{ marginRight: '4px' }} /> Add Category
                            </button>
                        )}
                    </div>
                    
                    <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
                        <table style={{ margin: 0 }}>
                            <thead>
                                <tr>
                                    <th style={{ width: '40%' }}>NAME</th>
                                    <th>CARBON OFFSET (Fallback)</th>
                                    {isAdmin && <th style={{ textAlign: 'right' }}>ACTIONS</th>}
                                </tr>
                            </thead>
                            <tbody>
                                {categories.map(cat => (
                                    <React.Fragment key={cat.id}>
                                        {/* Main Category Row */}
                                        <tr style={{ background: '#f9fafb', cursor: 'pointer' }} onClick={() => toggleExpand(cat.id)}>
                                            <td style={{ fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '8px' }}>
                                                {expandedCats[cat.id] ? <ChevronDown size={18} color="#6b7280"/> : <ChevronRight size={18} color="#6b7280"/>}
                                                {cat.name}
                                                <span style={{ fontSize: '0.75rem', background: '#e5e7eb', padding: '2px 8px', borderRadius: '12px', fontWeight: 'normal', color: '#4b5563' }}>
                                                    {cat.subcategories?.length || 0} sub
                                                </span>
                                            </td>
                                            <td>{cat.carbon_conversion_factor} kg / item</td>
                                            {isAdmin && (
                                                <td style={{ textAlign: 'right' }}>
                                                    <button 
                                                        style={{ background: 'none', border: 'none', color: 'var(--primary)', cursor: 'pointer', marginRight: '16px', fontWeight: 'bold' }}
                                                        onClick={(e) => { e.stopPropagation(); openAddSubModal(cat.id); }}
                                                    >
                                                        + SubCategory
                                                    </button>
                                                    <button 
                                                        style={{ background: 'none', border: 'none', color: '#dc2626', cursor: 'pointer' }}
                                                        onClick={(e) => { e.stopPropagation(); handleDeleteCategory(cat.id, cat.name); }}
                                                    >
                                                        <Trash2 size={18} />
                                                    </button>
                                                </td>
                                            )}
                                        </tr>
                                        {/* SubCategories Rows */}
                                        {expandedCats[cat.id] && cat.subcategories?.map(sub => (
                                            <tr key={sub.id}>
                                                <td style={{ paddingLeft: '2.5rem' }}>
                                                    <div style={{ position: 'relative' }}>
                                                        <div style={{ position: 'absolute', left: '-15px', top: '50%', width: '10px', height: '1px', background: '#d1d5db' }}></div>
                                                        <div style={{ position: 'absolute', left: '-15px', top: '-15px', width: '1px', height: '100%', background: '#d1d5db' }}></div>
                                                        {sub.name}
                                                    </div>
                                                </td>
                                                <td style={{ color: '#16a34a', fontWeight: 'bold' }}>{sub.carbon_conversion_factor} kg</td>
                                                {isAdmin && (
                                                    <td style={{ textAlign: 'right' }}>
                                                        <button 
                                                            style={{ background: 'none', border: 'none', color: '#dc2626', cursor: 'pointer' }}
                                                            onClick={() => handleDeleteSubCategory(sub.id, sub.name)}
                                                        >
                                                            <Trash2 size={16} />
                                                        </button>
                                                    </td>
                                                )}
                                            </tr>
                                        ))}
                                        {expandedCats[cat.id] && (!cat.subcategories || cat.subcategories.length === 0) && (
                                            <tr>
                                                <td colSpan="3" style={{ paddingLeft: '2.5rem', color: '#9ca3af', fontStyle: 'italic' }}>
                                                    No subcategories yet.
                                                </td>
                                            </tr>
                                        )}
                                    </React.Fragment>
                                ))}
                                {categories.length === 0 && <tr><td colSpan="3" style={{ textAlign: 'center', padding: '1rem' }}>No categories.</td></tr>}
                            </tbody>
                        </table>
                    </div>
                </div>

                {/* Safe Zones */}
                <div style={{ flex: 1 }}>
                    <div className="flex justify-between items-center mb-4">
                        <h2 style={{ margin: 0, fontSize: '1.25rem' }}>Safe Meetup Zones</h2>
                        {isAdmin && (
                            <button className="btn" style={{ padding: '0.5rem 1rem' }} onClick={() => setIsAddZoneModalOpen(true)}>
                                <Plus size={16} />
                            </button>
                        )}
                    </div>
                    <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
                        <table style={{ margin: 0 }}>
                            <thead>
                                <tr>
                                    <th>LOCATION DETAILS</th>
                                    {isAdmin && <th style={{ textAlign: 'right' }}>ACTIONS</th>}
                                </tr>
                            </thead>
                            <tbody>
                                {zones.map(zone => (
                                    <tr key={zone.id}>
                                        <td>
                                            <div style={{ fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '4px' }}>
                                                <MapPin size={14} color="var(--primary)"/> {zone.name}
                                            </div>
                                            <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: '4px' }}>{zone.description}</div>
                                            <div style={{ fontSize: '0.7rem', color: '#9ca3af', marginTop: '2px', fontFamily: 'monospace' }}>
                                                {zone.latitude}, {zone.longitude}
                                            </div>
                                        </td>
                                        {isAdmin && (
                                            <td style={{ textAlign: 'right' }}>
                                                <button 
                                                    style={{ background: 'none', border: 'none', color: '#dc2626', cursor: 'pointer' }}
                                                    onClick={() => handleDeleteZone(zone.id)}
                                                >
                                                    <Trash2 size={18} />
                                                </button>
                                            </td>
                                        )}
                                    </tr>
                                ))}
                                {zones.length === 0 && <tr><td colSpan="2" style={{ textAlign: 'center', padding: '1rem' }}>No zones configured.</td></tr>}
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

            {/* Modals */}
            {isAddCatModalOpen && (
                <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 50 }}>
                    <div className="card" style={{ width: '400px' }}>
                        <h2 style={{ marginTop: 0 }}>Add Category</h2>
                        <input type="text" className="input" value={newCatName} onChange={e => setNewCatName(e.target.value)} placeholder="Category Name" />
                        <input type="number" className="input" value={newCatCarbon} onChange={e => setNewCatCarbon(e.target.value)} placeholder="Fallback Carbon Offset (kg)" />
                        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
                            <button className="btn btn-outline" onClick={() => setIsAddCatModalOpen(false)}>Cancel</button>
                            <button className="btn" onClick={handleAddCategory}>Add Category</button>
                        </div>
                    </div>
                </div>
            )}

            {isAddSubModalOpen && (
                <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 50 }}>
                    <div className="card" style={{ width: '400px' }}>
                        <h2 style={{ marginTop: 0 }}>Add SubCategory</h2>
                        <input type="text" className="input" value={newSubName} onChange={e => setNewSubName(e.target.value)} placeholder="SubCategory Name (e.g. T-Shirts)" />
                        <input type="number" className="input" value={newSubCarbon} onChange={e => setNewSubCarbon(e.target.value)} placeholder="Carbon Offset Factor (kg) - e.g. 2.5" />
                        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
                            <button className="btn btn-outline" onClick={() => setIsAddSubModalOpen(false)}>Cancel</button>
                            <button className="btn" onClick={handleAddSubCategory}>Add SubCategory</button>
                        </div>
                    </div>
                </div>
            )}

            {isAddZoneModalOpen && (
                <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 50 }}>
                    <div className="card" style={{ width: '400px' }}>
                        <h2 style={{ marginTop: 0 }}>Add Safe Meetup Zone</h2>
                        <input type="text" className="input" value={newZoneName} onChange={e => setNewZoneName(e.target.value)} placeholder="Zone Name (e.g. Main Library)" />
                        <textarea className="input" style={{ resize: 'none', height: '60px' }} value={newZoneDesc} onChange={e => setNewZoneDesc(e.target.value)} placeholder="Description or Instructions..." />
                        <div style={{ display: 'flex', gap: '12px' }}>
                            <input type="number" className="input" value={newZoneLat} onChange={e => setNewZoneLat(e.target.value)} placeholder="Latitude (e.g. 3.123)" />
                            <input type="number" className="input" value={newZoneLng} onChange={e => setNewZoneLng(e.target.value)} placeholder="Longitude (e.g. 101.54)" />
                        </div>
                        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
                            <button className="btn btn-outline" onClick={() => setIsAddZoneModalOpen(false)}>Cancel</button>
                            <button className="btn" onClick={handleAddZone}>Create Zone</button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default Categories;
