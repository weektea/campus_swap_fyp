import React, { useState, useEffect } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { Search, Edit, Trash2, ArrowLeft, Filter, RefreshCw, ArrowUpDown, Download } from 'lucide-react';
import api, { IMAGE_BASE_URL } from '../services/api';
import PaginationControls from '../components/PaginationControls';

const Listings = () => {
    const location = useLocation();
    const navigate = useNavigate();
    const fromReportId = location.state?.fromReportId;

    const [listings, setListings] = useState([]);
    const [categories, setCategories] = useState([]);
    const [loading, setLoading] = useState(true);

    // Filter states
    const [searchTerm, setSearchTerm] = useState('');
    const [filterStatus, setFilterStatus] = useState('All');
    const [filterCategory, setFilterCategory] = useState('All');
    const [filterSubCategory, setFilterSubCategory] = useState('All');

    // Pagination & Sort states
    const [currentPage, setCurrentPage] = useState(1);
    const [pageSize, setPageSize] = useState(10);
    const [sortBy, setSortBy] = useState('newest');

    const sortOptions = [
        { label: 'Date: Newest First', value: 'newest' },
        { label: 'Date: Oldest First', value: 'oldest' },
        { label: 'Price: Low to High', value: 'price_asc' },
        { label: 'Price: High to Low', value: 'price_desc' },
        { label: 'Title: A to Z', value: 'title_asc' }
    ];

    // Auth context
    const [currentUser, setCurrentUser] = useState(null);

    // Modal state for Edit
    const [selectedListing, setSelectedListing] = useState(null);
    const [isEditModalOpen, setIsEditModalOpen] = useState(false);
    const [editStatus, setEditStatus] = useState('Available');

    useEffect(() => {
        const userStr = localStorage.getItem('user');
        if (userStr) {
            setCurrentUser(JSON.parse(userStr));
        }
        fetchCategories();
        fetchListings();
    }, [location]);

    const fetchCategories = async () => {
        try {
            const res = await api.get('/admin/categories');
            setCategories(Array.isArray(res.data) ? res.data : []);
        } catch (err) {
            console.error('Failed to fetch categories', err);
        }
    };

    const fetchListings = async () => {
        setLoading(true);
        try {
            const res = await api.get('/admin/listings');
            setListings(res.data);

            // Pre-select if navigated from Reports or Dashboard
            const targetId = location.state?.selectedId;
            if (targetId) {
                const found = res.data.find(item => item.id === targetId);
                if (found) {
                    setSelectedListing(found);
                    setEditStatus(found.status);
                    setIsEditModalOpen(true);
                }
            }
        } catch (err) {
            console.error('Failed to fetch listings', err);
        } finally {
            setLoading(false);
        }
    };

    const handleExportListingsCSV = () => {
        if (!sortedListings || sortedListings.length === 0) {
            alert('No listing data to export.');
            return;
        }
        const csvRows = [
            ['Listing ID', 'Title', 'Category', 'Subcategory', 'Type', 'Price/Rental Rate', 'Seller Name', 'Seller Email', 'Status', 'Condition', 'Posted Date', 'Updated Date']
        ];
        sortedListings.forEach(item => {
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
                item.createdAt ? new Date(item.createdAt).toLocaleString() : '',
                item.updatedAt ? new Date(item.updatedAt).toLocaleString() : ''
            ]);
        });
        const csvContent = csvRows.map(row => row.map(val => `"${String(val).replace(/"/g, '""')}"`).join(',')).join('\n');
        const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `Campus_Swap_Listings_Report_${new Date().toISOString().slice(0, 10)}.csv`;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        URL.revokeObjectURL(url);
    };

    const handleManageClick = (listing) => {
        setSelectedListing(listing);
        setEditStatus(listing.status);
        setIsEditModalOpen(true);
    };

    const handleUpdateStatus = async () => {
        if (!selectedListing) return;
        try {
            await api.put(`/admin/listings/${selectedListing.id}/status`, {
                status: editStatus
            });
            setIsEditModalOpen(false);
            fetchListings(); // Refresh
        } catch (err) {
            alert(err.response?.data?.error || 'Failed to update listing status');
        }
    };

    const handleDeleteListing = async () => {
        if (!selectedListing) return;
        if (!window.confirm('WARNING: Are you sure you want to permanently delete this listing from the database? This action cannot be undone!')) return;
        
        try {
            await api.delete(`/admin/listings/${selectedListing.id}`);
            setIsEditModalOpen(false);
            fetchListings();
        } catch (err) {
            alert(err.response?.data?.error || 'Failed to delete listing');
        }
    };

    const handleResetFilters = () => {
        setSearchTerm('');
        setFilterStatus('All');
        setFilterCategory('All');
        setFilterSubCategory('All');
        setSortBy('newest');
        setCurrentPage(1);
    };

    // Calculate available subcategories based on category filter
    const selectedCategoryObj = categories.find(c => c.id === filterCategory || c.name === filterCategory);
    const availableSubcategories = selectedCategoryObj ? (selectedCategoryObj.subcategories || []) : categories.flatMap(c => c.subcategories || []);

    // Filter Logic
    const filteredListings = listings.filter(item => {
        // 1. Search Query (Title, Description, Seller Email, Seller Name, ID)
        const term = searchTerm.toLowerCase().trim();
        const titleMatch = (item.title || '').toLowerCase().includes(term);
        const descMatch = (item.description || '').toLowerCase().includes(term);
        const sellerEmailMatch = (item.seller?.email || '').toLowerCase().includes(term);
        const sellerNameMatch = (item.seller?.full_name || '').toLowerCase().includes(term);
        const idMatch = (item.id || '').toLowerCase().includes(term);
        const matchSearch = !term || titleMatch || descMatch || sellerEmailMatch || sellerNameMatch || idMatch;

        // 2. Status Match
        const matchStatus = filterStatus === 'All' ? true : item.status === filterStatus;

        // 3. Category Match
        const matchCategory = filterCategory === 'All' ? true : (
            item.category_id === filterCategory || 
            item.categoryModel?.id === filterCategory ||
            item.categoryModel?.name === filterCategory
        );

        // 4. Subcategory Match
        const matchSubCategory = filterSubCategory === 'All' ? true : (
            item.sub_category_id === filterSubCategory || 
            item.subcategoryModel?.id === filterSubCategory ||
            item.subcategoryModel?.name === filterSubCategory
        );

        return matchSearch && matchStatus && matchCategory && matchSubCategory;
    });

    // Sort Logic
    const sortedListings = [...filteredListings].sort((a, b) => {
        const getPrice = (item) => {
            if (item.type === 'Rent') return parseFloat(item.rental_price_per_day) || 0;
            return parseFloat(item.price) || 0;
        };

        if (sortBy === 'newest') return new Date(b.createdAt) - new Date(a.createdAt);
        if (sortBy === 'oldest') return new Date(a.createdAt) - new Date(b.createdAt);
        if (sortBy === 'price_asc') return getPrice(a) - getPrice(b);
        if (sortBy === 'price_desc') return getPrice(b) - getPrice(a);
        if (sortBy === 'title_asc') return (a.title || '').localeCompare(b.title || '');
        return 0;
    });

    const totalPages = Math.ceil(sortedListings.length / pageSize) || 1;
    const paginatedListings = sortedListings.slice((currentPage - 1) * pageSize, currentPage * pageSize);

    if (loading) return <div className="p-8 text-center text-gray-500">Loading listings...</div>;

    return (
        <div>
            {fromReportId && (
                <div style={{ background: '#eff6ff', border: '1px solid #bfdbfe', borderRadius: '12px', padding: '12px 16px', marginBottom: '1.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <div style={{ color: '#1e40af', fontWeight: 'bold', fontSize: '0.9rem' }}>
                        🛡️ Inspecting listing from Report Ticket REP-{fromReportId}
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

            <div className="flex justify-between items-center mb-6">
                <div className="flex items-center gap-3">
                    <h1 style={{ fontSize: '1.5rem', margin: 0, fontWeight: '700' }}>Listings Management</h1>
                    <span style={{ fontSize: '0.85rem', padding: '4px 12px', borderRadius: '12px', background: '#eff6ff', color: '#2563eb', fontWeight: 'bold', border: '1px solid #bfdbfe' }}>
                        Showing {sortedListings.length} of {listings.length} listings
                    </span>
                </div>
            </div>

            {/* Filter Toolbar Card */}
            <div className="card mb-6" style={{ padding: '1.25rem', background: '#ffffff', borderRadius: '12px', border: '1px solid var(--border)' }}>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: '12px', alignItems: 'center', justifyContent: 'space-between' }}>
                    
                    {/* Search Field */}
                    <div style={{ 
                        display: 'flex', alignItems: 'center', 
                        background: '#f8fafc', 
                        border: '1px solid var(--border)',
                        borderRadius: '8px',
                        padding: '6px 14px',
                        flex: '1 1 240px',
                        minWidth: '220px'
                    }}>
                        <Search size={18} color="var(--text-muted)" style={{ marginRight: '8px', flexShrink: 0 }} />
                        <input 
                            type="text" 
                            placeholder="Search by title, description, seller or ID..." 
                            value={searchTerm}
                            onChange={(e) => { setSearchTerm(e.target.value); setCurrentPage(1); }}
                            style={{ border: 'none', background: 'transparent', outline: 'none', width: '100%', fontSize: '0.875rem' }}
                        />
                    </div>

                    {/* Filter Dropdowns Row */}
                    <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap', alignItems: 'center' }}>
                        
                        {/* Category Dropdown */}
                        <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                            <select 
                                className="input" 
                                style={{ margin: 0, padding: '7px 12px', fontSize: '0.85rem', borderRadius: '8px', width: '160px', appearance: 'auto' }}
                                value={filterCategory}
                                onChange={(e) => {
                                    setFilterCategory(e.target.value);
                                    setFilterSubCategory('All');
                                    setCurrentPage(1);
                                }}
                            >
                                <option value="All">📁 All Categories</option>
                                {categories.map(cat => (
                                    <option key={cat.id} value={cat.id}>{cat.name}</option>
                                ))}
                            </select>
                        </div>

                        {/* Subcategory Dropdown */}
                        <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                            <select 
                                className="input" 
                                style={{ margin: 0, padding: '7px 12px', fontSize: '0.85rem', borderRadius: '8px', width: '170px', appearance: 'auto' }}
                                value={filterSubCategory}
                                onChange={(e) => {
                                    setFilterSubCategory(e.target.value);
                                    setCurrentPage(1);
                                }}
                            >
                                <option value="All">📂 All Subcategories</option>
                                {availableSubcategories.map(sub => (
                                    <option key={sub.id} value={sub.id}>{sub.name}</option>
                                ))}
                            </select>
                        </div>

                        {/* Status Filter */}
                        <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                            <select 
                                className="input" 
                                style={{ margin: 0, padding: '7px 12px', fontSize: '0.85rem', borderRadius: '8px', width: '130px', appearance: 'auto' }}
                                value={filterStatus}
                                onChange={(e) => { setFilterStatus(e.target.value); setCurrentPage(1); }}
                            >
                                <option value="All">📌 All Status</option>
                                <option value="Available">Available</option>
                                <option value="Reserved">Reserved</option>
                                <option value="Sold">Sold</option>
                                <option value="Suspended">Suspended</option>
                                <option value="Removed">Removed</option>
                            </select>
                        </div>

                        {/* Sort By Dropdown */}
                        <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                            <select 
                                className="input" 
                                style={{ margin: 0, padding: '7px 12px', fontSize: '0.85rem', borderRadius: '8px', width: '175px', appearance: 'auto', fontWeight: 'bold', color: 'var(--primary)' }}
                                value={sortBy}
                                onChange={(e) => { setSortBy(e.target.value); setCurrentPage(1); }}
                            >
                                <option value="newest">⏳ Newest Post</option>
                                <option value="oldest">⌛ Oldest Post</option>
                                <option value="price_asc">💵 Price: Low to High</option>
                                <option value="price_desc">💎 Price: High to Low</option>
                                <option value="title_asc">🔤 Title: A to Z</option>
                            </select>
                        </div>

                        {/* Reset Filters Button */}
                        {(searchTerm || filterStatus !== 'All' || filterCategory !== 'All' || filterSubCategory !== 'All' || sortBy !== 'newest') && (
                            <button
                                className="btn"
                                onClick={handleResetFilters}
                                style={{ padding: '7px 12px', fontSize: '0.8rem', background: '#f3f4f6', color: '#4b5563', border: '1px solid #d1d5db', display: 'flex', alignItems: 'center', gap: '4px' }}
                                title="Reset Filters"
                            >
                                <RefreshCw size={14} /> Reset
                            </button>
                        )}

                        {/* Export CSV Button */}
                        <button
                            className="btn"
                            onClick={handleExportListingsCSV}
                            style={{ padding: '7px 14px', fontSize: '0.85rem', background: '#0d503c', color: 'white', border: 'none', display: 'flex', alignItems: 'center', gap: '6px' }}
                            title="Export Listings CSV"
                        >
                            <Download size={15} /> Export CSV
                        </button>
                    </div>
                </div>
            </div>

            {/* Listings Table */}
            <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
                <table>
                    <thead>
                        <tr>
                            <th style={{ width: '50px', textAlign: 'center' }}>NO.</th>
                            <th>LISTING</th>
                            <th>CATEGORY</th>
                            <th>PRICE</th>
                            <th>SELLER</th>
                            <th>TYPE</th>
                            <th>POSTED / UPDATED</th>
                            <th>STATUS</th>
                            <th>ACTIONS</th>
                        </tr>
                    </thead>
                    <tbody>
                        {paginatedListings.map((item, index) => (
                            <tr key={item.id}>
                                <td style={{ textAlign: 'center', fontWeight: 'bold', color: 'var(--text-muted)' }}>{(currentPage - 1) * pageSize + index + 1}</td>
                                <td style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                                    <div style={{ width: '44px', height: '44px', background: '#f3f4f6', borderRadius: '8px', overflow: 'hidden', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                                        {item.image_urls && item.image_urls.length > 0 ? (
                                            <img src={`${IMAGE_BASE_URL}${item.image_urls[0]}`} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                                        ) : (
                                            <span style={{ color: '#9ca3af', fontSize: '0.6rem' }}>No Img</span>
                                        )}
                                    </div>
                                    <div>
                                        <div style={{ fontWeight: 'bold', color: '#111827', fontSize: '0.9rem' }}>{item.title}</div>
                                        <div style={{ fontSize: '0.725rem', color: 'var(--text-muted)' }}>ID: {item.id.substring(0,8)}...</div>
                                    </div>
                                </td>
                                <td>
                                    <div style={{ fontSize: '0.8rem', fontWeight: 'bold', color: '#374151' }}>
                                        {item.categoryModel?.name || 'General'}
                                    </div>
                                    {item.subcategoryModel?.name && (
                                        <div style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>
                                            {item.subcategoryModel.name}
                                        </div>
                                    )}
                                </td>
                                <td style={{ color: 'var(--primary)' }}>
                                    {item.type === 'Rent' ? (
                                        <>
                                            <div style={{ fontWeight: 'bold' }}>RM {item.rental_price_per_day} <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>/ day</span></div>
                                            <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Dep: RM {item.rental_deposit}</div>
                                            <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Max: {item.max_rental_duration}d</div>
                                        </>
                                    ) : (
                                        <div style={{ fontWeight: 'bold' }}>RM {item.price}</div>
                                    )}
                                </td>
                                <td>
                                    <div>{item.seller?.full_name || 'No Name'}</div>
                                    <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{item.seller?.email}</div>
                                </td>
                                <td>
                                    <span style={{ 
                                        padding: '4px 8px', 
                                        background: item.type === 'Sale' ? '#e0e7ff' : '#fce7f3', 
                                        borderRadius: '4px', 
                                        color: item.type === 'Sale' ? '#3730a3' : '#9d174d', 
                                        fontSize: '0.75rem', 
                                        fontWeight: 'bold',
                                    }}>
                                        {item.type || 'Sale'}
                                    </span>
                                </td>
                                <td>
                                    <div style={{ fontSize: '0.8rem', fontWeight: 'bold', color: 'var(--text-main)' }}>
                                        {item.createdAt ? new Date(item.createdAt).toLocaleDateString() : 'N/A'}
                                    </div>
                                    <div style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>
                                        Upd: {item.updatedAt ? new Date(item.updatedAt).toLocaleDateString() : 'N/A'}
                                    </div>
                                </td>
                                <td>
                                    <span style={{ 
                                        padding: '4px 12px', 
                                        borderRadius: '12px', 
                                        fontSize: '0.75rem', 
                                        fontWeight: 'bold',
                                        background: item.status === 'Available' ? '#dcfce7' : 
                                                    item.status === 'Sold' ? '#f3f4f6' : 
                                                    item.status === 'Reserved' ? '#fef3c7' : '#fee2e2',
                                        color: item.status === 'Available' ? '#16a34a' : 
                                               item.status === 'Sold' ? '#4b5563' : 
                                               item.status === 'Reserved' ? '#d97706' : '#dc2626'
                                    }}>
                                        {item.status}
                                    </span>
                                </td>
                                <td>
                                    <button 
                                        onClick={() => handleManageClick(item)}
                                        style={{ background: 'none', border: 'none', color: 'var(--primary)', fontWeight: 'bold', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '4px' }}
                                    >
                                        <Edit size={14} /> Manage
                                    </button>
                                </td>
                            </tr>
                        ))}
                        {paginatedListings.length === 0 && (
                            <tr>
                                <td colSpan="9" style={{ textAlign: 'center', padding: '3rem', color: 'var(--text-muted)' }}>
                                    No listings found matching the current search & filter criteria.
                                </td>
                            </tr>
                        )}
                    </tbody>
                </table>
            </div>

            <PaginationControls
                currentPage={currentPage}
                totalPages={totalPages}
                pageSize={pageSize}
                totalItems={sortedListings.length}
                onPageChange={(page) => setCurrentPage(page)}
                onPageSizeChange={(size) => { setPageSize(size); setCurrentPage(1); }}
                sortBy={sortBy}
                sortOptions={sortOptions}
                onSortChange={(sort) => { setSortBy(sort); setCurrentPage(1); }}
            />

            {/* Edit Modal */}
            {isEditModalOpen && selectedListing && (
                <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 50 }}>
                    <div className="card" style={{ width: '600px', background: 'white', padding: '2rem', maxHeight: '90vh', overflowY: 'auto' }}>
                        <h2 style={{ marginTop: 0, borderBottom: '1px solid var(--border)', paddingBottom: '0.75rem', marginBottom: '1.25rem' }}>Listing Details & Moderation</h2>
                        
                        {/* Listing Preview Row */}
                        <div style={{ display: 'flex', gap: '1.25rem', marginBottom: '1.5rem', background: '#f8fafc', padding: '16px', borderRadius: '12px', border: '1px solid var(--border)' }}>
                            <div style={{ width: '90px', height: '90px', background: '#e2e8f0', borderRadius: '8px', overflow: 'hidden', flexShrink: 0 }}>
                                {selectedListing.image_urls && selectedListing.image_urls.length > 0 ? (
                                    <img src={`${IMAGE_BASE_URL}${selectedListing.image_urls[0]}`} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                                ) : (
                                    <div style={{ width: '100%', height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#64748b', fontSize: '0.8rem' }}>No Image</div>
                                )}
                            </div>
                            <div style={{ flex: 1 }}>
                                <h3 style={{ margin: '0 0 6px 0', fontSize: '1.1rem', fontWeight: 'bold' }}>{selectedListing.title}</h3>
                                <div style={{ display: 'flex', gap: '12px', fontSize: '0.85rem', color: 'var(--text-muted)', marginBottom: '8px' }}>
                                    <span>Type: <strong style={{ color: 'var(--text)' }}>{selectedListing.type}</strong></span>
                                    <span>Condition: <strong style={{ color: 'var(--text)' }}>{selectedListing.condition}</strong></span>
                                    <span>Price: <strong style={{ color: 'var(--primary)' }}>RM {selectedListing.type === 'Rent' ? `${selectedListing.rental_price_per_day}/day` : selectedListing.price}</strong></span>
                                </div>
                                <div style={{ fontSize: '0.85rem', color: 'var(--text-muted)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                    <div>
                                        <strong>Category:</strong> <span style={{ color: 'var(--text-main)', fontWeight: 'bold' }}>{selectedListing.categoryModel?.name || 'General'} {selectedListing.subcategoryModel?.name ? `> ${selectedListing.subcategoryModel.name}` : ''}</span>
                                    </div>
                                    <div>
                                        <strong>Status:</strong> <span style={{ 
                                            padding: '2px 8px', 
                                            borderRadius: '8px', 
                                            fontSize: '0.75rem', 
                                            fontWeight: 'bold',
                                            background: selectedListing.status === 'Available' ? '#dcfce7' : 
                                                        selectedListing.status === 'Sold' ? '#f3f4f6' : 
                                                        selectedListing.status === 'Reserved' ? '#fef3c7' : '#fee2e2',
                                            color: selectedListing.status === 'Available' ? '#16a34a' : 
                                                   selectedListing.status === 'Sold' ? '#4b5563' : 
                                                   selectedListing.status === 'Reserved' ? '#d97706' : '#dc2626'
                                }}>{selectedListing.status}</span>
                                    </div>
                                </div>
                                {/* Timestamps Metadata Badges */}
                                <div style={{ marginTop: '8px', paddingTop: '8px', borderTop: '1px dashed var(--border)', fontSize: '0.75rem', color: 'var(--text-muted)', display: 'flex', gap: '16px' }}>
                                    <span>📅 <strong>Posted:</strong> {selectedListing.createdAt ? new Date(selectedListing.createdAt).toLocaleString() : 'N/A'}</span>
                                    <span>🔄 <strong>Updated:</strong> {selectedListing.updatedAt ? new Date(selectedListing.updatedAt).toLocaleString() : 'N/A'}</span>
                                </div>
                            </div>
                        </div>

                        {/* Description Section */}
                        <div style={{ marginBottom: '1.5rem' }}>
                            <span style={{ fontWeight: 'bold', fontSize: '0.75rem', color: '#64748b', display: 'block', textTransform: 'uppercase', marginBottom: '6px' }}>Description</span>
                            <div style={{ background: '#f8fafc', padding: '12px 16px', borderRadius: '8px', fontSize: '0.9rem', lineHeight: '1.5', border: '1px solid var(--border)', maxHeight: '120px', overflowY: 'auto' }}>
                                {selectedListing.description || <span style={{ color: 'var(--text-muted)', fontStyle: 'italic' }}>No description provided.</span>}
                            </div>
                        </div>

                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem', marginBottom: '1.75rem' }}>
                            {/* Seller / Student Details */}
                            <div>
                                <span style={{ fontWeight: 'bold', fontSize: '0.75rem', color: '#64748b', display: 'block', textTransform: 'uppercase', marginBottom: '8px' }}>Student Profile</span>
                                <div style={{ fontSize: '0.9rem', display: 'flex', flexDirection: 'column', gap: '6px', padding: '12px', background: '#f8fafc', borderRadius: '8px', border: '1px solid var(--border)' }}>
                                    <div><strong>Name:</strong> {selectedListing.seller?.full_name || selectedListing.seller?.username || 'N/A'}</div>
                                    <div><strong>Email:</strong> {selectedListing.seller?.email || 'N/A'}</div>
                                    <div>
                                        <strong>Reputation:</strong> ⭐ {selectedListing.seller?.reputation_score !== undefined && selectedListing.seller?.reputation_score !== null ? Number(selectedListing.seller.reputation_score).toFixed(1) : '5.0'} / 5.0
                                        <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginLeft: '6px' }}>
                                            ({selectedListing.seller?.total_reviews || 0} review{selectedListing.seller?.total_reviews === 1 ? '' : 's'})
                                        </span>
                                    </div>
                                    <div>
                                        <strong>Status:</strong> <span style={{ fontWeight: 'bold', color: (selectedListing.seller?.is_active !== false && selectedListing.seller?.status !== 'suspended') ? '#16a34a' : '#dc2626' }}>
                                            {(selectedListing.seller?.is_active !== false && selectedListing.seller?.status !== 'suspended') ? 'Active' : 'Banned / Suspended'}
                                        </span>
                                    </div>
                                    <div>
                                        <strong>Verified:</strong> <span style={{ fontWeight: 'bold', color: selectedListing.seller?.is_verified ? '#16a34a' : '#d97706' }}>
                                            {selectedListing.seller?.is_verified ? 'Yes (TAR UMT Student)' : 'No'}
                                        </span>
                                    </div>
                                </div>
                            </div>

                            {/* Status Change Section */}
                            <div>
                                <span style={{ fontWeight: 'bold', fontSize: '0.75rem', color: '#64748b', display: 'block', textTransform: 'uppercase', marginBottom: '8px' }}>Action & Status</span>
                                <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                                    <div>
                                        <label style={{ display: 'block', marginBottom: '6px', fontSize: '0.85rem' }}>Set Listing Status:</label>
                                        <select 
                                            className="input" 
                                            value={editStatus} 
                                            onChange={(e) => setEditStatus(e.target.value)}
                                            style={{ width: '100%', marginBottom: 0 }}
                                        >
                                            <option value="Available">Available (Active)</option>
                                            <option value="Reserved">Reserved</option>
                                            <option value="Sold">Sold</option>
                                            <option value="Suspended">Suspended (Policy Violation)</option>
                                            <option value="Removed">Removed (Admin Deleted)</option>
                                        </select>
                                    </div>
                                </div>
                            </div>
                        </div>

                        {/* Modal Footer Buttons */}
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderTop: '1px solid var(--border)', paddingTop: '1.25rem' }}>
                            {currentUser?.role === 'admin' ? (
                                <button className="btn" style={{ background: '#fef2f2', color: '#dc2626', border: '1px solid #fca5a5' }} onClick={handleDeleteListing}>
                                    <Trash2 size={16} /> Permanent Delete
                                </button>
                            ) : <div></div>}

                            <div style={{ display: 'flex', gap: '12px' }}>
                                <button className="btn" style={{ background: '#e5e7eb', color: '#374151', border: 'none' }} onClick={() => setIsEditModalOpen(false)}>Cancel</button>
                                <button className="btn" style={{ background: 'var(--primary)', color: 'white', border: 'none' }} onClick={handleUpdateStatus}>Save Changes</button>
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default Listings;
