import React, { useEffect, useState } from 'react';
import { supabase } from '../supabase';
import { useApp } from '../context/AppContext';
import FacilityCard from '../components/FacilityCard';
import { sportsTypes } from '../constants';
import { Search, SearchX } from 'lucide-react';

export default function Facilities() {
    const { selectedCity } = useApp();
    const [facilities, setFacilities] = useState([]);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState('');
    const [sport, setSport] = useState('All');

    useEffect(() => {
        fetchFacilities();
    }, [selectedCity]);

    const fetchFacilities = async () => {
        try {
            setLoading(true);
            const { data, error } = await supabase.from('facilities').select('*');
            if (error) throw error;
            setFacilities(data || []);
        } catch (e) {
            console.error(e);
        } finally {
            setLoading(false);
        }
    };

    const filtered = facilities.filter(f => {
        const q = search.toLowerCase();
        const matchSearch = f.name.toLowerCase().includes(q) || f.location.toLowerCase().includes(q);
        const matchSport = sport === 'All' || f.sport_type === sport;
        return matchSearch && matchSport;
    });

    return (
        <div className="min-h-screen">
            {/* Page Hero */}
            <div className="glass-panel mx-4 mt-24 mb-6 rounded-3xl border border-white/60 shadow-xl relative overflow-hidden bg-white/40 backdrop-blur-3xl">
                <div className="absolute inset-0 bg-gradient-to-br from-white/40 to-transparent pointer-events-none" />
                <div className="page-container py-10 px-6 sm:px-10 lg:px-12 relative z-10">
                    <h1 className="text-4xl md:text-5xl font-black text-slate-900 mb-2 tracking-tight">
                        Explore Facilities
                    </h1>
                    <p className="text-slate-600 font-medium text-lg">
                        World-class courts and fields in <span className="font-bold text-primary tracking-wide">{selectedCity}</span>
                    </p>

                    {/* Search & Filter Bar */}
                    <div className="flex flex-col sm:flex-row gap-4 mt-8">
                        <div className="relative flex-1 group">
                            <Search size={20} className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-primary transition-colors" />
                            <input
                                type="text"
                                placeholder="Search by venue name..."
                                value={search}
                                onChange={(e) => setSearch(e.target.value)}
                                className="w-full rounded-2xl border border-white/80 bg-white/60 backdrop-blur-md px-4 py-3.5 text-base font-medium text-slate-800 placeholder:text-slate-400 outline-none focus:border-white focus:ring-4 focus:ring-white/50 transition-all shadow-sm pl-12"
                            />
                        </div>
                        <select
                            value={sport}
                            onChange={(e) => setSport(e.target.value)}
                            className="rounded-2xl border border-white/80 bg-white/60 backdrop-blur-md px-4 py-3.5 text-base font-medium text-slate-800 outline-none focus:border-white focus:ring-4 focus:ring-white/50 transition-all shadow-sm sm:w-56 appearance-none cursor-pointer"
                        >
                            {sportsTypes.map(s => (
                                <option key={s} value={s} className="bg-white text-slate-800 font-medium">{s}</option>
                            ))}
                        </select>
                    </div>

                    {/* Sport Filter Chips */}
                    <div className="flex flex-wrap gap-2.5 mt-6">
                        {sportsTypes.map(s => (
                            <button
                                key={s}
                                onClick={() => setSport(s)}
                                className={`px-4 py-1.5 rounded-full text-[13px] font-bold transition-all border shadow-sm ${sport === s ? 'bg-slate-900 text-white border-transparent scale-105' : 'bg-white/60 border-white/80 text-slate-600 hover:bg-white hover:text-primary backdrop-blur-md hover:-translate-y-0.5'}`}
                            >
                                {s}
                            </button>
                        ))}
                    </div>
                </div>
            </div>

            {/* Results */}
            <div className="page-container py-10 relative z-10">
                <div className="flex items-center justify-between mb-8">
                    <p className="text-[15px] font-bold text-slate-500">
                        {loading ? 'Loading facilities...' : `${filtered.length} venue${filtered.length !== 1 ? 's' : ''} found near you`}
                    </p>
                </div>

                {loading ? (
                    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
                        {[...Array(9)].map((_, i) => (
                            <div key={i} className="glass-panel rounded-3xl overflow-hidden border border-white/60 bg-white/40">
                                <div className="skeleton aspect-[16/10] bg-white/40" />
                                <div className="p-5 space-y-3">
                                    <div className="skeleton h-5 rounded-lg w-3/4 bg-white/60" />
                                    <div className="skeleton h-4 rounded-lg w-1/2 bg-white/60" />
                                </div>
                            </div>
                        ))}
                    </div>
                ) : filtered.length === 0 ? (
                    <div className="flex flex-col items-center justify-center py-24 text-center glass-panel rounded-3xl border border-white/60 shadow-xl mt-4 bg-white/40">
                        <SearchX size={64} className="text-slate-300 mb-6" />
                        <h3 className="text-2xl font-black text-slate-900 mb-2">No facilities found</h3>
                        <p className="text-slate-500 font-medium text-lg max-w-md">We couldn't find any venues matching your current search or filter criteria. Try broadening your search.</p>
                    </div>
                ) : (
                    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
                        {filtered.map(f => <FacilityCard key={f.id} facility={f} />)}
                    </div>
                )}

                {/* CTA */}
                {!loading && (
                    <div className="mt-16 rounded-3xl glass-panel border border-white/60 p-10 text-center shadow-xl relative overflow-hidden bg-white/40 backdrop-blur-3xl">
                        <div className="absolute inset-0 bg-gradient-to-br from-white/40 to-transparent pointer-events-none" />
                        <div className="relative z-10 max-w-2xl mx-auto">
                            <h3 className="text-2xl md:text-3xl font-black text-slate-900 mb-3 tracking-tight">Can't find the right venue?</h3>
                            <p className="text-slate-600 font-medium text-lg mb-8">Reach out to our dedicated coordinators. We'll help you find the perfect field for your next game, no matter the sport.</p>
                            <a href="/about" className="inline-flex h-12 items-center justify-center px-8 rounded-xl bg-slate-900 text-white font-bold text-[15px] shadow-lg shadow-slate-900/20 hover:scale-105 transition-all">Contact Support</a>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
}
