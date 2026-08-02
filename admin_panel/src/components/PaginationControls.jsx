import React, { useState } from 'react';
import { ChevronLeft, ChevronRight, ChevronsLeft, ChevronsRight, ArrowUpDown } from 'lucide-react';

const PaginationControls = ({
    currentPage = 1,
    totalPages = 1,
    pageSize = 10,
    totalItems = 0,
    pageSizeOptions = [10, 20, 50, 100],
    onPageChange,
    onPageSizeChange,
    sortBy = '',
    sortOptions = [],
    onSortChange
}) => {
    const [jumpInput, setJumpInput] = useState('');

    const handleJumpSubmit = (e) => {
        e.preventDefault();
        const pageNum = parseInt(jumpInput, 10);
        if (!isNaN(pageNum) && pageNum >= 1 && pageNum <= totalPages) {
            onPageChange(pageNum);
            setJumpInput('');
        } else {
            alert(`Please enter a valid page number between 1 and ${totalPages}`);
        }
    };

    const startItem = totalItems === 0 ? 0 : (currentPage - 1) * pageSize + 1;
    const endItem = Math.min(currentPage * pageSize, totalItems);

    return (
        <div style={{
            display: 'flex',
            flexWrap: 'wrap',
            alignItems: 'center',
            justifyContent: 'space-between',
            gap: '12px',
            padding: '12px 16px',
            background: 'white',
            border: '1px solid var(--border)',
            borderRadius: '8px',
            marginTop: '1rem'
        }}>
            {/* Left Section: Items info & Page Size Selector */}
            <div style={{ display: 'flex', alignItems: 'center', gap: '16px', flexWrap: 'wrap' }}>
                <span style={{ fontSize: '0.85rem', color: 'var(--text-muted)', fontWeight: '500' }}>
                    Showing <strong style={{ color: 'var(--text-main)' }}>{startItem}–{endItem}</strong> of <strong style={{ color: 'var(--text-main)' }}>{totalItems}</strong> items
                </span>

                <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <label style={{ fontSize: '0.85rem', color: 'var(--text-muted)', fontWeight: '500' }}>Rows per page:</label>
                    <select
                        value={pageSize}
                        onChange={(e) => onPageSizeChange(Number(e.target.value))}
                        style={{
                            padding: '4px 8px',
                            borderRadius: '6px',
                            border: '1px solid var(--border)',
                            background: 'white',
                            fontSize: '0.85rem',
                            outline: 'none',
                            cursor: 'pointer'
                        }}
                    >
                        {pageSizeOptions.map(size => (
                            <option key={size} value={size}>{size}</option>
                        ))}
                    </select>
                </div>
            </div>

            {/* Middle/Right Section: Sorting & Page Jump & Nav */}
            <div style={{ display: 'flex', alignItems: 'center', gap: '16px', flexWrap: 'wrap' }}>
                {/* Sort Option Dropdown (if options provided) */}
                {sortOptions.length > 0 && onSortChange && (
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                        <ArrowUpDown size={14} color="var(--text-muted)" />
                        <select
                            value={sortBy}
                            onChange={(e) => onSortChange(e.target.value)}
                            style={{
                                padding: '4px 8px',
                                borderRadius: '6px',
                                border: '1px solid var(--border)',
                                background: 'white',
                                fontSize: '0.85rem',
                                outline: 'none',
                                cursor: 'pointer'
                            }}
                        >
                            {sortOptions.map(opt => (
                                <option key={opt.value} value={opt.value}>{opt.label}</option>
                            ))}
                        </select>
                    </div>
                )}

                {/* Jump to Page Form */}
                <form onSubmit={handleJumpSubmit} style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <span style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>Go to:</span>
                    <input
                        type="number"
                        min="1"
                        max={totalPages}
                        value={jumpInput}
                        onChange={(e) => setJumpInput(e.target.value)}
                        placeholder={`1-${totalPages}`}
                        style={{
                            width: '60px',
                            padding: '4px 8px',
                            borderRadius: '6px',
                            border: '1px solid var(--border)',
                            fontSize: '0.85rem',
                            textAlign: 'center',
                            outline: 'none'
                        }}
                    />
                    <button
                        type="submit"
                        className="btn btn-outline"
                        style={{ padding: '4px 10px', fontSize: '0.8rem', height: '30px' }}
                    >
                        Go
                    </button>
                </form>

                {/* Navigation Controls */}
                <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                    <button
                        className="btn btn-outline"
                        style={{ padding: '4px 8px', height: '32px' }}
                        disabled={currentPage <= 1}
                        onClick={() => onPageChange(1)}
                        title="First Page"
                    >
                        <ChevronsLeft size={16} />
                    </button>
                    <button
                        className="btn btn-outline"
                        style={{ padding: '4px 8px', height: '32px' }}
                        disabled={currentPage <= 1}
                        onClick={() => onPageChange(currentPage - 1)}
                        title="Previous Page"
                    >
                        <ChevronLeft size={16} />
                    </button>

                    <span style={{ fontSize: '0.85rem', fontWeight: 'bold', margin: '0 6px', color: 'var(--primary)' }}>
                        Page {currentPage} of {totalPages || 1}
                    </span>

                    <button
                        className="btn btn-outline"
                        style={{ padding: '4px 8px', height: '32px' }}
                        disabled={currentPage >= totalPages}
                        onClick={() => onPageChange(currentPage + 1)}
                        title="Next Page"
                    >
                        <ChevronRight size={16} />
                    </button>
                    <button
                        className="btn btn-outline"
                        style={{ padding: '4px 8px', height: '32px' }}
                        disabled={currentPage >= totalPages}
                        onClick={() => onPageChange(totalPages)}
                        title="Last Page"
                    >
                        <ChevronsRight size={16} />
                    </button>
                </div>
            </div>
        </div>
    );
};

export default PaginationControls;
