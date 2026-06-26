import React, { useState, useEffect } from 'react';
import { BrainCircuit, Image as ImageIcon, Sparkles, CheckCircle2, History, RotateCcw, ArrowUpRight, ArrowDownRight } from 'lucide-react';
import { LineChart, Line, BarChart, Bar, XAxis, YAxis, ResponsiveContainer, Tooltip } from 'recharts';
import api from '../services/api';

const MLModels = () => {
    // ----------------------------------------------------------------
    // Image Model (True MLOps Pipeline connected to Python Backend)
    // ----------------------------------------------------------------
    const [isTrainingImage, setIsTrainingImage] = useState(false);
    const [isRollingBackImage, setIsRollingBackImage] = useState(false);
    const [imageHistory, setImageHistory] = useState([
        { version: 'v1.0.0', accuracy: '0.0%', precision: '0.0%', recall: '0.0%', latency: '0ms', dataset_size: 0, classes: '-' }
    ]);
    const [imagePending, setImagePending] = useState(0);
    const [imageTrainedCount, setImageTrainedCount] = useState(0);

    const fetchImageMetrics = async () => {
        try {
            const res = await fetch('http://localhost:5000/admin/ml-metrics');
            if (res.ok) {
                const data = await res.json();
                if (data.history && data.history.length > 0) {
                    setImageHistory(data.history);
                }
                setImagePending(data.pending_samples);
                // Safe check just in case history is empty
                const latestSize = data.history && data.history.length > 0 ? data.history[data.history.length - 1].dataset_size : 0;
                setImageTrainedCount(latestSize);
            }
        } catch (e) {
            console.error("Failed to fetch ML metrics:", e);
        }
    };

    useEffect(() => {
        fetchImageMetrics();
        const intervalId = setInterval(fetchImageMetrics, 3000); // Poll every 3 seconds
        return () => clearInterval(intervalId);
    }, []);

    const [mlDashboardData, setMlDashboardData] = useState(null);
    const [loadingDashboard, setLoadingDashboard] = useState(true);

    const fetchMlDashboardData = async () => {
        try {
            const res = await api.get('/admin/ml-dashboard');
            setMlDashboardData(res.data);
            setLoadingDashboard(false);
        } catch (e) {
            console.error("Failed to fetch ML Dashboard metrics:", e);
        }
    };

    useEffect(() => {
        fetchMlDashboardData();
        const intervalId = setInterval(fetchMlDashboardData, 10000); // Poll every 10 seconds
        return () => clearInterval(intervalId);
    }, []);

    // ----------------------------------------------------------------
    // Feed Model (Mock Pipeline)
    // ----------------------------------------------------------------
    const [isTrainingFeed, setIsTrainingFeed] = useState(false);
    const [feedVersion, setFeedVersion] = useState("v2.0.1");
    const [feedCTR, setFeedCTR] = useState("12.8%");
    const [feedInteractions, setFeedInteractions] = useState(15203);
    const [feedTrainedCount, setFeedTrainedCount] = useState(48200);
    const [feedHistory, setFeedHistory] = useState([
        { version: 'v1.9.0', ctr: 10.5 },
        { version: 'v1.9.5', ctr: 11.2 },
        { version: 'v2.0.0', ctr: 12.0 },
        { version: 'v2.0.1', ctr: 12.8 },
    ]);
    
    const [notification, setNotification] = useState(null);

    const showNotification = (msg) => {
        setNotification(msg);
        setTimeout(() => setNotification(null), 5000);
    };

    const handleRetrainImage = async () => {
        if (!window.confirm("Are you sure you want to retrain the Image Model with the pending dataset? This will trigger the actual Python PyTorch pipeline in the background.")) return;
        setIsTrainingImage(true);
        
        try {
            const response = await fetch('http://localhost:5000/train/image-model', {
                method: 'POST'
            });
            
            if (response.ok) {
                showNotification("Background PyTorch training started! Real-time metrics will update automatically upon completion.");
                // The polling mechanism will automatically pick up the new metrics once training finishes.
                // We keep it in 'training' state visually for a bit just to prevent spam clicks.
                setTimeout(() => setIsTrainingImage(false), 3000); 
            } else {
                throw new Error("Server error");
            }
        } catch (error) {
            console.error(error);
            alert("Failed to connect to ML Service on port 5000. Is the Python server running?");
            setIsTrainingImage(false);
        }
    };

    const handleRollbackImage = async () => {
        if (!window.confirm("Rollback logic is currently disabled in True MLOps mode. Wait for next release.")) return;
        // In a real app, this would call a DELETE /admin/ml-metrics or /train/rollback endpoint.
    };

    const handleRetrainFeed = async () => {
        if (!window.confirm("Are you sure you want to update the Recommendation Engine weights?")) return;
        setIsTrainingFeed(true);
        await new Promise(r => setTimeout(r, 2000));
        setIsTrainingFeed(false);
        setFeedVersion("v2.0.2");
        setFeedCTR("13.1%");
        setFeedTrainedCount(prev => prev + feedInteractions);
        setFeedInteractions(0);
        setFeedHistory(prev => [...prev, { version: 'v2.0.2', ctr: 13.1 }]);
        showNotification("Recommendation Engine weights updated to v2.0.2!");
    };

    // Derived values for Image Model UI
    const latestImageMetric = imageHistory[imageHistory.length - 1];
    const prevImageMetric = imageHistory.length > 1 ? imageHistory[imageHistory.length - 2] : null;
    
    const imageChartData = imageHistory.map(h => ({
        version: h.version,
        accuracy: parseFloat(h.accuracy) || 0
    }));

    // Diff Calculation for Table
    const parseMetric = (valStr) => parseFloat(String(valStr).replace(/[^0-9.-]+/g, "")) || 0;
    
    const getComparisonMetrics = () => {
        if (!prevImageMetric) {
            return {
                current: latestImageMetric,
                previous: { version: '-', accuracy: '-', precision: '-', recall: '-', latency: '-', classes: '-' },
                diffs: { accuracy: 0, precision: 0, recall: 0, latency: 0 }
            };
        }
        
        return {
            current: latestImageMetric,
            previous: prevImageMetric,
            diffs: {
                accuracy: parseMetric(latestImageMetric.accuracy) - parseMetric(prevImageMetric.accuracy),
                precision: parseMetric(latestImageMetric.precision) - parseMetric(prevImageMetric.precision),
                recall: parseMetric(latestImageMetric.recall) - parseMetric(prevImageMetric.recall),
                latency: parseMetric(latestImageMetric.latency) - parseMetric(prevImageMetric.latency)
            }
        };
    };

    const metrics = getComparisonMetrics();

    const renderDiffIndicator = (value) => {
        if (value === 0) return null;
        const isPositive = value > 0;
        
        return (
            <span style={{ 
                display: 'inline-flex', alignItems: 'center', fontSize: '0.75rem', 
                color: isPositive ? '#16a34a' : '#ef4444', 
                background: isPositive ? '#dcfce7' : '#fee2e2',
                padding: '2px 6px', borderRadius: '4px', marginLeft: '8px', fontWeight: 'bold'
            }}>
                {isPositive ? <ArrowUpRight size={12} style={{marginRight: '2px'}}/> : <ArrowDownRight size={12} style={{marginRight: '2px'}}/>}
                {Math.abs(value).toFixed(1)}
            </span>
        );
    };

    return (
        <div>
            <div className="flex justify-between items-center mb-8">
                <div>
                    <h1 style={{ fontSize: '1.5rem', margin: '0 0 8px 0' }}>ML Models Management</h1>
                    <p style={{ margin: 0, color: 'var(--text-muted)' }}>Monitor versioning, track performance history, and manage continuous learning pipelines.</p>
                </div>
            </div>

            {notification && (
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', padding: '16px', background: '#dcfce7', color: '#166534', borderRadius: '8px', marginBottom: '24px', border: '1px solid #bbf7d0', animation: 'fadeIn 0.3s ease' }}>
                    <CheckCircle2 size={20} />
                    <span>{notification}</span>
                </div>
            )}

            <div className="flex gap-6 mb-8">
                {/* Image Classification Model Card (TRUE MLOPS) */}
                <div className="card flex-1" style={{ display: 'flex', flexDirection: 'column' }}>
                    <div className="flex justify-between items-start mb-6">
                        <div className="flex items-center gap-4">
                            <div style={{ padding: '12px', background: '#eff6ff', borderRadius: '12px' }}>
                                <ImageIcon size={24} color="#3b82f6" />
                            </div>
                            <div>
                                <h2 style={{ fontSize: '1.125rem', margin: 0, fontWeight: 'bold' }}>Automated Image Analysis</h2>
                                <p style={{ margin: 0, color: 'var(--text-muted)', fontSize: '0.875rem' }}>Smart Product Listing</p>
                            </div>
                        </div>
                        <div style={{ textAlign: 'right' }}>
                            <div style={{ padding: '4px 12px', background: '#dcfce7', color: '#16a34a', borderRadius: '999px', fontSize: '0.75rem', fontWeight: 'bold', display: 'inline-block', marginBottom: '4px' }}>
                                Active
                            </div>
                            <div style={{ fontSize: '0.875rem', color: 'var(--text-muted)', fontWeight: 'bold' }}>{latestImageMetric.version}</div>
                        </div>
                    </div>

                    <div style={{ display: 'flex', flexDirection: 'column', gap: '16px', flex: 1 }}>
                        <div className="flex justify-between items-center">
                            <span style={{ color: 'var(--text-muted)' }}>Current Accuracy</span>
                            <div className="flex items-center gap-2">
                                <div style={{ width: '60px', height: '24px' }}>
                                    <ResponsiveContainer width="100%" height="100%">
                                        <LineChart data={imageChartData}>
                                            <YAxis domain={['auto', 'auto']} hide />
                                            <Line type="monotone" dataKey="accuracy" stroke="#16a34a" strokeWidth={2} dot={false} />
                                        </LineChart>
                                    </ResponsiveContainer>
                                </div>
                                <span style={{ fontWeight: 'bold', fontSize: '1.125rem' }}>{latestImageMetric.accuracy}</span>
                            </div>
                        </div>
                        <div className="flex justify-between items-center">
                            <span style={{ color: 'var(--text-muted)' }}>Total Dataset Size</span>
                            <span style={{ fontWeight: '500', fontSize: '1rem' }}>{imageTrainedCount.toLocaleString()} images</span>
                        </div>
                        <div className="flex justify-between items-center">
                            <span style={{ color: 'var(--text-muted)' }}>Pending Verified Samples</span>
                            <span style={{ fontWeight: 'bold', fontSize: '1.125rem', color: imagePending > 0 ? '#d97706' : '#111827' }}>+{imagePending.toLocaleString()}</span>
                        </div>
                    </div>

                    <div className="flex gap-4" style={{ marginTop: '32px' }}>
                        <button 
                            onClick={handleRetrainImage}
                            disabled={isTrainingImage || imagePending === 0}
                            className="btn btn-primary flex-1"
                            style={{ padding: '12px', display: 'flex', justifyContent: 'center', alignItems: 'center', gap: '8px', transition: 'all 0.2s' }}
                        >
                            {isTrainingImage ? (
                                <span>Triggering Backend...</span>
                            ) : (
                                <>
                                    <BrainCircuit size={18} />
                                    <span>Retrain & Deploy</span>
                                </>
                            )}
                        </button>
                        <button 
                            onClick={handleRollbackImage}
                            disabled={imageHistory.length <= 1}
                            className="btn btn-secondary"
                            style={{ padding: '12px', display: 'flex', justifyContent: 'center', alignItems: 'center', gap: '8px' }}
                            title="Rollback to previous version"
                        >
                            <RotateCcw size={18} />
                        </button>
                    </div>
                </div>

                {/* Recommendation Engine Card (MOCKED) */}
                <div className="card flex-1" style={{ display: 'flex', flexDirection: 'column' }}>
                    <div className="flex justify-between items-start mb-6">
                        <div className="flex items-center gap-4">
                            <div style={{ padding: '12px', background: '#f5f3ff', borderRadius: '12px' }}>
                                <Sparkles size={24} color="#8b5cf6" />
                            </div>
                            <div>
                                <h2 style={{ fontSize: '1.125rem', margin: 0, fontWeight: 'bold' }}>Recommendation Engine</h2>
                                <p style={{ margin: 0, color: 'var(--text-muted)', fontSize: '0.875rem' }}>Personalized Feed (For You)</p>
                            </div>
                        </div>
                        <div style={{ textAlign: 'right' }}>
                            <div style={{ padding: '4px 12px', background: '#dcfce7', color: '#16a34a', borderRadius: '999px', fontSize: '0.75rem', fontWeight: 'bold', display: 'inline-block', marginBottom: '4px' }}>
                                Active
                            </div>
                            <div style={{ fontSize: '0.875rem', color: 'var(--text-muted)', fontWeight: 'bold' }}>{feedVersion}</div>
                        </div>
                    </div>

                    <div style={{ display: 'flex', flexDirection: 'column', gap: '16px', flex: 1 }}>
                        <div className="flex justify-between items-center">
                            <span style={{ color: 'var(--text-muted)' }}>Click-Through Rate (CTR)</span>
                            <div className="flex items-center gap-2">
                                <div style={{ width: '60px', height: '24px' }}>
                                    <ResponsiveContainer width="100%" height="100%">
                                        <LineChart data={feedHistory}>
                                            <YAxis domain={['auto', 'auto']} hide />
                                            <Line type="monotone" dataKey="ctr" stroke="#8b5cf6" strokeWidth={2} dot={false} />
                                        </LineChart>
                                    </ResponsiveContainer>
                                </div>
                                <span style={{ fontWeight: 'bold', fontSize: '1.125rem' }}>{feedCTR}</span>
                            </div>
                        </div>
                        <div className="flex justify-between items-center">
                            <span style={{ color: 'var(--text-muted)' }}>Historical Interactions</span>
                            <span style={{ fontWeight: '500', fontSize: '1rem' }}>{feedTrainedCount.toLocaleString()} clicks</span>
                        </div>
                        <div className="flex justify-between items-center">
                            <span style={{ color: 'var(--text-muted)' }}>New Interactions to Process</span>
                            <span style={{ fontWeight: 'bold', fontSize: '1.125rem', color: feedInteractions > 0 ? '#d97706' : '#111827' }}>+{feedInteractions.toLocaleString()}</span>
                        </div>
                    </div>

                    <div className="flex gap-4" style={{ marginTop: '32px' }}>
                        <button 
                            onClick={handleRetrainFeed}
                            disabled={isTrainingFeed || feedInteractions === 0}
                            className="btn btn-primary flex-1"
                            style={{ padding: '12px', display: 'flex', justifyContent: 'center', alignItems: 'center', gap: '8px' }}
                        >
                            {isTrainingFeed ? (
                                <span>Refreshing...</span>
                            ) : (
                                <>
                                    <BrainCircuit size={18} />
                                    <span>Update Feed Weights</span>
                                </>
                            )}
                        </button>
                        <button 
                            className="btn btn-secondary"
                            style={{ padding: '12px', display: 'flex', justifyContent: 'center', alignItems: 'center', gap: '8px' }}
                            title="View training logs"
                        >
                            <History size={18} />
                        </button>
                    </div>
                </div>
            </div>

            {/* Model Evaluation & Comparison Table */}
            <div className="card" style={{ animation: 'fadeIn 0.5s ease' }}>
                <div style={{ marginBottom: '24px' }}>
                    <h3 style={{ fontSize: '1.125rem', margin: '0 0 8px 0', fontWeight: 'bold' }}>Model Version Evaluation</h3>
                    <p style={{ margin: 0, color: 'var(--text-muted)', fontSize: '0.875rem' }}>Detailed comparison of the Image Classification model against its predecessor.</p>
                </div>

                <div style={{ overflowX: 'auto' }}>
                    <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
                        <thead>
                            <tr style={{ borderBottom: '2px solid #e5e7eb' }}>
                                <th style={{ padding: '12px', color: 'var(--text-muted)', fontWeight: '600' }}>Metric</th>
                                <th style={{ padding: '12px', color: 'var(--text-muted)', fontWeight: '600' }}>Production ({metrics.current.version})</th>
                                <th style={{ padding: '12px', color: 'var(--text-muted)', fontWeight: '600' }}>Previous ({metrics.previous.version})</th>
                                <th style={{ padding: '12px', color: 'var(--text-muted)', fontWeight: '600' }}>Details / Change</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr style={{ borderBottom: '1px solid #f3f4f6' }}>
                                <td style={{ padding: '16px 12px', fontWeight: '500' }}>Accuracy</td>
                                <td style={{ padding: '16px 12px', fontWeight: 'bold' }}>{metrics.current.accuracy}</td>
                                <td style={{ padding: '16px 12px', color: '#6b7280' }}>{metrics.previous.accuracy}</td>
                                <td style={{ padding: '16px 12px' }}>
                                    Overall correct predictions {renderDiffIndicator(metrics.diffs.accuracy)}
                                </td>
                            </tr>
                            <tr style={{ borderBottom: '1px solid #f3f4f6' }}>
                                <td style={{ padding: '16px 12px', fontWeight: '500' }}>Precision</td>
                                <td style={{ padding: '16px 12px', fontWeight: 'bold' }}>{metrics.current.precision}</td>
                                <td style={{ padding: '16px 12px', color: '#6b7280' }}>{metrics.previous.precision}</td>
                                <td style={{ padding: '16px 12px' }}>
                                    Fewer misclassifications {renderDiffIndicator(metrics.diffs.precision)}
                                </td>
                            </tr>
                            <tr style={{ borderBottom: '1px solid #f3f4f6' }}>
                                <td style={{ padding: '16px 12px', fontWeight: '500' }}>Recall</td>
                                <td style={{ padding: '16px 12px', fontWeight: 'bold' }}>{metrics.current.recall}</td>
                                <td style={{ padding: '16px 12px', color: '#6b7280' }}>{metrics.previous.recall}</td>
                                <td style={{ padding: '16px 12px' }}>
                                    Detects items more reliably {renderDiffIndicator(metrics.diffs.recall)}
                                </td>
                            </tr>
                            <tr style={{ borderBottom: '1px solid #f3f4f6' }}>
                                <td style={{ padding: '16px 12px', fontWeight: '500' }}>Avg. Inference Latency</td>
                                <td style={{ padding: '16px 12px', fontWeight: 'bold' }}>{metrics.current.latency}</td>
                                <td style={{ padding: '16px 12px', color: '#6b7280' }}>{metrics.previous.latency}</td>
                                <td style={{ padding: '16px 12px' }}>
                                    Processing time per image {renderDiffIndicator(metrics.diffs.latency)}
                                </td>
                            </tr>
                            <tr>
                                <td style={{ padding: '16px 12px', fontWeight: '500' }}>Knowledge Base</td>
                                <td style={{ padding: '16px 12px', fontWeight: 'bold', color: '#3b82f6' }}>{metrics.current.classes}</td>
                                <td style={{ padding: '16px 12px', color: '#6b7280' }}>{metrics.previous.classes}</td>
                                <td style={{ padding: '16px 12px' }}>
                                    Trained Categories
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>

            {/* Recommendation System ML Dashboard */}
            <div style={{ marginTop: '48px', borderTop: '1px solid #e5e7eb', paddingTop: '32px' }}>
                <div style={{ marginBottom: '24px' }}>
                    <h2 style={{ fontSize: '1.5rem', margin: '0 0 8px 0', fontWeight: 'bold' }}>Recommendation System ML Dashboard</h2>
                    <p style={{ margin: 0, color: 'var(--text-muted)' }}>Real-time telemetry measuring content-based recommendation effectiveness, cold-start fallback behavior, and user engagement heatmap.</p>
                </div>

                {loadingDashboard || !mlDashboardData ? (
                    <div style={{ padding: '40px', textAlign: 'center', color: 'var(--text-muted)' }}>Loading ML telemetry...</div>
                ) : (
                    <>
                        {/* 1. ML Effectiveness Monitor & A/B Testing CTR */}
                        <div className="flex gap-6 mb-8">
                            <div className="card flex-1" style={{ borderLeft: '4px solid #8b5cf6' }}>
                                <h3 style={{ fontSize: '1.125rem', margin: '0 0 16px 0', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '8px' }}>
                                    <Sparkles size={18} color="#8b5cf6" />
                                    ML Effectiveness Monitor (A/B Test CTR)
                                </h3>
                                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '24px', marginBottom: '20px' }}>
                                    <div style={{ flex: 1, padding: '16px', background: '#f5f3ff', borderRadius: '12px', textAlign: 'center' }}>
                                        <div style={{ fontSize: '0.875rem', color: '#6b7280', fontWeight: '500', marginBottom: '4px' }}>ML Recommended Feed</div>
                                        <div style={{ fontSize: '2rem', fontWeight: 'bold', color: '#8b5cf6' }}>
                                            {mlDashboardData.ml_effectiveness.ml_ctr}%
                                        </div>
                                        <div style={{ fontSize: '0.75rem', color: '#10b981', fontWeight: 'bold', marginTop: '4px' }}>
                                            {(mlDashboardData.ml_effectiveness.ml_ctr / Math.max(1, mlDashboardData.ml_effectiveness.control_ctr)).toFixed(1)}x Lift
                                        </div>
                                    </div>
                                    <div style={{ flex: 1, padding: '16px', background: '#f3f4f6', borderRadius: '12px', textAlign: 'center' }}>
                                        <div style={{ fontSize: '0.875rem', color: '#6b7280', fontWeight: '500', marginBottom: '4px' }}>Standard/Latest Feed (Control)</div>
                                        <div style={{ fontSize: '2rem', fontWeight: 'bold', color: '#4b5563' }}>
                                            {mlDashboardData.ml_effectiveness.control_ctr}%
                                        </div>
                                        <div style={{ fontSize: '0.75rem', color: '#6b7280', fontWeight: '500', marginTop: '4px' }}>Baseline</div>
                                    </div>
                                    <div style={{ flex: 1, padding: '16px', background: '#ecfdf5', borderRadius: '12px', textAlign: 'center' }}>
                                        <div style={{ fontSize: '0.875rem', color: '#047857', fontWeight: '500', marginBottom: '4px' }}>Precision @ 5</div>
                                        <div style={{ fontSize: '2rem', fontWeight: 'bold', color: '#10b981' }}>
                                            {mlDashboardData.ml_effectiveness.precision_at_5}%
                                        </div>
                                        <div style={{ fontSize: '0.75rem', color: '#047857', fontWeight: '500', marginTop: '4px' }}>Recommendation Accuracy</div>
                                    </div>
                                </div>
                                <div style={{ fontSize: '0.875rem', color: 'var(--text-muted)', display: 'flex', justifyContent: 'space-between' }}>
                                    <span>Total Impressions: <strong>{mlDashboardData.ml_effectiveness.total_impressions.toLocaleString()}</strong></span>
                                    <span>Total Click Events: <strong>{mlDashboardData.ml_effectiveness.total_clicks.toLocaleString()}</strong></span>
                                </div>
                            </div>
                        </div>

                        {/* 2. Heatmap & Trending Grid */}
                        <div className="flex gap-6 mb-8">
                            {/* User Activity Heatmap */}
                            <div className="card flex-1" style={{ flex: '1.5' }}>
                                <h3 style={{ fontSize: '1.125rem', margin: '0 0 16px 0', fontWeight: 'bold' }}>User Activity Heatmap (Student Hourly Interaction Peak)</h3>
                                <div style={{ height: '220px', width: '100%' }}>
                                    <ResponsiveContainer width="100%" height="100%">
                                        <BarChart data={mlDashboardData.activity_heatmap} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                                            <XAxis dataKey="hour" stroke="#9ca3af" fontSize={10} tickLine={false} />
                                            <YAxis stroke="#9ca3af" fontSize={10} tickLine={false} />
                                            <Tooltip contentStyle={{ borderRadius: '8px', border: '1px solid #e5e7eb' }} />
                                            <Bar dataKey="count" fill="#8b5cf6" radius={[4, 4, 0, 0]} />
                                        </BarChart>
                                    </ResponsiveContainer>
                                </div>
                                <p style={{ margin: '12px 0 0 0', fontSize: '0.75rem', color: 'var(--text-muted)', textAlign: 'center' }}>
                                    Shows the total user interaction clicks (views & saves) distributed over a 24-hour cycle.
                                </p>
                            </div>

                            {/* Trending Items */}
                            <div className="card flex-1">
                                <h3 style={{ fontSize: '1.125rem', margin: '0 0 16px 0', fontWeight: 'bold' }}>Trending Items (Cold-Start Fallback Catalog)</h3>
                                <div style={{ overflowX: 'auto' }}>
                                    <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '0.875rem' }}>
                                        <thead>
                                            <tr style={{ borderBottom: '1px solid #e5e7eb' }}>
                                                <th style={{ padding: '8px', color: '#6b7280', fontWeight: '600' }}>Item Title</th>
                                                <th style={{ padding: '8px', color: '#6b7280', fontWeight: '600' }}>Category</th>
                                                <th style={{ padding: '8px', color: '#6b7280', fontWeight: '600', textAlign: 'right' }}>Views</th>
                                                <th style={{ padding: '8px', color: '#6b7280', fontWeight: '600', textAlign: 'right' }}>Saves</th>
                                                <th style={{ padding: '8px', color: '#6b7280', fontWeight: '600', textAlign: 'right' }}>Score</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            {mlDashboardData.trending_items.map((item, idx) => (
                                                <tr key={item.id} style={{ borderBottom: idx < mlDashboardData.trending_items.length - 1 ? '1px solid #f3f4f6' : 'none' }}>
                                                    <td style={{ padding: '10px 8px', fontWeight: '500', maxWidth: '120px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }} title={item.title}>
                                                        {item.title}
                                                    </td>
                                                    <td style={{ padding: '10px 8px', color: '#6b7280' }}>{item.category}</td>
                                                    <td style={{ padding: '10px 8px', textAlign: 'right', fontWeight: 'bold' }}>{item.view_count}</td>
                                                    <td style={{ padding: '10px 8px', textAlign: 'right', fontWeight: 'bold' }}>{item.save_count}</td>
                                                    <td style={{ padding: '10px 8px', textAlign: 'right', color: '#8b5cf6', fontWeight: 'bold' }}>
                                                        {item.popularity_score}
                                                    </td>
                                                </tr>
                                            ))}
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>
                    </>
                )}
            </div>
        </div>
    );
};

export default MLModels;
