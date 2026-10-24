import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { supabase } from '../supabase';
import { useAuth } from '../context/AuthContext';
import { Calendar, CheckCircle2, Clock, XCircle, CalendarDays, CalendarOff } from 'lucide-react';

export default function Dashboard() {
    const { user, signOut } = useAuth();
    const [bookings, setBookings] = useState([]);
    const [loading, setLoading] = useState(true);
    const [activeTab, setActiveTab] = useState('all');

    useEffect(() => {
        if (user) fetchBookings();
    }, [user]);

    const fetchBookings = async () => {
        try {
            setLoading(true);
            const { data, error } = await supabase
                .from('bookings')
                .select(`*, facilities(name, location, city, image_url, images)`)
                .eq('user_id', user.id)
                .order('date', { ascending: false });
            if (error) throw error;
            setBookings(data || []);
        } catch (e) { console.error(e); }
        finally { setLoading(false); }
    };

    const formatDate = (d) => new Date(d).toLocaleDateString('en-IN', { weekday: 'short', day: 'numeric', month: 'short', year: 'numeric' });

    const filtered = activeTab === 'all' ? bookings : bookings.filter(b => b.status === activeTab);

    const statusCls = {
        confirmed: 'bg-emerald-50 border border-emerald-200 text-emerald-700 shadow-sm',
        pending: 'bg-yellow-50 border border-yellow-200 text-yellow-700 shadow-sm',
        cancelled: 'bg-red-50 border border-red-200 text-red-700 shadow-sm',
    };

    return (
        <div className="min-h-screen relative z-10">
            {/* Page Header */}
            <div className="glass-panel bg-white/40 border-b border-white/60 backdrop-blur-3xl shadow-sm relative z-20">
                <div className="page-container py-8 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                    <div>
                        <h1 className="text-3xl font-black text-slate-900 tracking-tight">My Bookings</h1>
                        <p className="text-slate-500 font-bold mt-1">Welcome back, {user?.email?.split('@')[0]}</p>
                    </div>
                    <div className="flex gap-3">
                        <Link to="/facilities" className="h-10 px-5 flex items-center justify-center rounded-xl bg-slate-900 text-white font-bold hover:bg-slate-800 transition-all shadow-md">Book Again</Link>
                        <button onClick={signOut} className="h-10 px-5 flex items-center justify-center rounded-xl text-red-600 font-bold bg-white/60 hover:bg-white border border-white/80 transition-all shadow-sm">
                            Sign Out
                        </button>
                    </div>
                </div>
            </div>

            <div className="page-container py-8">
                {/* Stats */}
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 mb-8">
                    {[
                        { label: 'Total', count: bookings.length, icon: Calendar, color: 'text-primary' },
                        { label: 'Confirmed', count: bookings.filter(b => b.status === 'confirmed').length, icon: CheckCircle2, color: 'text-emerald-500' },
                        { label: 'Pending', count: bookings.filter(b => b.status === 'pending').length, icon: Clock, color: 'text-yellow-500' },
                        { label: 'Cancelled', count: bookings.filter(b => b.status === 'cancelled').length, icon: XCircle, color: 'text-red-500' },
                    ].map(({ label, count, icon: Icon, color }) => (
                        <div key={label} className="glass-panel bg-white/40 border-white/60 backdrop-blur-3xl rounded-3xl p-5 shadow-sm flex items-center gap-4">
                            <Icon size={32} className={color} />
                            <div>
                                <p className="text-2xl font-black text-slate-900 tracking-tight">{count}</p>
                                <p className="text-[13px] font-bold text-slate-500">{label}</p>
                            </div>
                        </div>
                    ))}
                </div>

                {/* Tabs */}
                <div className="flex gap-1.5 mb-6 glass-panel bg-white/40 border-white/60 backdrop-blur-3xl rounded-2xl p-1.5 shadow-sm w-fit">
                    {['all', 'confirmed', 'pending', 'cancelled'].map(tab => (
                        <button
                            key={tab}
                            onClick={() => setActiveTab(tab)}
                            className={`px-4 py-2.5 rounded-xl text-[15px] font-bold capitalize transition-all ${activeTab === tab ? 'bg-slate-900 text-white shadow-md' : 'text-slate-600 hover:bg-white/60'}`}
                        >
                            {tab}
                        </button>
                    ))}
                </div>

                {loading ? (
                    <div className="flex flex-col gap-4">
                        {[1, 2, 3].map(i => (
                            <div key={i} className="flex gap-4 glass-panel bg-white/40 border-white/60 backdrop-blur-2xl rounded-3xl p-5 shadow-sm">
                                <div className="skeleton bg-white/60 w-full sm:w-40 h-32 rounded-2xl shrink-0 border border-white/80"></div>
                                <div className="flex-1 flex flex-col justify-between py-1">
                                    <div>
                                        <div className="skeleton bg-white/60 h-6 w-1/2 rounded-lg mb-2"></div>
                                        <div className="skeleton bg-white/60 h-4 w-1/3 rounded-lg"></div>
                                    </div>
                                    <div className="skeleton bg-white/60 h-8 w-full rounded-lg mt-4"></div>
                                </div>
                            </div>
                        ))}
                    </div>
                ) : filtered.length === 0 ? (
                    <div className="flex flex-col items-center justify-center py-20 glass-panel bg-white/40 border-white/60 backdrop-blur-3xl rounded-3xl shadow-sm text-center">
                        <CalendarDays size={64} className="text-slate-300 mb-4" />
                        <h3 className="text-2xl font-black text-slate-900 tracking-tight mb-2">No bookings yet</h3>
                        <p className="text-[15px] font-bold text-slate-500 mb-6">Ready to book your first venue?</p>
                        <Link to="/facilities" className="h-12 px-6 flex items-center justify-center rounded-xl bg-slate-900 text-white font-bold hover:bg-slate-800 transition-all shadow-md mt-2">Find a Facility</Link>
                    </div>
                ) : (
                    <div className="flex flex-col gap-5">
                        {filtered.map(b => {
                            const imgSrc = b.facilities?.images?.[0] || b.facilities?.image_url || 'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=400&q=80';
                            return (
                                <div key={b.id} className="flex flex-col sm:flex-row gap-5 glass-panel bg-white/40 border-[1.5px] border-white/60 backdrop-blur-3xl rounded-3xl p-5 hover:border-white hover:shadow-lg hover:-translate-y-1 transition-all">
                                    <div className="w-full sm:w-48 h-36 rounded-2xl bg-cover bg-center shrink-0 overflow-hidden shadow-sm" style={{ backgroundImage: `url("${imgSrc}")` }} />
                                    <div className="flex-1 flex flex-col justify-between">
                                        <div>
                                            <div className="flex items-start justify-between gap-3">
                                                <h3 className="text-lg font-black tracking-tight text-slate-900">{b.facilities?.name}</h3>
                                                <span className={`px-3 py-1 rounded-full text-[13px] font-black capitalize ${statusCls[b.status] || statusCls.pending}`}>
                                                    {b.status}
                                                </span>
                                            </div>
                                            <p className="text-[15px] font-bold text-slate-500 mt-1">{b.facilities?.location}, {b.facilities?.city}</p>
                                        </div>
                                        <div className="flex flex-wrap gap-5 mt-4 pt-4 border-t border-white/80">
                                            <div className="flex items-center gap-1.5 text-[15px] font-bold text-slate-700">
                                                <Calendar size={18} className="text-slate-400" />
                                                {formatDate(b.date)}
                                            </div>
                                            <div className="flex items-center gap-1.5 text-[15px] font-bold text-slate-700">
                                                <Clock size={18} className="text-slate-400" />
                                                {b.time_slot}
                                            </div>
                                            <div className="ml-auto font-black text-emerald-600 text-lg">₹{b.total_price}</div>
                                        </div>
                                    </div>
                                </div>
                            );
                        })}
                    </div>
                )}
            </div>
        </div>
    );
}
