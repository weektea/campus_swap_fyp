import React from 'react';
import { Flame } from 'lucide-react';

const Dispute = () => {
    return (
        <div>
            <div style={{ background: '#fff7ed', padding: '16px 32px', margin: '-2rem -2rem 2rem -2rem', display: 'flex', alignItems: 'center', gap: '12px', color: '#ea580c', fontWeight: 'bold' }}>
                <Flame size={20} />
                <span>ESCALATED DISPUTE: Requires Admin Final Arbitration</span>
            </div>

            <div className="flex gap-8 items-start">
                <div style={{ flex: 3 }} className="flex-col gap-8">
                    {/* Notes */}
                    <div style={{ background: '#f8fafc', padding: '1.5rem', borderRadius: '16px' }}>
                        <div style={{ fontSize: '0.75rem', fontWeight: 'bold', color: '#64748b', letterSpacing: '1px', marginBottom: '1rem' }}>
                            MODERATOR NOTES
                        </div>
                        <p style={{ margin: 0, lineHeight: 1.6 }}>
                            Unable to verify item condition from provided evidence. Both parties have conflicting claims with supporting documentation. Escalating to Admin for final decision.
                        </p>
                    </div>

                    {/* Timeline */}
                    <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
                        <div style={{ padding: '1.5rem', borderBottom: '1px solid var(--border)' }}>
                            <h2 style={{ margin: 0, fontSize: '1.25rem' }}>Dispute Timeline</h2>
                        </div>
                        
                        <div style={{ padding: '1.5rem' }}>
                            <div className="mb-6">
                                <div style={{ fontSize: '0.75rem', color: '#64748b', marginBottom: '4px' }}>Oct 15, 2026 - 2:45 PM</div>
                                <div style={{ fontWeight: 'bold', marginBottom: '4px' }}>Buyer initiated dispute</div>
                                <div style={{ color: 'var(--text-muted)' }}>"Received broken textbook with missing pages. Not as described."</div>
                            </div>
                            
                            <div className="mb-8">
                                <div style={{ fontSize: '0.75rem', color: '#64748b', marginBottom: '4px' }}>Oct 15, 2026 - 4:20 PM</div>
                                <div style={{ fontWeight: 'bold', marginBottom: '4px' }}>Seller response</div>
                                <div style={{ color: 'var(--text-muted)' }}>"Book was in perfect condition when shipped. Provided photos from before shipping."</div>
                            </div>

                            <div style={{ background: '#f8fafc', padding: '1rem', borderRadius: '12px' }}>
                                <div style={{ fontSize: '0.75rem', fontWeight: 'bold', color: '#64748b', letterSpacing: '1px', marginBottom: '1rem' }}>
                                    CHAT LOGS
                                </div>
                                <div style={{ marginBottom: '8px' }}>
                                    <span style={{ color: '#2563eb', fontWeight: 'bold' }}>@buyer: </span>
                                    <span>The book arrived damaged</span>
                                </div>
                                <div style={{ marginBottom: '8px' }}>
                                    <span style={{ color: '#16a34a', fontWeight: 'bold' }}>@seller: </span>
                                    <span>I packaged it carefully with bubble wrap</span>
                                </div>
                                <div>
                                    <span style={{ color: '#2563eb', fontWeight: 'bold' }}>@buyer: </span>
                                    <span>Pages 45-60 are completely torn out</span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div style={{ flex: 2 }} className="flex-col gap-6">
                    <div className="card">
                        <h3 style={{ margin: '0 0 1.5rem 0', fontSize: '1rem' }}>Financial Resolution</h3>
                        <div className="flex gap-4">
                            <button className="flex-1 btn" style={{ background: '#2563eb', padding: '1.5rem 0' }}>
                                <div>Force Refund</div>
                                <div style={{ fontSize: '0.75rem', fontWeight: 'normal', opacity: 0.8 }}>(Buyer)</div>
                            </button>
                            <button className="flex-1 btn" style={{ background: '#16a34a', padding: '1.5rem 0' }}>
                                <div>Release Funds</div>
                                <div style={{ fontSize: '0.75rem', fontWeight: 'normal', opacity: 0.8 }}>(Seller)</div>
                            </button>
                        </div>
                    </div>

                    <div className="card" style={{ background: '#fef2f2', borderColor: '#fecaca' }}>
                        <h3 style={{ margin: '0 0 1rem 0', fontSize: '1rem', color: '#b91c1c' }}>Punitive Actions</h3>
                        
                        <label className="flex items-center gap-3" style={{ marginBottom: '12px', cursor: 'pointer' }}>
                            <input type="checkbox" style={{ width: '16px', height: '16px' }} />
                            <span>Ban @student_seller</span>
                        </label>
                        
                        <label className="flex items-center gap-3" style={{ cursor: 'pointer' }}>
                            <input type="checkbox" style={{ width: '16px', height: '16px' }} />
                            <span>Ban @student_buyer</span>
                        </label>
                    </div>

                    <button className="btn" style={{ background: '#991b1b', padding: '1rem', fontSize: '1rem' }}>
                        Execute Admin Decision
                    </button>
                </div>
            </div>
        </div>
    );
};

export default Dispute;
