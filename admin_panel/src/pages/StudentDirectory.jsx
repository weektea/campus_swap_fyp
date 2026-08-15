import React, { useState, useEffect, useRef } from 'react';
import { 
    GraduationCap, 
    UploadCloud, 
    UserPlus, 
    Download, 
    Search, 
    Filter, 
    CheckCircle2, 
    XCircle, 
    Clock, 
    AlertCircle, 
    Trash2, 
    FileSpreadsheet, 
    RotateCcw,
    Sparkles,
    ShieldCheck,
    Check,
    X,
    Building2,
    Calendar,
    HelpCircle
} from 'lucide-react';
import api from '../services/api';
import PaginationControls from '../components/PaginationControls';

const StudentDirectory = () => {
    const [students, setStudents] = useState([]);
    const [loading, setLoading] = useState(true);
    const [totalCount, setTotalCount] = useState(0);
    const [stats, setStats] = useState({ totalAll: 0, totalActive: 0, totalExpired: 0, faculties: [] });

    // Search and Filters
    const [searchTerm, setSearchTerm] = useState('');
    const [statusFilter, setStatusFilter] = useState('All');
    const [facultyFilter, setFacultyFilter] = useState('All');
    const [sortBy, setSortBy] = useState('newest');

    // Pagination
    const [currentPage, setCurrentPage] = useState(1);
    const [pageSize, setPageSize] = useState(10);
    const [totalPages, setTotalPages] = useState(1);

    // Modals
    const [isUploadModalOpen, setIsUploadModalOpen] = useState(false);
    const [isAddModalOpen, setIsAddModalOpen] = useState(false);

    // Upload State
    const [selectedFile, setSelectedFile] = useState(null);
    const [isUploading, setIsUploading] = useState(false);
    const [uploadResult, setUploadResult] = useState(null);
    const [isDragging, setIsDragging] = useState(false);
    const fileInputRef = useRef(null);

    // Single Add Form
    const [newStudentForm, setNewStudentForm] = useState({
        student_id: '',
        email: '',
        faculty: 'FCI',
        enrollment_year: new Date().getFullYear(),
        status: 'Active'
    });
    const [isSubmittingAdd, setIsSubmittingAdd] = useState(false);

    // Notification toast
    const [toastMessage, setToastMessage] = useState(null);

    const sortOptions = [
        { label: 'Date: Newest First', value: 'newest' },
        { label: 'Date: Oldest First', value: 'oldest' },
        { label: 'Student ID: A to Z', value: 'student_id_asc' },
        { label: 'Student ID: Z to A', value: 'student_id_desc' },
        { label: 'Enrollment Year: High to Low', value: 'year_desc' },
        { label: 'Enrollment Year: Low to High', value: 'year_asc' }
    ];

    const showToast = (msg, type = 'success') => {
        setToastMessage({ text: msg, type });
        setTimeout(() => setToastMessage(null), 4000);
    };

    useEffect(() => {
        fetchStudents();
    }, [currentPage, pageSize, statusFilter, facultyFilter, sortBy]);

    // Debounce Search
    useEffect(() => {
        const timer = setTimeout(() => {
            setCurrentPage(1);
            fetchStudents();
        }, 400);
        return () => clearTimeout(timer);
    }, [searchTerm]);

    const fetchStudents = async () => {
        setLoading(true);
        try {
            const params = {
                page: currentPage,
                limit: pageSize,
                search: searchTerm,
                status: statusFilter,
                faculty: facultyFilter,
                sortBy
            };
            const res = await api.get('/admin/whitelist', { params });
            setStudents(res.data.students || []);
            setTotalCount(res.data.total || 0);
            setTotalPages(res.data.totalPages || 1);
            if (res.data.stats) {
                setStats(res.data.stats);
            }
        } catch (err) {
            console.error('Failed to fetch whitelist students:', err);
            showToast('Failed to load whitelist directory', 'error');
        } finally {
            setLoading(false);
        }
    };

    // Toggle Status (Extend / Expire)
    const handleToggleStatus = async (student) => {
        const nextStatus = student.status === 'Active' ? 'Expired' : 'Active';
        const actionLabel = nextStatus === 'Active' ? 'Extend Access (set Active)' : 'Expire Access (set Expired)';
        
        try {
            await api.put(`/admin/whitelist/${student.id}/status`, { status: nextStatus });
            showToast(`Student ${student.student_id} status changed to ${nextStatus}!`);
            fetchStudents();
        } catch (err) {
            showToast(err.response?.data?.error || 'Failed to update student status', 'error');
        }
    };

    // Delete Student
    const handleDeleteStudent = async (student) => {
        if (!window.confirm(`Are you sure you want to remove student '${student.student_id}' (${student.email}) from the whitelist?`)) {
            return;
        }
        try {
            await api.delete(`/admin/whitelist/${student.id}`);
            showToast(`Student ${student.student_id} removed from whitelist.`);
            fetchStudents();
        } catch (err) {
            showToast(err.response?.data?.error || 'Failed to delete student', 'error');
        }
    };

    // Handle CSV File Selection
    const handleFileChange = (e) => {
        const file = e.target.files[0];
        if (file) {
            if (!file.name.toLowerCase().endsWith('.csv')) {
                alert('Please select a valid .csv file.');
                return;
            }
            setSelectedFile(file);
            setUploadResult(null);
        }
    };

    // Handle Drag & Drop
    const handleDragOver = (e) => {
        e.preventDefault();
        setIsDragging(true);
    };

    const handleDragLeave = () => {
        setIsDragging(false);
    };

    const handleDrop = (e) => {
        e.preventDefault();
        setIsDragging(false);
        const file = e.dataTransfer.files[0];
        if (file) {
            if (!file.name.toLowerCase().endsWith('.csv')) {
                alert('Please drop a valid .csv file.');
                return;
            }
            setSelectedFile(file);
            setUploadResult(null);
        }
    };

    // Upload CSV
    const handleUploadCSV = async (e) => {
        e.preventDefault();
        if (!selectedFile) {
            alert('Please select a CSV file to upload.');
            return;
        }

        setIsUploading(true);
        setUploadResult(null);

        const formData = new FormData();
        formData.append('file', selectedFile);

        try {
            const res = await api.post('/admin/whitelist/upload', formData, {
                headers: { 'Content-Type': 'multipart/form-data' }
            });
            setUploadResult({
                success: true,
                message: res.data.message,
                summary: res.data.summary
            });
            showToast('CSV uploaded and processed successfully!');
            fetchStudents();
        } catch (err) {
            console.error('Upload error:', err);
            setUploadResult({
                success: false,
                message: err.response?.data?.error || 'Failed to upload and parse CSV file.'
            });
        } finally {
            setIsUploading(false);
        }
    };

    // Single Add Student Submit
    const handleAddStudentSubmit = async (e) => {
        e.preventDefault();
        setIsSubmittingAdd(true);
        try {
            await api.post('/admin/whitelist', newStudentForm);
            showToast(`Student ${newStudentForm.student_id} added successfully!`);
            setIsAddModalOpen(false);
            setNewStudentForm({
                student_id: '',
                email: '',
                faculty: 'FCI',
                enrollment_year: new Date().getFullYear(),
                status: 'Active'
            });
            fetchStudents();
        } catch (err) {
            alert(err.response?.data?.error || 'Failed to add student to whitelist');
        } finally {
            setIsSubmittingAdd(false);
        }
    };

    // Export CSV Download
    const handleExportCSV = async () => {
        try {
            const res = await api.get('/admin/whitelist/export', { responseType: 'blob' });
            const url = window.URL.createObjectURL(new Blob([res.data]));
            const link = document.createElement('a');
            link.href = url;
            link.setAttribute('download', `student_whitelist_${new Date().toISOString().slice(0, 10)}.csv`);
            document.body.appendChild(link);
            link.click();
            link.remove();
            showToast('Whitelist exported successfully');
        } catch (err) {
            showToast('Failed to export whitelist CSV', 'error');
        }
    };

    // Download Sample CSV Template
    const handleDownloadTemplate = () => {
        const sampleContent = 'student_id,email,faculty,enrollment_year\n24PMR01234,student1@student.mmu.edu.my,FCI,2024\n23PMR09876,student2@student.mmu.edu.my,FOE,2023\n19PMR00001,graduated@student.mmu.edu.my,FCM,2019';
        const blob = new Blob([sampleContent], { type: 'text/csv;charset=utf-8;' });
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = 'campus_swap_whitelist_sample.csv';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    };

    const currentYear = new Date().getFullYear();

    return (
        <div style={{ padding: '0.5rem 0' }}>
            {/* Toast Notification */}
            {toastMessage && (
                <div style={{
                    position: 'fixed',
                    top: '20px',
                    right: '20px',
                    zIndex: 9999,
                    background: toastMessage.type === 'error' ? '#ef4444' : '#10b981',
                    color: 'white',
                    padding: '12px 20px',
                    borderRadius: '8px',
                    boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '10px',
                    fontWeight: '500',
                    animation: 'slideIn 0.3s ease-out'
                }}>
                    {toastMessage.type === 'error' ? <AlertCircle size={20} /> : <CheckCircle2 size={20} />}
                    <span>{toastMessage.text}</span>
                </div>
            )}

            {/* Page Header */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: '16px', marginBottom: '1.5rem' }}>
                <div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                        <div style={{ background: '#ecfdf5', color: '#059669', padding: '10px', borderRadius: '10px' }}>
                            <GraduationCap size={26} />
                        </div>
                        <div>
                            <h1 style={{ fontSize: '1.75rem', fontWeight: 'bold', margin: 0, color: 'var(--text-main)' }}>
                                Student Directory & Whitelist
                            </h1>
                            <p style={{ margin: '4px 0 0 0', color: 'var(--text-muted)', fontSize: '0.9rem' }}>
                                Manage verified university students authorized for campus registration & trading access.
                            </p>
                        </div>
                    </div>
                </div>

                <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
                    <button
                        onClick={handleExportCSV}
                        className="btn"
                        style={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: '8px',
                            background: 'white',
                            border: '1px solid var(--border)',
                            color: 'var(--text-main)',
                            padding: '9px 14px',
                            borderRadius: '8px',
                            cursor: 'pointer',
                            fontWeight: '600',
                            fontSize: '0.875rem'
                        }}
                    >
                        <Download size={16} />
                        <span>Export CSV</span>
                    </button>

                    <button
                        onClick={() => setIsAddModalOpen(true)}
                        className="btn"
                        style={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: '8px',
                            background: 'white',
                            border: '1px solid var(--border)',
                            color: 'var(--text-main)',
                            padding: '9px 14px',
                            borderRadius: '8px',
                            cursor: 'pointer',
                            fontWeight: '600',
                            fontSize: '0.875rem'
                        }}
                    >
                        <UserPlus size={16} />
                        <span>Add Student</span>
                    </button>

                    <button
                        onClick={() => {
                            setSelectedFile(null);
                            setUploadResult(null);
                            setIsUploadModalOpen(true);
                        }}
                        className="btn btn-primary"
                        style={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: '8px',
                            background: 'var(--primary, #00695C)',
                            color: 'white',
                            border: 'none',
                            padding: '9px 16px',
                            borderRadius: '8px',
                            cursor: 'pointer',
                            fontWeight: '600',
                            fontSize: '0.875rem',
                            boxShadow: '0 2px 6px rgba(0,105,92,0.25)'
                        }}
                    >
                        <UploadCloud size={18} />
                        <span>Upload CSV</span>
                    </button>
                </div>
            </div>

            {/* Metrics & Statistics Cards */}
            <div style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
                gap: '16px',
                marginBottom: '1.5rem'
            }}>
                {/* Total Whitelisted */}
                <div style={{
                    background: 'white',
                    border: '1px solid var(--border)',
                    borderRadius: '12px',
                    padding: '16px 20px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between'
                }}>
                    <div>
                        <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: '600', textTransform: 'uppercase' }}>
                            Total Whitelisted
                        </div>
                        <div style={{ fontSize: '1.75rem', fontWeight: 'bold', color: 'var(--text-main)', marginTop: '4px' }}>
                            {stats.totalAll}
                        </div>
                        <div style={{ fontSize: '0.75rem', color: '#6b7280', marginTop: '2px' }}>
                            University verified records
                        </div>
                    </div>
                    <div style={{ background: '#f0fdf4', color: '#16a34a', padding: '12px', borderRadius: '10px' }}>
                        <ShieldCheck size={26} />
                    </div>
                </div>

                {/* Active Students */}
                <div style={{
                    background: 'white',
                    border: '1px solid var(--border)',
                    borderRadius: '12px',
                    padding: '16px 20px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between'
                }}>
                    <div>
                        <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: '600', textTransform: 'uppercase' }}>
                            Active Access
                        </div>
                        <div style={{ fontSize: '1.75rem', fontWeight: 'bold', color: '#16a34a', marginTop: '4px' }}>
                            {stats.totalActive}
                        </div>
                        <div style={{ fontSize: '0.75rem', color: '#16a34a', marginTop: '2px', fontWeight: '500' }}>
                            {stats.totalAll > 0 ? `${Math.round((stats.totalActive / stats.totalAll) * 100)}% eligible to trade` : '0%'}
                        </div>
                    </div>
                    <div style={{ background: '#ecfdf5', color: '#059669', padding: '12px', borderRadius: '10px' }}>
                        <CheckCircle2 size={26} />
                    </div>
                </div>

                {/* Expired / Graduated */}
                <div style={{
                    background: 'white',
                    border: '1px solid var(--border)',
                    borderRadius: '12px',
                    padding: '16px 20px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between'
                }}>
                    <div>
                        <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: '600', textTransform: 'uppercase' }}>
                            Expired / Graduated
                        </div>
                        <div style={{ fontSize: '1.75rem', fontWeight: 'bold', color: '#dc2626', marginTop: '4px' }}>
                            {stats.totalExpired}
                        </div>
                        <div style={{ fontSize: '0.75rem', color: '#dc2626', marginTop: '2px', fontWeight: '500' }}>
                            Tenure &gt; 4 yrs or manual expire
                        </div>
                    </div>
                    <div style={{ background: '#fef2f2', color: '#dc2626', padding: '12px', borderRadius: '10px' }}>
                        <Clock size={26} />
                    </div>
                </div>

                {/* Participating Faculties */}
                <div style={{
                    background: 'white',
                    border: '1px solid var(--border)',
                    borderRadius: '12px',
                    padding: '16px 20px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between'
                }}>
                    <div>
                        <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: '600', textTransform: 'uppercase' }}>
                            Faculties Included
                        </div>
                        <div style={{ fontSize: '1.75rem', fontWeight: 'bold', color: 'var(--primary)', marginTop: '4px' }}>
                            {stats.faculties?.length || 0}
                        </div>
                        <div style={{ fontSize: '0.75rem', color: '#6b7280', marginTop: '2px' }}>
                            Campus departments
                        </div>
                    </div>
                    <div style={{ background: '#f0fdfa', color: '#0d9488', padding: '12px', borderRadius: '10px' }}>
                        <Building2 size={26} />
                    </div>
                </div>
            </div>

            {/* Auto-Expiration Rule Notice Banner */}
            <div style={{
                background: '#eff6ff',
                border: '1px solid #bfdbfe',
                borderRadius: '8px',
                padding: '10px 16px',
                marginBottom: '1.5rem',
                display: 'flex',
                alignItems: 'center',
                gap: '12px',
                fontSize: '0.85rem',
                color: '#1e40af'
            }}>
                <Sparkles size={18} style={{ flexShrink: 0, color: '#3b82f6' }} />
                <span>
                    <strong>Automated 4-Year Graduation Rule:</strong> Students with enrollment year earlier than <strong>{currentYear - 4}</strong> are automatically marked as <strong>Expired</strong> upon registration and during daily maintenance. Admins can manually extend or expire access at any time using the action toggles below.
                </span>
            </div>

            {/* Filter and Search Bar */}
            <div style={{
                background: 'white',
                border: '1px solid var(--border)',
                borderRadius: '12px',
                padding: '16px',
                marginBottom: '1rem',
                display: 'flex',
                flexWrap: 'wrap',
                gap: '12px',
                alignItems: 'center',
                justifyContent: 'space-between'
            }}>
                {/* Search Box */}
                <div style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '8px',
                    background: '#f9fafb',
                    border: '1px solid var(--border)',
                    borderRadius: '8px',
                    padding: '8px 12px',
                    flex: '1 1 280px',
                    maxWidth: '400px'
                }}>
                    <Search size={18} style={{ color: 'var(--text-muted)' }} />
                    <input
                        type="text"
                        placeholder="Search by Student ID, Email, or Faculty..."
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        style={{
                            border: 'none',
                            background: 'transparent',
                            outline: 'none',
                            width: '100%',
                            fontSize: '0.875rem'
                        }}
                    />
                    {searchTerm && (
                        <button
                            onClick={() => setSearchTerm('')}
                            style={{ border: 'none', background: 'transparent', cursor: 'pointer', color: '#9ca3af' }}
                        >
                            <X size={16} />
                        </button>
                    )}
                </div>

                {/* Filters */}
                <div style={{ display: 'flex', gap: '10px', alignItems: 'center', flexWrap: 'wrap' }}>
                    {/* Status Filter */}
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                        <span style={{ fontSize: '0.85rem', color: 'var(--text-muted)', fontWeight: '500' }}>Status:</span>
                        <select
                            value={statusFilter}
                            onChange={(e) => {
                                setStatusFilter(e.target.value);
                                setCurrentPage(1);
                            }}
                            style={{
                                padding: '7px 12px',
                                borderRadius: '6px',
                                border: '1px solid var(--border)',
                                background: 'white',
                                fontSize: '0.85rem',
                                outline: 'none'
                            }}
                        >
                            <option value="All">All Statuses</option>
                            <option value="Active">Active Only</option>
                            <option value="Expired">Expired Only</option>
                        </select>
                    </div>

                    {/* Faculty Filter */}
                    {stats.faculties && stats.faculties.length > 0 && (
                        <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                            <span style={{ fontSize: '0.85rem', color: 'var(--text-muted)', fontWeight: '500' }}>Faculty:</span>
                            <select
                                value={facultyFilter}
                                onChange={(e) => {
                                    setFacultyFilter(e.target.value);
                                    setCurrentPage(1);
                                }}
                                style={{
                                    padding: '7px 12px',
                                    borderRadius: '6px',
                                    border: '1px solid var(--border)',
                                    background: 'white',
                                    fontSize: '0.85rem',
                                    outline: 'none'
                                }}
                            >
                                <option value="All">All Faculties</option>
                                {stats.faculties.map((fac) => (
                                    <option key={fac} value={fac}>{fac}</option>
                                ))}
                            </select>
                        </div>
                    )}

                    {/* Reset Filters */}
                    {(searchTerm || statusFilter !== 'All' || facultyFilter !== 'All') && (
                        <button
                            onClick={() => {
                                setSearchTerm('');
                                setStatusFilter('All');
                                setFacultyFilter('All');
                                setCurrentPage(1);
                            }}
                            style={{
                                display: 'flex',
                                alignItems: 'center',
                                gap: '4px',
                                background: '#f3f4f6',
                                border: 'none',
                                padding: '7px 12px',
                                borderRadius: '6px',
                                fontSize: '0.8rem',
                                color: '#4b5563',
                                cursor: 'pointer'
                            }}
                        >
                            <RotateCcw size={14} />
                            <span>Reset</span>
                        </button>
                    )}
                </div>
            </div>

            {/* Students Data Table */}
            <div style={{
                background: 'white',
                border: '1px solid var(--border)',
                borderRadius: '12px',
                overflow: 'hidden',
                boxShadow: '0 1px 3px rgba(0,0,0,0.05)'
            }}>
                <div style={{ overflowX: 'auto' }}>
                    <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '0.875rem' }}>
                        <thead>
                            <tr style={{ background: '#f9fafb', borderBottom: '1px solid var(--border)', color: 'var(--text-muted)' }}>
                                <th style={{ padding: '12px 16px', fontWeight: '600' }}>Student ID</th>
                                <th style={{ padding: '12px 16px', fontWeight: '600' }}>Campus Email</th>
                                <th style={{ padding: '12px 16px', fontWeight: '600' }}>Faculty</th>
                                <th style={{ padding: '12px 16px', fontWeight: '600' }}>Intake Year</th>
                                <th style={{ padding: '12px 16px', fontWeight: '600' }}>Tenure</th>
                                <th style={{ padding: '12px 16px', fontWeight: '600' }}>Status</th>
                                <th style={{ padding: '12px 16px', fontWeight: '600', textAlign: 'right' }}>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {loading ? (
                                <tr>
                                    <td colSpan={7} style={{ padding: '40px', textAlign: 'center', color: 'var(--text-muted)' }}>
                                        <div style={{ display: 'inline-block', width: '24px', height: '24px', border: '3px solid #f3f3f3', borderTop: '3px solid var(--primary)', borderRadius: '50%', animation: 'spin 1s linear infinite' }} />
                                        <div style={{ marginTop: '8px' }}>Loading student records...</div>
                                    </td>
                                </tr>
                            ) : students.length === 0 ? (
                                <tr>
                                    <td colSpan={7} style={{ padding: '40px', textAlign: 'center', color: 'var(--text-muted)' }}>
                                        <GraduationCap size={40} style={{ color: '#d1d5db', marginBottom: '8px' }} />
                                        <div style={{ fontWeight: '600', color: 'var(--text-main)' }}>No student records found</div>
                                        <p style={{ margin: '4px 0 0 0', fontSize: '0.8rem' }}>
                                            {searchTerm || statusFilter !== 'All' 
                                                ? 'Try adjusting your search criteria or filters.' 
                                                : 'Click "Upload CSV" to import university student records.'}
                                        </p>
                                    </td>
                                </tr>
                            ) : (
                                students.map((student) => {
                                    const tenureYears = currentYear - student.enrollment_year;
                                    const isOverTenure = tenureYears > 4;

                                    return (
                                        <tr key={student.id} style={{ borderBottom: '1px solid var(--border)', transition: 'background 0.15s' }}>
                                            {/* Student ID */}
                                            <td style={{ padding: '12px 16px' }}>
                                                <span style={{
                                                    fontFamily: 'monospace',
                                                    fontWeight: '700',
                                                    background: '#f3f4f6',
                                                    color: '#1f2937',
                                                    padding: '4px 8px',
                                                    borderRadius: '6px',
                                                    fontSize: '0.85rem'
                                                }}>
                                                    {student.student_id}
                                                </span>
                                            </td>

                                            {/* Email */}
                                            <td style={{ padding: '12px 16px' }}>
                                                <span style={{ fontWeight: '500', color: 'var(--text-main)' }}>
                                                    {student.email}
                                                </span>
                                            </td>

                                            {/* Faculty */}
                                            <td style={{ padding: '12px 16px' }}>
                                                <span style={{
                                                    background: '#e0f2fe',
                                                    color: '#0369a1',
                                                    padding: '3px 8px',
                                                    borderRadius: '6px',
                                                    fontSize: '0.75rem',
                                                    fontWeight: '600'
                                                }}>
                                                    {student.faculty || 'General'}
                                                </span>
                                            </td>

                                            {/* Enrollment Year */}
                                            <td style={{ padding: '12px 16px', color: 'var(--text-main)', fontWeight: '500' }}>
                                                {student.enrollment_year}
                                            </td>

                                            {/* Tenure */}
                                            <td style={{ padding: '12px 16px' }}>
                                                <span style={{
                                                    fontSize: '0.75rem',
                                                    fontWeight: '500',
                                                    color: isOverTenure ? '#b91c1c' : '#4b5563',
                                                    background: isOverTenure ? '#fee2e2' : '#f3f4f6',
                                                    padding: '2px 8px',
                                                    borderRadius: '4px',
                                                    display: 'inline-flex',
                                                    alignItems: 'center',
                                                    gap: '4px'
                                                }}>
                                                    {tenureYears} {tenureYears === 1 ? 'yr' : 'yrs'}
                                                    {isOverTenure && ' (Exceeded)'}
                                                </span>
                                            </td>

                                            {/* Status Badge */}
                                            <td style={{ padding: '12px 16px' }}>
                                                {student.status === 'Active' ? (
                                                    <span style={{
                                                        display: 'inline-flex',
                                                        alignItems: 'center',
                                                        gap: '4px',
                                                        background: '#dcfce7',
                                                        color: '#15803d',
                                                        padding: '4px 10px',
                                                        borderRadius: '20px',
                                                        fontSize: '0.75rem',
                                                        fontWeight: '600'
                                                    }}>
                                                        <CheckCircle2 size={13} />
                                                        Active
                                                    </span>
                                                ) : (
                                                    <span style={{
                                                        display: 'inline-flex',
                                                        alignItems: 'center',
                                                        gap: '4px',
                                                        background: '#fee2e2',
                                                        color: '#b91c1c',
                                                        padding: '4px 10px',
                                                        borderRadius: '20px',
                                                        fontSize: '0.75rem',
                                                        fontWeight: '600'
                                                    }}>
                                                        <XCircle size={13} />
                                                        Expired
                                                    </span>
                                                )}
                                            </td>

                                            {/* Action Buttons */}
                                            <td style={{ padding: '12px 16px', textAlign: 'right' }}>
                                                <div style={{ display: 'inline-flex', alignItems: 'center', gap: '8px' }}>
                                                    {/* Toggle Button */}
                                                    <button
                                                        onClick={() => handleToggleStatus(student)}
                                                        title={student.status === 'Active' ? 'Click to expire access' : 'Click to extend access'}
                                                        style={{
                                                            padding: '5px 12px',
                                                            borderRadius: '6px',
                                                            border: student.status === 'Active' ? '1px solid #fca5a5' : '1px solid #86efac',
                                                            background: student.status === 'Active' ? '#fff1f2' : '#f0fdf4',
                                                            color: student.status === 'Active' ? '#be123c' : '#15803d',
                                                            fontSize: '0.75rem',
                                                            fontWeight: '600',
                                                            cursor: 'pointer',
                                                            display: 'flex',
                                                            alignItems: 'center',
                                                            gap: '4px',
                                                            transition: 'all 0.15s'
                                                        }}
                                                    >
                                                        {student.status === 'Active' ? (
                                                            <>
                                                                <Clock size={13} />
                                                                <span>Expire</span>
                                                            </>
                                                        ) : (
                                                            <>
                                                                <RotateCcw size={13} />
                                                                <span>Extend</span>
                                                            </>
                                                        )}
                                                    </button>

                                                    {/* Delete Button */}
                                                    <button
                                                        onClick={() => handleDeleteStudent(student)}
                                                        title="Remove from whitelist"
                                                        style={{
                                                            padding: '5px',
                                                            borderRadius: '6px',
                                                            border: 'none',
                                                            background: 'transparent',
                                                            color: '#9ca3af',
                                                            cursor: 'pointer'
                                                        }}
                                                        onMouseEnter={(e) => e.currentTarget.style.color = '#ef4444'}
                                                        onMouseLeave={(e) => e.currentTarget.style.color = '#9ca3af'}
                                                    >
                                                        <Trash2 size={16} />
                                                    </button>
                                                </div>
                                            </td>
                                        </tr>
                                    );
                                })
                            )}
                        </tbody>
                    </table>
                </div>

                {/* Pagination Controls */}
                {!loading && totalCount > 0 && (
                    <div style={{ padding: '0 16px 12px 16px' }}>
                        <PaginationControls
                            currentPage={currentPage}
                            totalPages={totalPages}
                            pageSize={pageSize}
                            totalItems={totalCount}
                            onPageChange={(page) => setCurrentPage(page)}
                            onPageSizeChange={(size) => {
                                setPageSize(size);
                                setCurrentPage(1);
                            }}
                            sortBy={sortBy}
                            sortOptions={sortOptions}
                            onSortChange={(sort) => setSortBy(sort)}
                        />
                    </div>
                )}
            </div>

            {/* ========================================================================= */}
            {/* CSV UPLOAD MODAL */}
            {/* ========================================================================= */}
            {isUploadModalOpen && (
                <div style={{
                    position: 'fixed',
                    inset: 0,
                    backgroundColor: 'rgba(0, 0, 0, 0.5)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    zIndex: 1000,
                    padding: '16px'
                }}>
                    <div style={{
                        background: 'white',
                        borderRadius: '12px',
                        maxWidth: '560px',
                        width: '100%',
                        maxHeight: '90vh',
                        overflowY: 'auto',
                        padding: '24px',
                        boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)'
                    }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                <FileSpreadsheet size={22} style={{ color: 'var(--primary)' }} />
                                <h3 style={{ fontSize: '1.25rem', fontWeight: 'bold', margin: 0, color: 'var(--text-main)' }}>
                                    Upload Student Whitelist CSV
                                </h3>
                            </div>
                            <button
                                onClick={() => setIsUploadModalOpen(false)}
                                style={{ border: 'none', background: 'transparent', cursor: 'pointer', color: '#9ca3af' }}
                            >
                                <X size={20} />
                            </button>
                        </div>

                        {/* Format Instructions */}
                        <div style={{
                            background: '#f8fafc',
                            border: '1px solid #e2e8f0',
                            borderRadius: '8px',
                            padding: '12px 16px',
                            marginBottom: '16px',
                            fontSize: '0.85rem'
                        }}>
                            <div style={{ fontWeight: '600', color: '#334155', marginBottom: '4px' }}>
                                Required CSV Column Headers:
                            </div>
                            <code style={{ background: '#e2e8f0', padding: '2px 6px', borderRadius: '4px', color: '#0f172a', fontWeight: '600' }}>
                                student_id, email, faculty, enrollment_year
                            </code>
                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '10px' }}>
                                <span style={{ color: '#64748b', fontSize: '0.75rem' }}>
                                    Example: 24PMR01234, student@student.mmu.edu.my, FCI, 2024
                                </span>
                                <button
                                    onClick={handleDownloadTemplate}
                                    style={{
                                        border: 'none',
                                        background: 'transparent',
                                        color: 'var(--primary)',
                                        cursor: 'pointer',
                                        fontSize: '0.75rem',
                                        fontWeight: '600',
                                        display: 'flex',
                                        alignItems: 'center',
                                        gap: '4px'
                                    }}
                                >
                                    <Download size={13} />
                                    Download Template
                                </button>
                            </div>
                        </div>

                        {/* Dropzone */}
                        <form onSubmit={handleUploadCSV}>
                            <div
                                onDragOver={handleDragOver}
                                onDragLeave={handleDragLeave}
                                onDrop={handleDrop}
                                onClick={() => fileInputRef.current?.click()}
                                style={{
                                    border: isDragging ? '2px dashed var(--primary)' : '2px dashed #cbd5e1',
                                    background: isDragging ? '#f0fdfa' : '#fafafa',
                                    borderRadius: '10px',
                                    padding: '30px 20px',
                                    textAlign: 'center',
                                    cursor: 'pointer',
                                    marginBottom: '16px',
                                    transition: 'all 0.2s'
                                }}
                            >
                                <input
                                    type="file"
                                    ref={fileInputRef}
                                    onChange={handleFileChange}
                                    accept=".csv"
                                    style={{ display: 'none' }}
                                />
                                <UploadCloud size={38} style={{ color: isDragging ? 'var(--primary)' : '#94a3b8', margin: '0 auto 10px auto' }} />
                                {selectedFile ? (
                                    <div>
                                        <div style={{ fontWeight: '600', color: 'var(--text-main)', fontSize: '0.95rem' }}>
                                            {selectedFile.name}
                                        </div>
                                        <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: '2px' }}>
                                            {(selectedFile.size / 1024).toFixed(1)} KB • Click to choose another
                                        </div>
                                    </div>
                                ) : (
                                    <div>
                                        <div style={{ fontWeight: '600', color: 'var(--text-main)', fontSize: '0.9rem' }}>
                                            Click to browse or drag & drop CSV file
                                        </div>
                                        <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: '4px' }}>
                                            Only .csv format up to 10MB supported
                                        </div>
                                    </div>
                                )}
                            </div>

                            {/* Result Summary */}
                            {uploadResult && (
                                <div style={{
                                    padding: '12px 16px',
                                    borderRadius: '8px',
                                    marginBottom: '16px',
                                    background: uploadResult.success ? '#f0fdf4' : '#fef2f2',
                                    border: uploadResult.success ? '1px solid #bbf7d0' : '1px solid #fecaca',
                                    fontSize: '0.85rem'
                                }}>
                                    <div style={{
                                        fontWeight: '600',
                                        color: uploadResult.success ? '#15803d' : '#b91c1c',
                                        display: 'flex',
                                        alignItems: 'center',
                                        gap: '6px'
                                    }}>
                                        {uploadResult.success ? <CheckCircle2 size={16} /> : <AlertCircle size={16} />}
                                        <span>{uploadResult.message}</span>
                                    </div>

                                    {uploadResult.summary && (
                                        <div style={{ marginTop: '8px', fontSize: '0.8rem', color: '#374151' }}>
                                            <div><strong>Total processed:</strong> {uploadResult.summary.totalRows}</div>
                                            <div><strong>Newly inserted:</strong> {uploadResult.summary.inserted}</div>
                                            <div><strong>Updated:</strong> {uploadResult.summary.updated}</div>
                                            {uploadResult.summary.skipped > 0 && (
                                                <div style={{ color: '#b91c1c' }}>
                                                    <strong>Skipped:</strong> {uploadResult.summary.skipped}
                                                </div>
                                            )}
                                        </div>
                                    )}
                                </div>
                            )}

                            {/* Modal Action Buttons */}
                            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
                                <button
                                    type="button"
                                    onClick={() => setIsUploadModalOpen(false)}
                                    style={{
                                        padding: '9px 16px',
                                        borderRadius: '8px',
                                        border: '1px solid var(--border)',
                                        background: 'white',
                                        color: 'var(--text-main)',
                                        cursor: 'pointer',
                                        fontWeight: '500'
                                    }}
                                >
                                    Cancel
                                </button>
                                <button
                                    type="submit"
                                    disabled={!selectedFile || isUploading}
                                    style={{
                                        padding: '9px 20px',
                                        borderRadius: '8px',
                                        border: 'none',
                                        background: 'var(--primary, #00695C)',
                                        color: 'white',
                                        fontWeight: '600',
                                        cursor: (!selectedFile || isUploading) ? 'not-allowed' : 'pointer',
                                        opacity: (!selectedFile || isUploading) ? 0.6 : 1,
                                        display: 'flex',
                                        alignItems: 'center',
                                        gap: '8px'
                                    }}
                                >
                                    {isUploading ? (
                                        <>
                                            <div style={{ width: '14px', height: '14px', border: '2px solid white', borderTop: '2px solid transparent', borderRadius: '50%', animation: 'spin 1s linear infinite' }} />
                                            <span>Processing...</span>
                                        </>
                                    ) : (
                                        <>
                                            <UploadCloud size={16} />
                                            <span>Import Whitelist</span>
                                        </>
                                    )}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* ========================================================================= */}
            {/* ADD SINGLE STUDENT MODAL */}
            {/* ========================================================================= */}
            {isAddModalOpen && (
                <div style={{
                    position: 'fixed',
                    inset: 0,
                    backgroundColor: 'rgba(0, 0, 0, 0.5)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    zIndex: 1000,
                    padding: '16px'
                }}>
                    <div style={{
                        background: 'white',
                        borderRadius: '12px',
                        maxWidth: '480px',
                        width: '100%',
                        padding: '24px',
                        boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1)'
                    }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                <UserPlus size={20} style={{ color: 'var(--primary)' }} />
                                <h3 style={{ fontSize: '1.2rem', fontWeight: 'bold', margin: 0, color: 'var(--text-main)' }}>
                                    Add Student to Whitelist
                                </h3>
                            </div>
                            <button
                                onClick={() => setIsAddModalOpen(false)}
                                style={{ border: 'none', background: 'transparent', cursor: 'pointer', color: '#9ca3af' }}
                            >
                                <X size={20} />
                            </button>
                        </div>

                        <form onSubmit={handleAddStudentSubmit}>
                            <div style={{ display: 'flex', flexDirection: 'column', gap: '14px', marginBottom: '20px' }}>
                                {/* Student ID */}
                                <div>
                                    <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: '600', color: 'var(--text-main)', marginBottom: '4px' }}>
                                        Student / University ID *
                                    </label>
                                    <input
                                        type="text"
                                        required
                                        placeholder="e.g. 24PMR01234"
                                        value={newStudentForm.student_id}
                                        onChange={(e) => setNewStudentForm({ ...newStudentForm, student_id: e.target.value })}
                                        style={{
                                            width: '100%',
                                            padding: '8px 12px',
                                            borderRadius: '6px',
                                            border: '1px solid var(--border)',
                                            fontSize: '0.875rem',
                                            outline: 'none',
                                            textTransform: 'uppercase'
                                        }}
                                    />
                                </div>

                                {/* Email */}
                                <div>
                                    <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: '600', color: 'var(--text-main)', marginBottom: '4px' }}>
                                        Student Email (.edu.my) *
                                    </label>
                                    <input
                                        type="email"
                                        required
                                        placeholder="e.g. student@student.mmu.edu.my"
                                        value={newStudentForm.email}
                                        onChange={(e) => setNewStudentForm({ ...newStudentForm, email: e.target.value })}
                                        style={{
                                            width: '100%',
                                            padding: '8px 12px',
                                            borderRadius: '6px',
                                            border: '1px solid var(--border)',
                                            fontSize: '0.875rem',
                                            outline: 'none'
                                        }}
                                    />
                                </div>

                                {/* Faculty */}
                                <div>
                                    <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: '600', color: 'var(--text-main)', marginBottom: '4px' }}>
                                        Faculty / Department
                                    </label>
                                    <input
                                        type="text"
                                        placeholder="e.g. FCI, FOE, FCM, FOM"
                                        value={newStudentForm.faculty}
                                        onChange={(e) => setNewStudentForm({ ...newStudentForm, faculty: e.target.value })}
                                        style={{
                                            width: '100%',
                                            padding: '8px 12px',
                                            borderRadius: '6px',
                                            border: '1px solid var(--border)',
                                            fontSize: '0.875rem',
                                            outline: 'none'
                                        }}
                                    />
                                </div>

                                {/* Enrollment Year */}
                                <div>
                                    <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: '600', color: 'var(--text-main)', marginBottom: '4px' }}>
                                        Enrollment Year *
                                    </label>
                                    <input
                                        type="number"
                                        required
                                        min={1990}
                                        max={2100}
                                        value={newStudentForm.enrollment_year}
                                        onChange={(e) => setNewStudentForm({ ...newStudentForm, enrollment_year: parseInt(e.target.value, 10) || currentYear })}
                                        style={{
                                            width: '100%',
                                            padding: '8px 12px',
                                            borderRadius: '6px',
                                            border: '1px solid var(--border)',
                                            fontSize: '0.875rem',
                                            outline: 'none'
                                        }}
                                    />
                                    <span style={{ fontSize: '0.75rem', color: '#6b7280', marginTop: '2px', display: 'block' }}>
                                        {currentYear - newStudentForm.enrollment_year > 4 ? (
                                            <span style={{ color: '#dc2626' }}>Over 4 years tenure &mdash; will automatically expire.</span>
                                        ) : (
                                            <span style={{ color: '#16a34a' }}>Valid student tenure &mdash; active access.</span>
                                        )}
                                    </span>
                                </div>

                                {/* Status */}
                                <div>
                                    <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: '600', color: 'var(--text-main)', marginBottom: '4px' }}>
                                        Access Status
                                    </label>
                                    <select
                                        value={newStudentForm.status}
                                        onChange={(e) => setNewStudentForm({ ...newStudentForm, status: e.target.value })}
                                        style={{
                                            width: '100%',
                                            padding: '8px 12px',
                                            borderRadius: '6px',
                                            border: '1px solid var(--border)',
                                            fontSize: '0.875rem',
                                            outline: 'none',
                                            background: 'white'
                                        }}
                                    >
                                        <option value="Active">Active</option>
                                        <option value="Expired">Expired</option>
                                    </select>
                                </div>
                            </div>

                            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
                                <button
                                    type="button"
                                    onClick={() => setIsAddModalOpen(false)}
                                    style={{
                                        padding: '8px 14px',
                                        borderRadius: '6px',
                                        border: '1px solid var(--border)',
                                        background: 'white',
                                        cursor: 'pointer'
                                    }}
                                >
                                    Cancel
                                </button>
                                <button
                                    type="submit"
                                    disabled={isSubmittingAdd}
                                    style={{
                                        padding: '8px 18px',
                                        borderRadius: '6px',
                                        border: 'none',
                                        background: 'var(--primary, #00695C)',
                                        color: 'white',
                                        fontWeight: '600',
                                        cursor: isSubmittingAdd ? 'not-allowed' : 'pointer'
                                    }}
                                >
                                    {isSubmittingAdd ? 'Saving...' : 'Add to Whitelist'}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
};

export default StudentDirectory;
