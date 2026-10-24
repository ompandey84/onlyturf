import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { supabase } from '../supabase';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { Wallet, Bookmark, CalendarDays, ArrowRight, Dribbble, ChevronRight, RefreshCw } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

export default function AdminDashboard() {
    const { user } = useAuth();
    const navigate = useNavigate();
    const [loading, setLoading] = useState(true);
    const [userName, setUserName] = useState('Owner');
    const [stats, setStats] = useState({ todayRevenue: 0, todayBookings: 0 });
    const [chartData, setChartData] = useState([]);
    const [recentBookings, setRecentBookings] = useState([]);
    const [facilities, setFacilities] = useState([]);

    const fetchDashboardData = async () => {
        setLoading(true);
        try {
            // 1. Get Profile Name
            const { data: profile } = await supabase
                .from('profiles')
                .select('full_name')
                .eq('id', user.id)
                .single();
            if (profile?.full_name) setUserName(profile.full_name);

            // 2. Get Facilities
            const { data: facs } = await supabase
                .from('facilities')
                .select('id, name')
                .eq('owner_id', user.id);

            setFacilities(facs || []);
            const facilityIds = (facs || []).map(f => f.id);

            if (facilityIds.length === 0) {
                setLoading(false);
                return;
            }

            // 3. Get Bookings for Last 7 Days
            const today = new Date();
            today.setHours(23, 59, 59, 999);
            const sevenDaysAgo = new Date();
            sevenDaysAgo.setDate(today.getDate() - 6);
            sevenDaysAgo.setHours(0, 0, 0, 0);

            const { data: bks } = await supabase
                .from('bookings')
                .select('date, total_price, status, id, time_slot, facilities(name), profiles(full_name)')
                .in('facility_id', facilityIds)
                .gte('date', sevenDaysAgo.toISOString().split('T')[0])
                .lte('date', today.toISOString().split('T')[0]);

            let tRev = 0;
            let tBks = 0;
            const weekRev = Array(7).fill(0);

            const todayStr = today.toISOString().split('T')[0];

            (bks || []).forEach(b => {
                const dateStr = b.date;
                const price = b.total_price || 0;

                if (dateStr === todayStr && b.status !== 'cancelled') {
                    tRev += price;
                    tBks += 1;
                }

                if (b.status !== 'cancelled') {
                    const bDate = new Date(dateStr);
                    bDate.setHours(0, 0, 0, 0);
                    const diffTime = Math.abs(today - bDate);
                    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)) - 1; // 0 is today, 6 is 7 days ago
                    if (diffDays >= 0 && diffDays < 7) {
                        weekRev[6 - diffDays] += price;
                    }
                }
            });

            // Format chart data matching flutter's "7d ago" to "Today"
            const newChartData = weekRev.map((val, idx) => {
                let label = '';
                if (idx === 0) label = '7d ago';
                else if (idx === 6) label = 'Today';
                return { name: label, revenue: val };
            });

            setStats({ todayRevenue: tRev, todayBookings: tBks });
            setChartData(newChartData);

            // 4. Recent Bookings (limit 5)
            const { data: recent } = await supabase
                .from('bookings')
                .select('id, date, total_price, status, time_slot, facilities(name), profiles(full_name, phone_number)')
                .in('facility_id', facilityIds)
                .order('date', { ascending: false })
                .limit(5);

            setRecentBookings(recent || []);
        } catch (e) {
            console.error(e);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchDashboardData();
    }, [user.id]);

    const statusCls = {
        confirmed: 'bg-green-50 text-green-700 dark:bg-green-900/20 dark:text-green-400',
        pending: 'bg-yellow-50 text-yellow-700 dark:bg-yellow-900/20 dark:text-yellow-400',
        cancelled: 'bg-red-50 text-red-700 dark:bg-red-900/20 dark:text-red-400',
        blocked: 'bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-400',
    };

    if (loading) {
        return (
            <div className="page-container py-8 flex flex-col items-center justify-center min-h-[60vh]">
                <div className="w-10 h-10 border-4 border-primary border-t-transparent rounded-full animate-spin mb-4"></div>
                <p className="text-[#617589] dark:text-gray-400 font-medium">Loading Dashboard...</p>
            </div>
        );
    }

    return (
        <div className="page-container py-8 animate-fade-in">
            {/* Header */}
            <div className="flex justify-between items-start mb-8">
                <div>
                    <h1 className="text-2xl font-bold text-[#111418] dark:text-white mb-1">Dashboard</h1>
                    <p className="text-sm text-[#617589] dark:text-gray-400">Welcome back, {userName}</p>
                </div>
                <button
                    onClick={fetchDashboardData}
                    className="p-2 text-primary hover:bg-primary/10 rounded-full transition-colors"
                >
                    <RefreshCw size={20} />
                </button>
            </div>

            {/* Stats */}
            <div className="grid grid-cols-2 gap-4 mb-8">
                <div className="bg-white dark:bg-[#1a2632] p-5 rounded-2xl border border-[#f0f2f4] dark:border-gray-800 shadow-sm flex flex-col">
                    <div className="w-10 h-10 rounded-full bg-green-50 dark:bg-green-900/20 flex items-center justify-center mb-4">
                        <Wallet size={20} className="text-green-600 dark:text-green-400" />
                    </div>
                    <span className="text-2xl font-bold text-[#111418] dark:text-white mb-1">₹{stats.todayRevenue.toLocaleString()}</span>
                    <span className="text-sm font-medium text-[#617589] dark:text-gray-400">Today's Revenue</span>
                </div>
                <div className="bg-white dark:bg-[#1a2632] p-5 rounded-2xl border border-[#f0f2f4] dark:border-gray-800 shadow-sm flex flex-col">
                    <div className="w-10 h-10 rounded-full bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center mb-4">
                        <Bookmark size={20} className="text-blue-600 dark:text-blue-400" />
                    </div>
                    <span className="text-2xl font-bold text-[#111418] dark:text-white mb-1">{stats.todayBookings}</span>
                    <span className="text-sm font-medium text-[#617589] dark:text-gray-400">Today's Bookings</span>
                </div>
            </div>

            {/* Chart */}
            <div className="bg-white dark:bg-[#1a2632] p-6 rounded-2xl border border-[#f0f2f4] dark:border-gray-800 shadow-sm mb-8">
                <h2 className="text-lg font-bold text-[#111418] dark:text-white mb-6">Revenue Trend (Last 7 Days)</h2>
                <div className="h-48 w-full">
                    <ResponsiveContainer width="100%" height="100%">
                        <AreaChart data={chartData} margin={{ top: 5, right: 0, left: 0, bottom: 0 }}>
                            <defs>
                                <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                                    <stop offset="5%" stopColor="#137fec" stopOpacity={0.2} />
                                    <stop offset="95%" stopColor="#137fec" stopOpacity={0} />
                                </linearGradient>
                            </defs>
                            <XAxis
                                dataKey="name"
                                axisLine={false}
                                tickLine={false}
                                tick={{ fill: '#9ca3af', fontSize: 12 }}
                                dy={10}
                            />
                            <Tooltip
                                contentStyle={{ borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}
                                itemStyle={{ color: '#137fec', fontWeight: 'bold' }}
                                formatter={(value) => [`₹${value}`, 'Revenue']}
                            />
                            <Area
                                type="monotone"
                                dataKey="revenue"
                                stroke="#137fec"
                                strokeWidth={3}
                                fillOpacity={1}
                                fill="url(#colorRevenue)"
                            />
                        </AreaChart>
                    </ResponsiveContainer>
                </div>
            </div>

            {/* Quick Actions */}
            <h2 className="text-lg font-bold text-[#111418] dark:text-white mb-4">Quick Actions</h2>
            <div
                onClick={() => navigate('/facility-owner/facilities')}
                className="bg-white dark:bg-[#1a2632] p-4 rounded-2xl border border-[#f0f2f4] dark:border-gray-800 shadow-sm flex items-center mb-8 cursor-pointer hover:shadow-md transition-shadow group"
            >
                <div className="w-12 h-12 rounded-xl bg-purple-50 dark:bg-purple-900/20 flex items-center justify-center shrink-0">
                    <CalendarDays size={24} className="text-purple-600 dark:text-purple-400" />
                </div>
                <div className="ml-4 flex-1">
                    <h3 className="font-semibold text-[#111418] dark:text-white text-base">Manage Slots</h3>
                    <p className="text-sm text-[#617589] dark:text-gray-400">Update availability & pricing</p>
                </div>
                <div className="w-8 h-8 rounded-full bg-gray-50 dark:bg-gray-800 flex items-center justify-center group-hover:bg-primary group-hover:text-white transition-colors">
                    <ChevronRight size={18} className="text-gray-400 group-hover:text-white" />
                </div>
            </div>

            {/* Recent Bookings */}
            <h2 className="text-lg font-bold text-[#111418] dark:text-white mb-4">Recent Bookings</h2>
            {recentBookings.length === 0 ? (
                <div className="bg-white dark:bg-[#1a2632] p-10 rounded-2xl border border-[#f0f2f4] dark:border-gray-800 flex flex-col items-center justify-center">
                    <Bookmark size={48} className="text-gray-300 dark:text-gray-600 mb-2" />
                    <p className="text-gray-400">No bookings yet</p>
                </div>
            ) : (
                <div className="space-y-3">
                    {recentBookings.map((b) => (
                        <div key={b.id} className="bg-white dark:bg-[#1a2632] p-4 rounded-2xl border border-[#f0f2f4] dark:border-gray-800 shadow-sm flex items-center gap-4">
                            <div className="w-10 h-10 rounded-xl bg-[#f6f7f8] dark:bg-gray-800 flex items-center justify-center shrink-0 border border-gray-200 dark:border-gray-700">
                                <Dribbble size={20} className="text-[#111418] dark:text-gray-300" />
                            </div>
                            <div className="flex-1 min-w-0">
                                <p className="font-semibold text-[#111418] dark:text-white text-sm truncate">
                                    {b.facilities?.name || 'Unknown Venue'}
                                </p>
                                <p className="text-xs text-[#617589] dark:text-gray-400 truncate mt-0.5">
                                    {b.profiles?.full_name || 'Guest'} • {b.date}
                                </p>
                            </div>
                            <div className="flex flex-col items-end shrink-0">
                                <span className="font-bold text-[#111418] dark:text-white text-base">₹{b.total_price}</span>
                                <span className={`mt-1 px-2 py-0.5 rounded-md text-[10px] font-bold uppercase tracking-wider ${statusCls[b.status] || statusCls.pending}`}>
                                    {b.status}
                                </span>
                            </div>
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
}
