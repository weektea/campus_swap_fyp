import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import Layout from './components/Layout';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Reports from './pages/Reports';
import Tickets from './pages/Tickets';
import Backup from './pages/Backup';
import History from './pages/History';
import Users from './pages/Users';
import UserDetail from './pages/UserDetail';
import Dispute from './pages/Dispute';
import Listings from './pages/Listings';
import Analytics from './pages/Analytics';
import Transactions from './pages/Transactions';
import Categories from './pages/Categories';
import Reviews from './pages/Reviews';
import MLModels from './pages/MLModels';
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

        <Route path="/reports" element={
          <PrivateRoute>
            <Layout>
              <Reports />
            </Layout>
          </PrivateRoute>
        } />

        <Route path="/tickets" element={
          <PrivateRoute>
            <Layout>
              <Tickets />
            </Layout>
          </PrivateRoute>
        } />

        <Route path="/backup" element={
          <PrivateRoute>
            <Layout>
              <Backup />
            </Layout>
          </PrivateRoute>
        } />

        <Route path="/history" element={
          <PrivateRoute>
            <Layout>
              <History />
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

        <Route path="/users/:id" element={
          <PrivateRoute>
            <Layout>
              <UserDetail />
            </Layout>
          </PrivateRoute>
        } />

        <Route path="/listings" element={
          <PrivateRoute>
            <Layout>
              <Listings />
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

        <Route path="/ml-models" element={
          <PrivateRoute>
            <Layout>
              <MLModels />
            </Layout>
          </PrivateRoute>
        } />

        <Route path="/transactions" element={
          <PrivateRoute>
            <Layout>
              <Transactions />
            </Layout>
          </PrivateRoute>
        } />

        <Route path="/categories" element={
          <PrivateRoute>
            <Layout>
              <Categories />
            </Layout>
          </PrivateRoute>
        } />

        <Route path="/reviews" element={
          <PrivateRoute>
            <Layout>
              <Reviews />
            </Layout>
          </PrivateRoute>
        } />

        {/* Catch all */}
        <Route path="*" element={<Navigate to="/dashboard" replace />} />
      </Routes>
    </Router>
  );
}

export default App;
