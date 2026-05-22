import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import Layout from './components/Layout';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Triage from './pages/Triage';
import Dispute from './pages/Dispute';
import Users from './pages/Users';
import Analytics from './pages/Analytics';
import PrivateRoute from './components/PrivateRoute';

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/login" element={<Login />} />

        {/* Protected Dashboard Routes wrapped in Layout */}
        <Route path="/dashboard" element={
          <PrivateRoute>
            <Layout>
              <Dashboard />
            </Layout>
          </PrivateRoute>
        } />

        <Route path="/triage" element={
          <PrivateRoute>
            <Layout>
              <Triage />
            </Layout>
          </PrivateRoute>
        } />

        <Route path="/disputes" element={
          <PrivateRoute>
            <Layout>
              <Dispute />
            </Layout>
          </PrivateRoute>
        } />

        <Route path="/users" element={
          <PrivateRoute>
            <Layout>
              <Users />
            </Layout>
          </PrivateRoute>
        } />

        <Route path="/analytics" element={
          <PrivateRoute>
            <Layout>
              <Analytics />
            </Layout>
          </PrivateRoute>
        } />

        <Route path="/" element={<Navigate to="/dashboard" replace />} />
      </Routes>
    </Router>
  );
}

export default App;
