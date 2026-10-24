import React, { useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { supabase } from '../supabase';
import FacilityCard from '../components/FacilityCard';
import { Search, SearchX } from 'lucide-react';

export default function SearchResults() {
    const [searchParams, setSearchParams] = useSearchParams();
    const queryParam = searchParams.get('q') || '';
    const [query, setQuery] = useState(queryParam);
    const [results, setResults] = useState([]);
    const [loading, setLoading] = useState(false);

    useEffect(() => {
        if (queryParam) { doSearch(queryParam); }
    }, [queryParam]);

    const doSearch = async (q) => {
        if (!q.trim()) return;
        setLoading(true);
        try {
            const { data, error } = await supabase.from('facilities').select('*').or(`name.ilike.%${q}%,location.ilike.%${q}%,city.ilike.%${q}%,sport_type.ilike.%${q}%`);
            if (error) throw error;
            setResults(data || []);
        } catch (e) { console.error(e); }
        finally { setLoading(false); }
    };

    const handleSearch = (e) => {
        e.preventDefault();
        setSearchParams({ q: query });
        doSearch(query);
    };

    return (
        <div className="min-h-screen relative z-10">
            <div className="glass-panel bg-white/40 border-b border-white/60 backdrop-blur-3xl shadow-sm relative z-20">
                <div className="page-container py-10">
                    <h1 className="text-3xl font-black text-slate-900 tracking-tight mb-5">Search Venues</h1>
                    <form onSubmit={handleSearch} className="flex gap-3">
                        <div className="relative flex-1">
                            <Search size={20} className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" />
                            <input
                                type="text"
                                placeholder="Search by name, city, or sport..."
                                value={query}
                                onChange={(e) => setQuery(e.target.value)}
                                className="w-full rounded-xl border border-white/80 bg-white/60 pl-11 pr-4 py-3.5 text-[15px] font-bold text-slate-900 placeholder:text-slate-400 outline-none focus:border-white focus:ring-4 focus:ring-white/50 transition-all shadow-sm backdrop-blur-md"
                            />
                        </div>
                        <button type="submit" className="h-[52px] px-8 flex items-center justify-center rounded-xl bg-slate-900 text-white font-bold hover:bg-slate-800 transition-all shadow-md shrink-0">Search</button>
                    </form>
                    {queryParam && (
                        <p className="mt-4 text-[15px] font-bold text-slate-600">
                            {loading ? 'Searching...' : `${results.length} result${results.length !== 1 ? 's' : ''} for "${queryParam}"`}
                        </p>
                    )}
                </div>
            </div>

            <div className="page-container py-10">
                {loading ? (
                    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
                        {[...Array(6)].map((_, i) => (
                            <div key={i} className="glass-panel bg-white/40 border-white/60 backdrop-blur-2xl rounded-3xl p-4 shadow-sm">
                                <div className="skeleton bg-white/60 aspect-[16/10] rounded-2xl mb-4 border border-white/80" />
                                <div className="space-y-3 px-1">
                                    <div className="skeleton bg-white/60 h-5 rounded-lg w-3/4" />
                                    <div className="skeleton bg-white/60 h-4 rounded-lg w-1/2" />
                                </div>
                            </div>
                        ))}
                    </div>
                ) : !queryParam ? (
                    <div className="flex flex-col items-center justify-center py-24 glass-panel bg-white/40 border-white/60 backdrop-blur-3xl rounded-3xl shadow-sm text-center">
                        <Search size={64} className="text-slate-300 mb-4" />
                        <h3 className="text-2xl font-black text-slate-900 tracking-tight mb-2">Search for Sports Venues</h3>
                        <p className="text-[15px] font-bold text-slate-500">Search by venue name, city, or sport type above.</p>
                    </div>
                ) : results.length === 0 ? (
                    <div className="flex flex-col items-center justify-center py-24 glass-panel bg-white/40 border-white/60 backdrop-blur-3xl rounded-3xl shadow-sm text-center">
                        <SearchX size={64} className="text-slate-300 mb-4" />
                        <h3 className="text-2xl font-black text-slate-900 tracking-tight mb-2">No results found</h3>
                        <p className="text-[15px] font-bold text-slate-500">Try different keywords or browse all facilities.</p>
                    </div>
                ) : (
                    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
                        {results.map(f => <FacilityCard key={f.id} facility={f} />)}
                    </div>
                )}
            </div>
        </div>
    );
}
