import React from 'react';

const History = () => {
    return (
        <div className="flex flex-col items-center justify-center h-full text-gray-500" style={{ minHeight: '60vh' }}>
            <h2 style={{ marginBottom: '1rem' }}>My Activity History</h2>
            <p>This module tracks your personal moderation logs and actions over time.</p>
            <p style={{ marginTop: '0.5rem', fontSize: '0.875rem' }}>(UI to be designed in future iterations)</p>
        </div>
    );
};

export default History;
