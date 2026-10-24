import React from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import Layout from './components/Layout';
import ProtectedRoute from './components/ProtectedRoute';
import ScrollToTop from './components/ScrollToTop';

import Home from './pages/Home';
import Login from './pages/Login';
import Signup from './pages/Signup';
import Facilities from './pages/Facilities';
import FacilityDetails from './pages/FacilityDetails';
import BookingPage from './pages/BookingPage';
import BookingConfirmation from './pages/BookingConfirmation';
import Dashboard from './pages/Dashboard';
import AdminDashboard from './pages/AdminDashboard'; // Will become OwnerDashboard
import OwnerBookings from './pages/OwnerBookings';
import OwnerFacilities from './pages/OwnerFacilities';
import OwnerProfile from './pages/OwnerProfile'; // New file
import AddFacility from './pages/AddFacility';
import EditFacility from './pages/EditFacility';
import SlotManagement from './pages/SlotManagement';
import AboutUs from './pages/AboutUs';
import TermsOfService from './pages/TermsOfService';
import PrivacyPolicy from './pages/DataPolicy';
import NotFound from './pages/NotFound';

export default function App() {
    return (
        <BrowserRouter>
            <ScrollToTop />
            <Routes>
                {/* Public pages with Navbar+Footer */}
                <Route element={<Layout />}>
                    <Route path="/" element={<Home />} />
                    <Route path="/facilities" element={<Facilities />} />
                    <Route path="/facility-details" element={<FacilityDetails />} />
                    <Route path="/book/:id" element={<BookingPage />} />
                    <Route path="/about" element={<AboutUs />} />
                    <Route path="/terms" element={<TermsOfService />} />
                    <Route path="/privacy" element={<PrivacyPolicy />} />
                </Route>

                {/* Auth pages (no Layout) */}
                <Route path="/login" element={<Login />} />
                <Route path="/signup" element={<Signup />} />

                {/* Protected user pages */}
                <Route element={<ProtectedRoute />}>
                    <Route element={<Layout />}>
                        <Route path="/dashboard" element={<Dashboard />} />
                        <Route path="/booking-confirmation" element={<BookingConfirmation />} />
                    </Route>
                </Route>

                {/* Protected admin/owner pages */}
                <Route element={<ProtectedRoute roles={['owner', 'admin']} />}>
                    <Route element={<Layout />}>
                        <Route path="/facility-owner/dashboard" element={<AdminDashboard />} />
                        <Route path="/facility-owner/bookings" element={<OwnerBookings />} />
                        <Route path="/facility-owner/facilities" element={<OwnerFacilities />} />
                        <Route path="/facility-owner/profile" element={<OwnerProfile />} />
                        <Route path="/facility-owner/facilities/add" element={<AddFacility />} />
                        <Route path="/facility-owner/facilities/edit/:id" element={<EditFacility />} />
                        <Route path="/facility-owner/facilities/slots/:id" element={<SlotManagement />} />
                    </Route>
                </Route>

                <Route path="*" element={<NotFound />} />
            </Routes>
        </BrowserRouter>
    );
}
