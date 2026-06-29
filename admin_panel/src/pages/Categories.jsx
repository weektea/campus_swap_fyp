import React, { useState, useEffect, useRef } from 'react';
import { Plus, Trash2, ChevronDown, ChevronRight, MapPin, Edit } from 'lucide-react';
import api from '../services/api';

const loadLeaflet = () => {
    return new Promise((resolve, reject) => {
        if (window.L) {
            resolve(window.L);
            return;
        }

        // Add CSS link
        if (!document.getElementById('leaflet-css')) {
            const link = document.createElement('link');
            link.rel = 'stylesheet';
            link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
            link.id = 'leaflet-css';
            document.head.appendChild(link);
        }

        // Add JS script
        if (!document.getElementById('leaflet-js')) {
            const script = document.createElement('script');
            script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
            script.id = 'leaflet-js';
            script.onload = () => {
                resolve(window.L);
            };
            script.onerror = (err) => {
                reject(err);
            };
            document.body.appendChild(script);
        } else {
            const interval = setInterval(() => {
                if (window.L) {
                    clearInterval(interval);
                    resolve(window.L);
                }
            }, 50);
        }
    });
};

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
    const [newCatIcon, setNewCatIcon] = useState('box-icon');
    
    const [selectedParentId, setSelectedParentId] = useState(null);
    const [newSubName, setNewSubName] = useState('');
    const [newSubCarbon, setNewSubCarbon] = useState('');

    const [newZoneName, setNewZoneName] = useState('');
    const [newZoneDesc, setNewZoneDesc] = useState('');
    const [newZoneLat, setNewZoneLat] = useState('');
    const [newZoneLng, setNewZoneLng] = useState('');
    const [newZoneActive, setNewZoneActive] = useState(true);

    const [isEditCatModalOpen, setIsEditCatModalOpen] = useState(false);
    const [editCatId, setEditCatId] = useState(null);
    const [editCatName, setEditCatName] = useState('');
    const [editCatIcon, setEditCatIcon] = useState('');
    const [editCatCarbon, setEditCatCarbon] = useState('');

    const [isEditSubModalOpen, setIsEditSubModalOpen] = useState(false);
    const [editSubId, setEditSubId] = useState(null);
    const [editSubName, setEditSubName] = useState('');
    const [editSubCarbon, setEditSubCarbon] = useState('');

    const [isEditZoneModalOpen, setIsEditZoneModalOpen] = useState(false);
    const [editZoneId, setEditZoneId] = useState(null);
    const [editZoneName, setEditZoneName] = useState('');
    const [editZoneDesc, setEditZoneDesc] = useState('');
    const [editZoneLat, setEditZoneLat] = useState('');
    const [editZoneLng, setEditZoneLng] = useState('');
    const [editZoneActive, setEditZoneActive] = useState(true);

    const mapInstanceRef = useRef(null);
    const markerInstanceRef = useRef(null);
    const editMapInstanceRef = useRef(null);
    const editMarkerInstanceRef = useRef(null);

    useEffect(() => {
        const userStr = localStorage.getItem('user');
        if (userStr) setCurrentUser(JSON.parse(userStr));
        fetchData();
    }, []);

    // Load Leaflet and initialize map when modal opens
    useEffect(() => {
        if (!isAddZoneModalOpen) {
            if (mapInstanceRef.current) {
                mapInstanceRef.current.remove();
                mapInstanceRef.current = null;
                markerInstanceRef.current = null;
            }
            return;
        }

        let isMounted = true;
        let mapTimeout = null;

        loadLeaflet().then((L) => {
            if (!isMounted || !isAddZoneModalOpen) return;

            mapTimeout = setTimeout(() => {
                const mapEl = document.getElementById('zone-map');
                if (!mapEl) return;

                // Override icons with unpkg URLs
                L.Icon.Default.mergeOptions({
                    iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
                    iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
                    shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
                });

                // Default center: Penang campus coords
                const initLat = parseFloat(newZoneLat) || 5.457;
                const initLng = parseFloat(newZoneLng) || 100.286;

                const map = L.map('zone-map').setView([initLat, initLng], 15);
                mapInstanceRef.current = map;

                L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                    maxZoom: 19,
                    attribution: '&copy; OpenStreetMap contributors'
                }).addTo(map);

                const marker = L.marker([initLat, initLng], { draggable: true }).addTo(map);
                markerInstanceRef.current = marker;

                if (!newZoneLat || !newZoneLng) {
                    setNewZoneLat(initLat.toFixed(6));
                    setNewZoneLng(initLng.toFixed(6));
                }

                // Handle marker drag
                marker.on('dragend', (e) => {
                    const position = marker.getLatLng();
                    setNewZoneLat(position.lat.toFixed(6));
                    setNewZoneLng(position.lng.toFixed(6));
                });

                // Handle map clicks
                map.on('click', (e) => {
                    const { lat, lng } = e.latlng;
                    marker.setLatLng([lat, lng]);
                    setNewZoneLat(lat.toFixed(6));
                    setNewZoneLng(lng.toFixed(6));
                });

                // Force layout recalculation in case of modal flex transitions
                setTimeout(() => {
                    if (mapInstanceRef.current) {
                        mapInstanceRef.current.invalidateSize();
                    }
                }, 200);

            }, 100);
        }).catch(err => {
            console.error('Failed to load Leaflet:', err);
        });

        return () => {
            isMounted = false;
            if (mapTimeout) clearTimeout(mapTimeout);
            if (mapInstanceRef.current) {
                mapInstanceRef.current.remove();
                mapInstanceRef.current = null;
                markerInstanceRef.current = null;
            }
        };
    }, [isAddZoneModalOpen]);

    // Update map/marker when manual inputs change
    useEffect(() => {
        if (!mapInstanceRef.current || !markerInstanceRef.current) return;

        const lat = parseFloat(newZoneLat);
        const lng = parseFloat(newZoneLng);

        if (!isNaN(lat) && !isNaN(lng) && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
            const currentLatLng = markerInstanceRef.current.getLatLng();
            if (Math.abs(currentLatLng.lat - lat) > 0.00001 || Math.abs(currentLatLng.lng - lng) > 0.00001) {
                markerInstanceRef.current.setLatLng([lat, lng]);
                mapInstanceRef.current.panTo([lat, lng]);
            }
        }
    }, [newZoneLat, newZoneLng]);

    // Load Leaflet and initialize map when edit modal opens
    useEffect(() => {
        if (!isEditZoneModalOpen) {
            return;
        }

        let isMounted = true;
        let mapTimeout = null;

        loadLeaflet().then((L) => {
            if (!isMounted || !isEditZoneModalOpen) return;

            mapTimeout = setTimeout(() => {
                const mapEl = document.getElementById('edit-zone-map');
                if (!mapEl) return;

                L.Icon.Default.mergeOptions({
                    iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
                    iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
                    shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
                });

                const initLat = parseFloat(editZoneLat) || 5.457;
                const initLng = parseFloat(editZoneLng) || 100.286;

                const map = L.map('edit-zone-map').setView([initLat, initLng], 15);
                editMapInstanceRef.current = map;

                L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                    maxZoom: 19,
                    attribution: '&copy; OpenStreetMap contributors'
                }).addTo(map);

                const marker = L.marker([initLat, initLng], { draggable: true }).addTo(map);
                editMarkerInstanceRef.current = marker;

                // Handle marker drag
                marker.on('dragend', (e) => {
                    const position = marker.getLatLng();
                    setEditZoneLat(position.lat.toFixed(6));
                    setEditZoneLng(position.lng.toFixed(6));
                });

                // Handle map clicks
                map.on('click', (e) => {
                    const { lat, lng } = e.latlng;
                    marker.setLatLng([lat, lng]);
                    setEditZoneLat(lat.toFixed(6));
                    setEditZoneLng(lng.toFixed(6));
                });

                setTimeout(() => {
                    if (editMapInstanceRef.current) {
                        editMapInstanceRef.current.invalidateSize();
                    }
                }, 200);

            }, 100);
        }).catch(err => {
            console.error('Failed to load Leaflet:', err);
        });

        return () => {
            isMounted = false;
            if (mapTimeout) clearTimeout(mapTimeout);
            if (editMapInstanceRef.current) {
                editMapInstanceRef.current.remove();
                editMapInstanceRef.current = null;
                editMarkerInstanceRef.current = null;
            }
        };
    }, [isEditZoneModalOpen]);

    // Update edit map/marker when manual inputs change
    useEffect(() => {
        if (!editMapInstanceRef.current || !editMarkerInstanceRef.current) return;

        const lat = parseFloat(editZoneLat);
        const lng = parseFloat(editZoneLng);

        if (!isNaN(lat) && !isNaN(lng) && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
            const currentLatLng = editMarkerInstanceRef.current.getLatLng();
            if (Math.abs(currentLatLng.lat - lat) > 0.00001 || Math.abs(currentLatLng.lng - lng) > 0.00001) {
                editMarkerInstanceRef.current.setLatLng([lat, lng]);
                editMapInstanceRef.current.panTo([lat, lng]);
            }
        }
    }, [editZoneLat, editZoneLng]);

    const allZonesMapRef = useRef(null);
    const allZonesMarkersRef = useRef({});

    // Load Leaflet and display all zones on the main screen map
    useEffect(() => {
        let isMounted = true;
        let mapTimeout = null;

        if (loading) return;

        loadLeaflet().then((L) => {
            if (!isMounted) return;

            mapTimeout = setTimeout(() => {
                const mapEl = document.getElementById('all-zones-map');
                if (!mapEl) return;

                L.Icon.Default.mergeOptions({
                    iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
                    iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
                    shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
                });

                let map = allZonesMapRef.current;
                if (!map) {
                    map = L.map('all-zones-map').setView([5.457, 100.286], 15);
                    allZonesMapRef.current = map;

                    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                        maxZoom: 19,
                        attribution: '&copy; OpenStreetMap contributors'
                    }).addTo(map);
                }

                // Clear previous markers
                Object.values(allZonesMarkersRef.current).forEach(m => m.remove());
                allZonesMarkersRef.current = {};

                // Add new markers
                const markerList = [];
                zones.forEach(zone => {
                    const lat = parseFloat(zone.latitude);
                    const lng = parseFloat(zone.longitude);
                    if (!isNaN(lat) && !isNaN(lng)) {
                        const marker = L.marker([lat, lng])
                            .addTo(map)
                            .bindPopup(`<b>${zone.name}</b><br><span style="font-size:0.8rem;color:#4b5563;">${zone.description}</span>`);
                        allZonesMarkersRef.current[zone.id] = marker;
                        markerList.push([lat, lng]);
                    }
                });

                // Adjust bounds to show all markers
                if (markerList.length > 0) {
                    const bounds = L.latLngBounds(markerList);
                    map.fitBounds(bounds, { padding: [30, 30] });
                }

                setTimeout(() => {
                    if (allZonesMapRef.current) {
                        allZonesMapRef.current.invalidateSize();
                    }
                }, 200);

            }, 100);
        }).catch(err => {
            console.error('Failed to load Leaflet for main map:', err);
        });

        return () => {
            isMounted = false;
            if (mapTimeout) clearTimeout(mapTimeout);
        };
    }, [zones, loading]);

    const handleFocusZone = (zone) => {
        if (allZonesMapRef.current && window.L) {
            const lat = parseFloat(zone.latitude);
            const lng = parseFloat(zone.longitude);
            if (!isNaN(lat) && !isNaN(lng)) {
                allZonesMapRef.current.setView([lat, lng], 17);
                if (allZonesMarkersRef.current[zone.id]) {
                    allZonesMarkersRef.current[zone.id].openPopup();
                }
            }
        }
    };

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
                icon_url: newCatIcon,
                carbon_conversion_factor: parseFloat(newCatCarbon) || 0.0
            });
            setIsAddCatModalOpen(false);
            setNewCatName('');
            setNewCatCarbon('');
            setNewCatIcon('box-icon');
            fetchData();
        } catch (err) {
            alert(err.response?.data?.error || 'Failed to add category');
        }
    };

    const openEditCatModal = (cat) => {
        setEditCatId(cat.id);
        setEditCatName(cat.name);
        setEditCatIcon(cat.icon_url || cat.icon_name || 'box-icon');
        setEditCatCarbon(cat.carbon_conversion_factor.toString());
        setIsEditCatModalOpen(true);
    };

    const handleEditCategory = async () => {
        try {
            await api.put(`/admin/categories/${editCatId}`, {
                name: editCatName,
                icon_url: editCatIcon,
                carbon_conversion_factor: parseFloat(editCatCarbon) || 0.0
            });
            setIsEditCatModalOpen(false);
            fetchData();
        } catch (err) {
            alert(err.response?.data?.error || 'Failed to update category');
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

    const openEditSubModal = (sub) => {
        setEditSubId(sub.id);
        setEditSubName(sub.name);
        setEditSubCarbon(sub.carbon_conversion_factor.toString());
        setIsEditSubModalOpen(true);
    };

    const handleEditSubCategory = async () => {
        try {
            await api.put(`/admin/subcategories/${editSubId}`, {
                name: editSubName,
                carbon_conversion_factor: parseFloat(editSubCarbon) || 0.0
            });
            setIsEditSubModalOpen(false);
            fetchData();
        } catch (err) {
            alert(err.response?.data?.error || 'Failed to update subcategory');
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
                is_active: newZoneActive
            });
            setIsAddZoneModalOpen(false);
            setNewZoneName('');
            setNewZoneDesc('');
            setNewZoneLat('');
            setNewZoneLng('');
            setNewZoneActive(true);
            fetchData();
        } catch (err) {
            alert(err.response?.data?.error || 'Failed to add zone');
        }
    };

    const openEditZoneModal = (zone) => {
        setEditZoneId(zone.id);
        setEditZoneName(zone.name);
        setEditZoneDesc(zone.description || '');
        setEditZoneLat(zone.latitude.toString());
        setEditZoneLng(zone.longitude.toString());
        setEditZoneActive(zone.is_active !== false);
        setIsEditZoneModalOpen(true);
    };

    const handleEditZone = async () => {
        try {
            await api.put(`/admin/zones/${editZoneId}`, {
                name: editZoneName,
                description: editZoneDesc,
                latitude: parseFloat(editZoneLat),
                longitude: parseFloat(editZoneLng),
                is_active: editZoneActive
            });
            setIsEditZoneModalOpen(false);
            fetchData();
        } catch (err) {
            alert(err.response?.data?.error || 'Failed to update zone');
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
                                            <td>{cat.carbon_conversion_factor} kg CO2e / item</td>
                                            {isAdmin && (
                                                <td style={{ textAlign: 'right' }}>
                                                    <button 
                                                        style={{ background: 'none', border: 'none', color: 'var(--primary)', cursor: 'pointer', marginRight: '16px', fontWeight: 'bold' }}
                                                        onClick={(e) => { e.stopPropagation(); openAddSubModal(cat.id); }}
                                                    >
                                                        + SubCategory
                                                    </button>
                                                    <button 
                                                        style={{ background: 'none', border: 'none', color: 'var(--primary)', cursor: 'pointer', marginRight: '16px' }}
                                                        onClick={(e) => { e.stopPropagation(); openEditCatModal(cat); }}
                                                    >
                                                        <Edit size={18} />
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
                                                <td style={{ color: '#16a34a', fontWeight: 'bold' }}>{sub.carbon_conversion_factor} kg CO2e</td>
                                                {isAdmin && (
                                                    <td style={{ textAlign: 'right' }}>
                                                        <button 
                                                            style={{ background: 'none', border: 'none', color: 'var(--primary)', cursor: 'pointer', marginRight: '16px' }}
                                                            onClick={() => openEditSubModal(sub)}
                                                        >
                                                            <Edit size={16} />
                                                        </button>
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
                <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                    <div className="flex justify-between items-center">
                        <h2 style={{ margin: 0, fontSize: '1.25rem' }}>Safe Meetup Zones</h2>
                        {isAdmin && (
                            <button className="btn" style={{ padding: '0.5rem 1rem' }} onClick={() => setIsAddZoneModalOpen(true)}>
                                <Plus size={16} />
                            </button>
                        )}
                    </div>
                    <div className="card" style={{ padding: '16px', display: 'flex', flexDirection: 'column', gap: '16px' }}>
                        {/* Map displaying all points */}
                        <div 
                            id="all-zones-map" 
                            style={{ 
                                width: '100%', 
                                height: '240px', 
                                borderRadius: '12px', 
                                border: '1px solid #d1d5db',
                                overflow: 'hidden',
                                zIndex: 1
                            }}
                        ></div>

                        {/* List details */}
                        <div style={{ maxHeight: '360px', overflowY: 'auto' }}>
                            <table style={{ margin: 0 }}>
                                <thead>
                                    <tr>
                                        <th>LOCATION DETAILS</th>
                                        {isAdmin && <th style={{ textAlign: 'right' }}>ACTIONS</th>}
                                    </tr>
                                </thead>
                                <tbody>
                                    {zones.map(zone => (
                                        <tr 
                                            key={zone.id}
                                            style={{ cursor: 'pointer' }}
                                            onClick={() => handleFocusZone(zone)}
                                        >
                                            <td>
                                                <div style={{ fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '4px' }}>
                                                    <MapPin size={14} color="var(--primary)"/> {zone.name}
                                                    {zone.is_active === false && (
                                                        <span style={{ fontSize: '0.65rem', background: '#fee2e2', color: '#dc2626', padding: '1px 6px', borderRadius: '4px', fontWeight: 'bold' }}>
                                                            Inactive
                                                        </span>
                                                    )}
                                                </div>
                                                <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: '4px' }}>{zone.description}</div>
                                                <div style={{ fontSize: '0.7rem', color: '#9ca3af', marginTop: '2px', fontFamily: 'monospace' }}>
                                                    {zone.latitude}, {zone.longitude}
                                                </div>
                                            </td>
                                            {isAdmin && (
                                                <td style={{ textAlign: 'right' }}>
                                                    <button 
                                                        style={{ background: 'none', border: 'none', color: 'var(--primary)', cursor: 'pointer', marginRight: '16px' }}
                                                        onClick={(e) => { e.stopPropagation(); openEditZoneModal(zone); }}
                                                    >
                                                        <Edit size={18} />
                                                    </button>
                                                    <button 
                                                        style={{ background: 'none', border: 'none', color: '#dc2626', cursor: 'pointer' }}
                                                        onClick={(e) => { e.stopPropagation(); handleDeleteZone(zone.id); }}
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
            </div>

            {/* Modals */}
            {isAddCatModalOpen && (
                <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 50 }}>
                    <div className="card" style={{ width: '400px' }}>
                        <h2 style={{ marginTop: 0 }}>Add Category</h2>
                        <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: '600', marginBottom: '4px', color: '#4b5563' }}>Category Name</label>
                        <input type="text" className="input" value={newCatName} onChange={e => setNewCatName(e.target.value)} placeholder="Category Name (e.g. Books)" />
                        <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: '600', marginBottom: '4px', color: '#4b5563' }}>Icon Name/URL</label>
                        <input type="text" className="input" value={newCatIcon} onChange={e => setNewCatIcon(e.target.value)} placeholder="Icon Name/URL (e.g. book-icon)" />
                        <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: '600', marginBottom: '4px', color: '#4b5563' }}>Fallback Carbon Offset (kg CO2e)</label>
                        <input type="number" className="input" value={newCatCarbon} onChange={e => setNewCatCarbon(e.target.value)} placeholder="Fallback Carbon Offset (kg CO2e)" />
                        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '16px' }}>
                            <button className="btn btn-outline" onClick={() => setIsAddCatModalOpen(false)}>Cancel</button>
                            <button className="btn" onClick={handleAddCategory}>Add Category</button>
                        </div>
                    </div>
                </div>
            )}

            {isEditCatModalOpen && (
                <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 50 }}>
                    <div className="card" style={{ width: '400px' }}>
                        <h2 style={{ marginTop: 0 }}>Edit Category</h2>
                        <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: '600', marginBottom: '4px', color: '#4b5563' }}>Category Name</label>
                        <input type="text" className="input" value={editCatName} onChange={e => setEditCatName(e.target.value)} placeholder="Category Name" />
                        <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: '600', marginBottom: '4px', color: '#4b5563' }}>Icon Name/URL</label>
                        <input type="text" className="input" value={editCatIcon} onChange={e => setEditCatIcon(e.target.value)} placeholder="Icon Name/URL (e.g. shirt-icon)" />
                        <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: '600', marginBottom: '4px', color: '#4b5563' }}>Carbon Offset (kg CO2e)</label>
                        <input type="number" className="input" value={editCatCarbon} onChange={e => setEditCatCarbon(e.target.value)} placeholder="Fallback Carbon Offset (kg CO2e)" />
                        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '16px' }}>
                            <button className="btn btn-outline" onClick={() => setIsEditCatModalOpen(false)}>Cancel</button>
                            <button className="btn" onClick={handleEditCategory}>Save Changes</button>
                        </div>
                    </div>
                </div>
            )}

            {isAddSubModalOpen && (
                <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 50 }}>
                    <div className="card" style={{ width: '400px' }}>
                        <h2 style={{ marginTop: 0 }}>Add SubCategory</h2>
                        <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: '600', marginBottom: '4px', color: '#4b5563' }}>SubCategory Name</label>
                        <input type="text" className="input" value={newSubName} onChange={e => setNewSubName(e.target.value)} placeholder="SubCategory Name (e.g. T-Shirts)" />
                        <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: '600', marginBottom: '4px', color: '#4b5563' }}>Carbon Offset Factor (kg CO2e)</label>
                        <input type="number" className="input" value={newSubCarbon} onChange={e => setNewSubCarbon(e.target.value)} placeholder="Carbon Offset Factor (kg CO2e) - e.g. 2.5" />
                        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '16px' }}>
                            <button className="btn btn-outline" onClick={() => setIsAddSubModalOpen(false)}>Cancel</button>
                            <button className="btn" onClick={handleAddSubCategory}>Add SubCategory</button>
                        </div>
                    </div>
                </div>
            )}

            {isEditSubModalOpen && (
                <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 50 }}>
                    <div className="card" style={{ width: '400px' }}>
                        <h2 style={{ marginTop: 0 }}>Edit SubCategory</h2>
                        <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: '600', marginBottom: '4px', color: '#4b5563' }}>SubCategory Name</label>
                        <input type="text" className="input" value={editSubName} onChange={e => setEditSubName(e.target.value)} placeholder="SubCategory Name" />
                        <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: '600', marginBottom: '4px', color: '#4b5563' }}>Carbon Offset Factor (kg CO2e)</label>
                        <input type="number" className="input" value={editSubCarbon} onChange={e => setEditSubCarbon(e.target.value)} placeholder="Carbon Offset Factor (kg CO2e)" />
                        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '16px' }}>
                            <button className="btn btn-outline" onClick={() => setIsEditSubModalOpen(false)}>Cancel</button>
                            <button className="btn" onClick={handleEditSubCategory}>Save Changes</button>
                        </div>
                    </div>
                </div>
            )}

            {isAddZoneModalOpen && (
                <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 50 }}>
                    <div className="card" style={{ width: '760px', maxWidth: '95vw', padding: '24px' }}>
                        <h2 style={{ marginTop: 0, marginBottom: '20px', fontSize: '1.5rem', fontWeight: '700' }}>Add Safe Meetup Zone</h2>
                        
                        <div style={{ display: 'flex', gap: '24px', flexWrap: 'wrap' }}>
                            {/* Left Side: Form inputs */}
                            <div style={{ flex: '1 1 320px', display: 'flex', flexDirection: 'column', gap: '12px' }}>
                                <div>
                                    <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: '600', marginBottom: '4px', color: '#4b5563' }}>Zone Name</label>
                                    <input type="text" className="input" value={newZoneName} onChange={e => setNewZoneName(e.target.value)} placeholder="e.g. Main Library" style={{ width: '100%', margin: 0 }} />
                                </div>
                                <div>
                                    <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: '600', marginBottom: '4px', color: '#4b5563' }}>Description or Instructions</label>
                                    <textarea className="input" style={{ resize: 'none', height: '80px', width: '100%', margin: 0 }} value={newZoneDesc} onChange={e => setNewZoneDesc(e.target.value)} placeholder="Description or Instructions..." />
                                </div>
                                <div style={{ display: 'flex', gap: '12px' }}>
                                    <div style={{ flex: 1 }}>
                                        <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: '600', marginBottom: '4px', color: '#4b5563' }}>Latitude</label>
                                        <input type="number" className="input" value={newZoneLat} onChange={e => setNewZoneLat(e.target.value)} placeholder="e.g. 5.4578" step="any" style={{ width: '100%', margin: 0 }} />
                                    </div>
                                    <div style={{ flex: 1 }}>
                                        <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: '600', marginBottom: '4px', color: '#4b5563' }}>Longitude</label>
                                        <input type="number" className="input" value={newZoneLng} onChange={e => setNewZoneLng(e.target.value)} placeholder="e.g. 100.2863" step="any" style={{ width: '100%', margin: 0 }} />
                                    </div>
                                </div>
                                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginTop: '8px' }}>
                                    <input type="checkbox" id="add-zone-active" checked={newZoneActive} onChange={e => setNewZoneActive(e.target.checked)} />
                                    <label htmlFor="add-zone-active" style={{ fontSize: '0.9rem', fontWeight: '600', color: '#4b5563', cursor: 'pointer' }}>Active (Show on Mobile App)</label>
                                </div>
                            </div>
                            
                            {/* Right Side: Map */}
                            <div style={{ flex: '1 1 320px', display: 'flex', flexDirection: 'column' }}>
                                <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: '600', marginBottom: '6px', color: '#4b5563' }}>
                                    Map Location (Click on map or drag pin)
                                </label>
                                <div 
                                    id="zone-map" 
                                    style={{ 
                                        width: '100%', 
                                        height: '220px', 
                                        borderRadius: '8px', 
                                        border: '1px solid #d1d5db',
                                        overflow: 'hidden',
                                        zIndex: 1
                                    }}
                                ></div>
                                <span style={{ fontSize: '0.75rem', color: '#9ca3af', marginTop: '6px', fontStyle: 'italic' }}>
                                    Click anywhere on the map above to select the coordinates, or manually edit latitude/longitude.
                                </span>
                            </div>
                        </div>
                        
                        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '24px', borderTop: '1px solid #e5e7eb', paddingTop: '16px' }}>
                            <button className="btn btn-outline" onClick={() => setIsAddZoneModalOpen(false)}>Cancel</button>
                            <button className="btn" onClick={handleAddZone} disabled={!newZoneName || !newZoneLat || !newZoneLng}>Create Zone</button>
                        </div>
                    </div>
                </div>
            )}

            {isEditZoneModalOpen && (
                <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 50 }}>
                    <div className="card" style={{ width: '760px', maxWidth: '95vw', padding: '24px' }}>
                        <h2 style={{ marginTop: 0, marginBottom: '20px', fontSize: '1.5rem', fontWeight: '700' }}>Edit Safe Meetup Zone</h2>
                        
                        <div style={{ display: 'flex', gap: '24px', flexWrap: 'wrap' }}>
                            {/* Left Side: Form inputs */}
                            <div style={{ flex: '1 1 320px', display: 'flex', flexDirection: 'column', gap: '12px' }}>
                                <div>
                                    <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: '600', marginBottom: '4px', color: '#4b5563' }}>Zone Name</label>
                                    <input type="text" className="input" value={editZoneName} onChange={e => setEditZoneName(e.target.value)} placeholder="e.g. Main Library" style={{ width: '100%', margin: 0 }} />
                                </div>
                                <div>
                                    <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: '600', marginBottom: '4px', color: '#4b5563' }}>Description or Instructions</label>
                                    <textarea className="input" style={{ resize: 'none', height: '80px', width: '100%', margin: 0 }} value={editZoneDesc} onChange={e => setEditZoneDesc(e.target.value)} placeholder="Description or Instructions..." />
                                </div>
                                <div style={{ display: 'flex', gap: '12px' }}>
                                    <div style={{ flex: 1 }}>
                                        <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: '600', marginBottom: '4px', color: '#4b5563' }}>Latitude</label>
                                        <input type="number" className="input" value={editZoneLat} onChange={e => setEditZoneLat(e.target.value)} placeholder="e.g. 5.4578" step="any" style={{ width: '100%', margin: 0 }} />
                                    </div>
                                    <div style={{ flex: 1 }}>
                                        <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: '600', marginBottom: '4px', color: '#4b5563' }}>Longitude</label>
                                        <input type="number" className="input" value={editZoneLng} onChange={e => setEditZoneLng(e.target.value)} placeholder="e.g. 100.2863" step="any" style={{ width: '100%', margin: 0 }} />
                                    </div>
                                </div>
                                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginTop: '8px' }}>
                                    <input type="checkbox" id="edit-zone-active" checked={editZoneActive} onChange={e => setEditZoneActive(e.target.checked)} />
                                    <label htmlFor="edit-zone-active" style={{ fontSize: '0.9rem', fontWeight: '600', color: '#4b5563', cursor: 'pointer' }}>Active (Show on Mobile App)</label>
                                </div>
                            </div>
                            
                            {/* Right Side: Map */}
                            <div style={{ flex: '1 1 320px', display: 'flex', flexDirection: 'column' }}>
                                <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: '600', marginBottom: '6px', color: '#4b5563' }}>
                                    Map Location (Click on map or drag pin)
                                </label>
                                <div 
                                    id="edit-zone-map" 
                                    style={{ 
                                        width: '100%', 
                                        height: '220px', 
                                        borderRadius: '8px', 
                                        border: '1px solid #d1d5db',
                                        overflow: 'hidden',
                                        zIndex: 1
                                    }}
                                ></div>
                                <span style={{ fontSize: '0.75rem', color: '#9ca3af', marginTop: '6px', fontStyle: 'italic' }}>
                                    Click anywhere on the map above to select the coordinates, or manually edit latitude/longitude.
                                </span>
                            </div>
                        </div>
                        
                        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '24px', borderTop: '1px solid #e5e7eb', paddingTop: '16px' }}>
                            <button className="btn btn-outline" onClick={() => setIsEditZoneModalOpen(false)}>Cancel</button>
                            <button className="btn" onClick={handleEditZone} disabled={!editZoneName || !editZoneLat || !editZoneLng}>Save Changes</button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default Categories;
