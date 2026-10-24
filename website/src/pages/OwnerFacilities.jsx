import React, { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { supabase } from '../supabase';
import { useAuth } from '../context/AuthContext';
import { Plus, MapPin, Edit, Trash2, Calendar, Building2, Tag } from 'lucide-react';

export default function OwnerFacilities() {
    const { user, role } = useAuth();
    const navigate = useNavigate();
    const [facilities, setFacilities] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => { fetchFacilities(); }, [user, role]);

    const fetchFacilities = async () => {
        try {
            setLoading(true);
            let query = supabase.from('facilities').select('*');
            if (role === 'owner') query = query.eq('owner_id', user.id);
            const { data, error } = await query.order('created_at', { ascending: false });
            if (error) throw error;
            setFacilities(data || []);
        } catch (e) {
            console.error(e);
        } finally {
            setLoading(false);
        }
    };

    const deleteFacility = async (id) => {
        if (!window.confirm('Delete Facility?\n\nThis action cannot be undone. All associated slots will also be deleted.')) return;
        if (!window.confirm('Are you absolutely sure?\n\nPlease confirm deletion.')) return;

        try {
            await supabase.from('facilities').delete().eq('id', id);
            fetchFacilities();
        } catch (e) {
            console.error('Error deleting:', e);
            alert('Failed to delete facility.');
        }
    };

    return (
        <div className="page-container py-8 md:py-12 animate-fade-in relative min-h-[80vh] z-10 px-4">
            <div className="flex justify-between items-center mb-8">
                <h1 className="text-3xl font-black text-white drop-shadow-md tracking-tight">My Facilities</h1>
            </div>

            {loading ? (
                <div className="flex flex-col items-center justify-center py-20">
                    <div className="w-12 h-12 border-4 border-white/30 border-t-white rounded-full animate-spin mb-4"></div>
                </div>
            ) : facilities.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-20 glass-panel rounded-3xl border border-white/20 p-12 text-center max-w-lg mx-auto shadow-2xl relative overflow-hidden">
                    <div className="absolute inset-0 bg-gradient-to-br from-white/10 to-transparent pointer-events-none" />
                    <div className="p-8 bg-white/10 rounded-full mb-6 backdrop-blur-md border border-white/20">
                        <Building2 size={64} className="text-white drop-shadow" />
                    </div>
                    <h3 className="text-2xl font-bold text-white mb-2 drop-shadow">No facilities yet</h3>
                    <p className="text-blue-100/90 mb-8 max-w-xs text-center drop-shadow">Start by adding your first facility to accept bookings</p>
                    <Link to="/facility-owner/facilities/add" className="px-8 py-3 rounded-xl bg-white/20 hover:bg-white/30 flex items-center gap-2 font-bold text-white shadow-lg shadow-black/20 border border-white/30 backdrop-blur-md transition-all hover:-translate-y-1">
                        <Plus size={20} />
                        Add Facility
                    </Link>
                </div>
            ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 pb-24">
                    {facilities.map(f => {
                        const img = (f.images?.length > 0 && f.images[0]) ? f.images[0] : f.image_url;
                        return (
                            <div key={f.id} className="glass-panel rounded-3xl border border-white/20 shadow-xl flex flex-col group overflow-hidden transition-all duration-300 hover:scale-[1.02] hover:shadow-2xl hover:shadow-black/40 hover:border-white/40">

                                {/* Image Box */}
                                <div className="relative w-full aspect-[16/10] bg-black/40">
                                    {img ? (
                                        <div
                                            className="w-full h-full bg-cover bg-center transition-transform duration-500 group-hover:scale-105"
                                            style={{ backgroundImage: `url("${img}")` }}
                                        />
                                    ) : (
                                        <div className="w-full h-full bg-gradient-to-br from-white/10 to-transparent flex items-center justify-center">
                                            <Building2 size={64} className="text-white/20" />
                                        </div>
                                    )}
                                    <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/20 to-transparent opacity-80" />

                                    {/* Highlight Tag */}
                                    {f.highlight_tag && (
                                        <div className="absolute top-4 left-4">
                                            <span className="px-3 py-1.5 rounded-xl bg-white/20 backdrop-blur-md border border-white/30 text-white text-[10px] font-black uppercase tracking-wider shadow-lg flex items-center gap-1.5">
                                                <Tag size={12} />
                                                {f.highlight_tag}
                                            </span>
                                        </div>
                                    )}

                                    <div className="absolute top-4 right-4 bg-black/40 backdrop-blur-md px-3 py-1.5 rounded-xl shadow-lg border border-white/20">
                                        <span className="text-white font-bold text-[10px] tracking-wider uppercase">
                                            {f.sport_type || 'GENERAL'}
                                        </span>
                                    </div>

                                    <div className="absolute bottom-4 left-4 right-4 flex justify-between items-end">
                                        <span className="px-3 py-1.5 rounded-xl bg-white/95 text-black text-sm font-black shadow-lg">
                                            ₹{f.price_per_hour}/hr
                                        </span>
                                    </div>
                                </div>

                                {/* Content */}
                                <div className="p-5 flex flex-col flex-1 relative z-10 bg-gradient-to-b from-transparent to-black/40">
                                    <h3 className="text-[18px] font-black text-white leading-tight mb-2 line-clamp-1 drop-shadow-md">
                                        {f.name || 'Unnamed Venue'}
                                    </h3>

                                    <div className="flex items-center gap-2 mb-5">
                                        <MapPin size={16} className="text-blue-100/70 shrink-0" />
                                        <p className="text-sm font-medium text-blue-100/70 truncate">
                                            {f.location || 'Location missing'}
                                        </p>
                                    </div>

                                    <div className="mt-auto grid grid-cols-2 gap-3 mb-4">
                                        <Link
                                            to={`/facility-owner/facilities/edit/${f.id}`}
                                            className="col-span-1 py-3 bg-white/10 hover:bg-white/20 border border-white/10 hover:border-white/30 backdrop-blur-md text-white rounded-xl font-bold flex items-center justify-center gap-2 transition-all text-sm shadow-lg"
                                        >
                                            <Edit size={16} className="text-blue-200" /> Edit
                                        </Link>
                                        <button
                                            onClick={() => deleteFacility(f.id)}
                                            className="col-span-1 py-3 bg-red-500/10 hover:bg-red-500/20 border border-red-500/20 hover:border-red-500/40 backdrop-blur-md text-red-200 rounded-xl font-bold flex items-center justify-center gap-2 transition-all text-sm shadow-lg"
                                        >
                                            <Trash2 size={16} className="text-red-400" /> Delete
                                        </button>
                                    </div>

                                    <button
                                        onClick={() => navigate(`/facility-owner/facilities/slots/${f.id}`)}
                                        className="w-full flex items-center justify-center gap-2 bg-white/20 hover:bg-white/30 border border-white/30 hover:border-white/50 backdrop-blur-md text-white font-bold py-3.5 rounded-xl transition-all shadow-lg hover:-translate-y-0.5"
                                    >
                                        <Calendar size={18} />
                                        Manage Slots
                                    </button>
                                </div>
                            </div>
                        );
                    })}
                </div>
            )}

            {/* Floating Action Button */}
            {!loading && facilities.length > 0 && (
                <Link
                    to="/facility-owner/facilities/add"
                    className="fixed bottom-8 right-8 z-50 flex items-center gap-2 bg-white/20 hover:bg-white/30 text-white px-6 py-4 rounded-full shadow-2xl shadow-black/40 backdrop-blur-md border hover:-translate-y-1 transition-all border-white/50"
                >
                    <Plus size={20} />
                    <span className="font-bold relative z-10 drop-shadow">Add New Venue</span>
                </Link>
            )}
        </div>
    );
}
