import React, { useEffect, useState } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { supabase } from '../supabase';
import { useAuth } from '../context/AuthContext';
import { ArrowLeft, CheckCircle2 } from 'lucide-react';

const generateSlots = () => {
    const slots = [];
    for (let i = 6; i < 23; i++) {
        const s = i < 10 ? `0${i}:00` : `${i}:00`;
        const e = (i + 1) < 10 ? `0${i + 1}:00` : `${i + 1}:00`;
        slots.push(`${s} - ${e}`);
    }
    return slots;
};

const ALL_SLOTS = generateSlots();

export default function BookingPage() {
    const { id } = useParams();
    const navigate = useNavigate();
    const { user } = useAuth();

    const [facility, setFacility] = useState(null);
    const [loading, setLoading] = useState(true);
    const [selectedDate, setSelectedDate] = useState(new Date().toISOString().split('T')[0]);
    const [bookedSlots, setBookedSlots] = useState([]);
    const [selectedSlot, setSelectedSlot] = useState(null);

    useEffect(() => {
        if (id) { fetchFacility(); }
    }, [id]);

    useEffect(() => {
        if (id && selectedDate) { fetchBookings(); }
    }, [id, selectedDate]);

    const fetchFacility = async () => {
        try {
            setLoading(true);
            const { data, error } = await supabase.from('facilities').select('*').eq('id', id).single();
            if (error) throw error;
            setFacility(data);
        } catch (e) { console.error(e); }
        finally { setLoading(false); }
    };

    const fetchBookings = async () => {
        try {
            const { data } = await supabase.from('bookings').select('time_slot').eq('facility_id', id).eq('date', selectedDate).neq('status', 'cancelled');
            const booked = (data || []).map(b => b.time_slot);
            setBookedSlots(booked);
        } catch (e) { console.error(e); }
    };

    const handleBook = () => {
        if (!user) { navigate('/login'); return; }
        if (!selectedSlot) return;
        navigate('/booking-confirmation', { state: { facility, date: selectedDate, slot: selectedSlot } });
    };

    if (loading) return (
        <div className="min-h-screen page-container py-12 relative z-10">
            <div className="glass-panel h-12 w-48 mb-8 rounded-3xl border border-white/60 shadow-md bg-white/40 relative overflow-hidden backdrop-blur-2xl">
                <div className="absolute inset-0 skeleton bg-white/40" />
            </div>
            <div className="glass-panel h-[500px] w-full max-w-xl mx-auto rounded-3xl border border-white/60 shadow-xl bg-white/40 relative overflow-hidden backdrop-blur-2xl">
                <div className="absolute inset-0 skeleton bg-white/40" />
            </div>
        </div>
    );

    if (!facility) return (
        <div className="flex h-[60vh] items-center justify-center">
            <div className="glass-panel p-8 text-center rounded-3xl border border-white/60 shadow-xl bg-white/40 backdrop-blur-2xl">
                <h2 className="text-2xl font-black text-slate-900 tracking-tight">Facility not found</h2>
                <p className="text-slate-600 font-medium mt-2">The facility you are looking for does not exist.</p>
            </div>
        </div>
    );

    return (
        <div className="min-h-screen relative z-10">
            <div className="glass-panel mx-4 mt-24 mb-8 rounded-3xl border border-white/60 shadow-sm overflow-hidden relative bg-white/40 backdrop-blur-2xl">
                <div className="absolute inset-0 bg-gradient-to-r from-white/40 to-transparent pointer-events-none" />
                <div className="page-container py-4 flex items-center gap-3 relative z-10">
                    <button onClick={() => navigate(-1)} className="flex items-center gap-2 text-[15px] font-bold text-slate-600 hover:text-primary transition-all hover:-translate-x-1 group">
                        <ArrowLeft size={20} className="text-slate-400 group-hover:text-primary transition-colors" />
                        Back to Venue
                    </button>
                    <span className="text-slate-300">|</span>
                    <span className="text-[15px] font-bold text-slate-800">{facility.name}</span>
                </div>
            </div>

            <div className="page-container py-8 flex justify-center">
                <div className="w-full max-w-xl glass-panel p-8 shadow-xl relative overflow-hidden bg-white/40 border-white/60 backdrop-blur-3xl rounded-3xl">
                    <div className="absolute inset-0 bg-gradient-to-br from-white/40 to-transparent pointer-events-none" />
                    <h1 className="text-3xl font-black text-slate-900 mb-6 text-center tracking-tight relative z-10">Complete Booking</h1>

                    {!user ? (
                        <div className="flex flex-col items-center justify-center py-10 px-4 text-center bg-white/60 border border-white/80 rounded-2xl shadow-sm relative z-10">
                            <h2 className="text-xl font-black text-slate-900 mb-2">Login Required</h2>
                            <p className="text-[15px] text-slate-600 font-medium mb-6">
                                Please sign in to view available time slots and book this venue.
                            </p>
                            <button
                                onClick={() => navigate('/login')}
                                className="w-full h-14 rounded-xl bg-slate-900 text-white font-bold text-lg hover:bg-slate-800 transition-all shadow-md  hover:-translate-y-1 relative z-10 border border-transparent"
                            >
                                Login to View Slots
                            </button>
                        </div>
                    ) : (
                        <>
                            {/* Date */}
                            <div className="mb-6 relative z-10">
                                <label className="block text-[15px] font-bold text-slate-700 mb-2 ml-1">Select Date</label>
                                <input
                                    type="date"
                                    value={selectedDate}
                                    min={new Date().toISOString().split('T')[0]}
                                    onChange={(e) => { setSelectedDate(e.target.value); setSelectedSlot(null); }}
                                    className="w-full rounded-2xl border border-white/80 bg-white/60 backdrop-blur-md px-4 py-3.5 text-base font-bold text-slate-800 outline-none focus:border-white focus:ring-4 focus:ring-white/50 transition-all shadow-sm"
                                />
                            </div>

                            {/* Legend */}
                            <div className="flex justify-center gap-5 mb-6 text-[13px] font-bold text-slate-500 relative z-10">
                                <span className="flex items-center gap-1.5"><span className="w-3.5 h-3.5 rounded-md bg-white/60 border border-white/80"></span>Available</span>
                                <span className="flex items-center gap-1.5"><span className="w-3.5 h-3.5 rounded-md bg-slate-900 border border-slate-900 shadow-sm"></span>Selected</span>
                                <span className="flex items-center gap-1.5"><span className="w-3.5 h-3.5 rounded-md bg-red-50 border border-red-200"></span>Booked</span>
                            </div>

                            {/* Slots */}
                            <div className="mb-8 relative z-10">
                                <label className="block text-[15px] font-bold text-slate-700 mb-3 ml-1">Time Slots</label>
                                <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 max-h-[300px] overflow-y-auto pr-2 custom-scrollbar">
                                    {ALL_SLOTS.map(slot => {
                                        const isBooked = bookedSlots.includes(slot);
                                        const isSelected = selectedSlot === slot;
                                        return (
                                            <button
                                                key={slot}
                                                disabled={isBooked}
                                                onClick={() => !isBooked && setSelectedSlot(isSelected ? null : slot)}
                                                className={`slot-btn px-2 py-3.5 rounded-xl text-[13px] font-bold transition-all border shadow-sm flex justify-center items-center ${isBooked ? 'bg-red-50 border-red-200 text-red-600 opacity-60 cursor-not-allowed' :
                                                    isSelected ? 'bg-slate-900 border-slate-900 text-white shadow-md scale-105' :
                                                        'bg-white/60 border-white/80 text-slate-600 hover:bg-white hover:border-white hover:text-primary backdrop-blur-md'
                                                    }`}
                                            >
                                                {slot}
                                            </button>
                                        );
                                    })}
                                </div>
                            </div>

                            {/* Summary */}
                            <div className="bg-white/60 backdrop-blur-md border border-white/80 shadow-sm rounded-2xl p-5 mb-8 relative z-10">
                                <div className="flex justify-between items-center text-[15px] mb-3">
                                    <span className="font-bold text-slate-500">Selected Slot</span>
                                    <span className="font-black text-slate-900">{selectedSlot || '—'}</span>
                                </div>
                                <div className="flex justify-between items-center pt-3 border-t border-white/80">
                                    <span className="font-bold text-slate-500">Total Amount</span>
                                    <span className="font-black text-emerald-600 text-2xl">₹{selectedSlot ? facility.price_per_hour : 0}</span>
                                </div>
                            </div>

                            <button
                                onClick={handleBook}
                                disabled={!selectedSlot}
                                className="w-full h-14 rounded-xl bg-slate-900 text-white font-bold text-lg hover:bg-slate-800 disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-md  hover:-translate-y-1 relative z-10 border border-transparent"
                            >
                                Proceed to Pay
                            </button>
                        </>
                    )}
                </div>
            </div>
        </div>
    );
}
