import React from 'react';
import { Lock, AlertTriangle } from 'lucide-react';

const Triage = () => {
    return (
        <div>
            <div style={{ background: '#e8f5e9', padding: '12px 32px', margin: '-2rem -2rem 2rem -2rem', display: 'flex', alignItems: 'center', gap: '8px', color: '#2e7d32', fontWeight: 'bold' }}>
                <Lock size={18} />
                <span>Ticket #REP-102 is currently locked by you.</span>
            </div>

            <div className="flex gap-8 items-start">
                {/* Left Column */}
                <div className="card" style={{ flex: 3, padding: 0, overflow: 'hidden' }}>
                    <div style={{ padding: '1.5rem', borderBottom: '1px solid var(--border)' }}>
                        <h2 style={{ margin: 0, fontSize: '1.25rem' }}>Reported Content Snapshot</h2>
                    </div>
                    
                    <div style={{ padding: '1.5rem' }}>
                        <div className="flex gap-6 mb-6">
                            <div style={{ width: '120px', height: '120px', background: '#f3f4f6', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#9ca3af' }}>
                                Chair Image
                            </div>
                            <div>
                                <h3 style={{ margin: '0 0 8px 0', fontSize: '1.25rem' }}>Vintage Wooden Chair</h3>
                                <div style={{ color: 'var(--text-muted)', marginBottom: '4px' }}>Price: RM 45</div>
                                <div style={{ color: 'var(--text-muted)' }}>Seller: @student_seller</div>
                            </div>
                        </div>

                        <p style={{ color: 'var(--text-muted)', lineHeight: 1.6, marginBottom: '2rem' }}>
                            Beautiful vintage wooden chair in excellent condition. Perfect for study or dining. Sturdy construction with minor wear consistent with age.
                        </p>

                        <div className="flex gap-4 items-start mb-4">
                            <AlertTriangle color="var(--danger)" />
                            <div>
                                <span style={{ fontWeight: 'bold' }}>Reporter's Claim: </span>
                                <span>Item is completely broken, not as described. Chair leg is cracked and unusable.</span>
                            </div>
                        </div>

                        <div style={{ width: '150px', height: '150px', background: '#e5e7eb', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#6b7280', textAlign: 'center', padding: '1rem' }}>
                            Evidence Photo: Broken Chair Leg
                        </div>
                    </div>
                </div>

                {/* Right Column */}
                <div className="card" style={{ flex: 2 }}>
                    <h2 style={{ margin: '0 0 2rem 0', fontSize: '1.25rem' }}>Moderation Terminal</h2>
                    
                    <div style={{ marginBottom: '1.5rem' }}>
                        <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-muted)', fontSize: '0.875rem' }}>Select Violation Category</label>
                        <select className="input" style={{ marginBottom: 0, appearance: 'auto' }}>
                            <option>Item Condition Misrepresented</option>
                            <option>Fake Item</option>
                            <option>Scam</option>
                            <option>Inappropriate Content</option>
                        </select>
                    </div>

                    <div style={{ marginBottom: '2rem' }}>
                        <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-muted)', fontSize: '0.875rem' }}>Internal Mod Notes</label>
                        <textarea 
                            className="input" 
                            rows="6" 
                            placeholder="Document your findings and reasoning..."
                            style={{ resize: 'vertical' }}
                        ></textarea>
                    </div>

                    <button className="btn btn-outline" style={{ width: '100%', marginBottom: '12px' }}>
                        Dismiss Report
                    </button>
                    
                    <button className="btn btn-danger" style={{ width: '100%' }}>
                        Uphold & Suspend Listing
                    </button>
                </div>
            </div>
        </div>
    );
};

export default Triage;
