import React from 'react';
import { Navigate, Outlet } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

export default function ProtectedRoute({ roles }) {
    const { user, role, loading } = useAuth();

    if (loading) {
        return (
            <div className="flex h-screen items-center justify-center bg-[#f6f7f8] dark:bg-[#101922]">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
            </div>
        );
    }

    if (!user) return <Navigate to="/login" replace />;

    if (roles && !roles.includes(role)) {
        return <Navigate to="/" replace />;
    }

    return <Outlet />;
}
