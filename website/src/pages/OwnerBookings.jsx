import React, { useState, useEffect } from 'react';
import { supabase } from '../supabase';
import { useAuth } from '../context/AuthContext';
import { CalendarDays, History, User } from 'lucide-react';
import { formatDate } from '../utils/dateUtils';

export default function OwnerBookings() {
    const { user } = useAuth();
    const [bookings, setBookings] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showUpcoming, setShowUpcoming] = useState(true);

    const fetchBookings = async () => {
        setLoading(true);
        try {
            // First get facilities owned by user
            const { data: facs } = await supabase
                .from('facilities')
                .select('id')
                .eq('owner_id', user.id);

            const ids = (facs || []).map(f => f.id);

            if (ids.length === 0) {
                setBookings([]);
                setLoading(false);
                return;
            }

            const { data, error } = await supabase
                .from('bookings')
                .select('*, facilities(name), profiles(full_name, phone_number)')
                .in('facility_id', ids)
                .order('date', { ascending: false });

            if (error) throw error;
            setBookings(data || []);
        } catch (e) {
            console.error(e);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchBookings();
    }, [user.id]);

    const statusCls = {
        confirmed: 'bg-green-50 text-green-700 dark:bg-green-900/20 dark:text-green-400',
        pending: 'bg-yellow-50 text-yellow-700 dark:bg-yellow-900/20 dark:text-yellow-400',
        cancelled: 'bg-red-50 text-red-700 dark:bg-red-900/20 dark:text-red-400',
        blocked: 'bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-400',
    };

    // Filter bookings client-safe
    const filteredBookings = bookings.filter(b => {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const bDate = new Date(b.date);
        bDate.setHours(0, 0, 0, 0);

        if (showUpcoming) {
            return bDate >= today;
        } else {
            return bDate < today;
        }
    });

    return (
        <div className="page-container py-8 animate-fade-in">
            <div className="flex justify-between items-center mb-6">
                <h1 className="text-2xl font-bold text-[#111418] dark:text-white">Bookings</h1>
            </div>

            {/* Toggle */}
            <div className="bg-white dark:bg-[#1a2632] p-1.5 rounded-2xl border border-[#f0f2f4] dark:border-gray-800 flex mb-8 max-w-sm mx-auto shadow-sm">
                <button
                    onClick={() => setShowUpcoming(true)}
                    className={`flex-1 py-3 text-sm font-semibold rounded-xl transition-all ${showUpcoming ? 'bg-primary text-white shadow-md' : 'text-[#617589] dark:text-gray-400 hover:text-[#111418] dark:hover:text-white'}`}
                >
                    Upcoming
                </button>
                <button
                    onClick={() => setShowUpcoming(false)}
                    className={`flex-1 py-3 text-sm font-semibold rounded-xl transition-all ${!showUpcoming ? 'bg-primary text-white shadow-md' : 'text-[#617589] dark:text-gray-400 hover:text-[#111418] dark:hover:text-white'}`}
                >
                    History
                </button>
            </div>

            {loading ? (
                <div className="flex flex-col items-center justify-center py-20">
                    <div className="w-10 h-10 border-4 border-primary border-t-transparent rounded-full animate-spin mb-4"></div>
                </div>
            ) : filteredBookings.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-20">
                    {showUpcoming ? (
                        <CalendarDays size={64} className="text-gray-300 dark:text-gray-600 mb-4" />
                    ) : (
                        <History size={64} className="text-gray-300 dark:text-gray-600 mb-4" />
                    )}
                    <p className="text-lg font-semibold text-[#617589] dark:text-gray-400">
                        {showUpcoming ? 'No upcoming bookings' : 'No past bookings'}
                    </p>
                </div>
            ) : (
                <div className="space-y-4 max-w-3xl mx-auto">
                    {filteredBookings.map((b) => (
                        <div key={b.id} className="bg-white dark:bg-[#1a2632] p-5 rounded-2xl border border-[#f0f2f4] dark:border-gray-800 shadow-sm flex flex-col gap-4 hover:shadow-md transition-shadow">
                            <div className="flex justify-between items-start">
                                <h3 className="font-bold text-[#111418] dark:text-white text-base">
                                    {b.facilities?.name || 'Unknown Venue'}
                                </h3>
                                <span className={`px-2.5 py-1 rounded-lg text-[11px] font-bold uppercase tracking-wider ${statusCls[b.status] || statusCls.pending}`}>
                                    {b.status}
                                </span>
                            </div>

                            <div className="flex items-center gap-3">
                                <div className="p-2.5 bg-blue-50 dark:bg-blue-900/20 rounded-xl">
                                    <CalendarDays size={20} className="text-blue-600 dark:text-blue-400" />
                                </div>
                                <div>
                                    <p className="font-semibold text-[#111418] dark:text-white text-sm">
                                        {formatDate(b.date)}
                                    </p>
                                    <p className="text-[#617589] dark:text-gray-400 text-sm mt-0.5">
                                        {b.time_slot}
                                    </p>
                                </div>
                            </div>

                            <div className="pt-4 border-t border-[#f0f2f4] dark:border-gray-800 flex justify-between items-center">
                                <div className="flex items-center gap-3">
                                    <div className="w-8 h-8 rounded-full bg-gray-100 dark:bg-gray-800 flex items-center justify-center shrink-0">
                                        <User size={16} className="text-gray-500" />
                                    </div>
                                    <div className="min-w-0">
                                        <p className="font-medium text-[#111418] dark:text-white text-sm truncate">
                                            {b.profiles?.full_name || 'Guest'}
                                        </p>
                                        <p className="text-xs text-[#617589] dark:text-gray-400 truncate mt-0.5">
                                            {b.profiles?.phone_number || 'N/A'}
                                        </p>
                                    </div>
                                </div>
                                <div className="text-lg font-bold text-[#111418] dark:text-white">
                                    ₹{b.total_price}
                                </div>
                            </div>
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
}
