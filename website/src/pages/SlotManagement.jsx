import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { supabase } from '../supabase';
import { useAuth } from '../context/AuthContext';
import { ArrowLeft, Calendar, Lock, Unlock, CheckCircle2 } from 'lucide-react';
import { formatDate } from '../utils/dateUtils';

export default function SlotManagement() {
    const { id } = useParams();
    const navigate = useNavigate();
    const { user } = useAuth();

    const [facility, setFacility] = useState(null);
    const [bookings, setBookings] = useState([]);
    const [loading, setLoading] = useState(true);
    const [selectedDate, setSelectedDate] = useState(new Date());

    // Simple 1-hour slots from 6 AM to 11 PM
    const timeSlots = [
        '06:00 AM', '07:00 AM', '08:00 AM', '09:00 AM', '10:00 AM', '11:00 AM',
        '12:00 PM', '01:00 PM', '02:00 PM', '03:00 PM', '04:00 PM', '05:00 PM',
        '06:00 PM', '07:00 PM', '08:00 PM', '09:00 PM', '10:00 PM', '11:00 PM'
    ];

    const makeTimeSlotString = (startTime) => {
        const [time, period] = startTime.split(' ');
        let [hour, minute] = time.split(':');
        hour = parseInt(hour, 10);

        let nextHour = hour + 1;
        let nextPeriod = period;

        if (nextHour === 12) {
            nextPeriod = period === 'AM' ? 'PM' : 'AM';
        } else if (nextHour === 13) {
            nextHour = 1;
        }

        const nextTime = `${nextHour.toString().padStart(2, '0')}:${minute} ${nextPeriod}`;
        return `${startTime} - ${nextTime}`;
    };

    const fetchAllData = async () => {
        setLoading(true);
        try {
            const { data: fac } = await supabase
                .from('facilities')
                .select('*')
                .eq('id', id)
                .single();
            setFacility(fac);

            const dateStr = selectedDate.toISOString().split('T')[0];
            const { data: bks } = await supabase
                .from('bookings')
                .select('*, profiles(full_name, phone_number)')
                .eq('facility_id', id)
                .eq('date', dateStr);

            setBookings(bks || []);
        } catch (e) {
            console.error(e);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchAllData();
    }, [id, selectedDate]);

    const handleBlockSlot = async (slotString) => {
        try {
            const dateStr = selectedDate.toISOString().split('T')[0];
            const { error } = await supabase.from('bookings').insert([{
                facility_id: id,
                date: dateStr,
                time_slot: slotString,
                user_id: user.id,
                status: 'blocked',
                total_price: 0,
            }]);
            if (error) throw error;
            fetchAllData();
        } catch (e) {
            console.error(e);
            alert('Failed to block slot');
        }
    };

    const handleUnblockSlot = async (bookingId) => {
        try {
            await supabase.from('bookings').delete().eq('id', bookingId);
            fetchAllData();
        } catch (e) {
            console.error(e);
            alert('Failed to unblock slot');
        }
    };

    const StatusBox = ({ slotString, booking }) => {
        const isBooked = !!booking;
        const isBlocked = isBooked && booking.status === 'blocked';
        const isCustomer = isBooked && !isBlocked;

        if (isCustomer) {
            return (
                <div className="bg-red-50 border border-red-200 backdrop-blur-md rounded-xl p-4 flex flex-col items-center justify-center text-center gap-2 h-24 shadow-sm">
                    <Lock size={18} className="text-red-500" />
                    <span className="text-xs font-bold text-red-700">Booked</span>
                </div>
            );
        }

        if (isBlocked) {
            return (
                <div
                    onClick={() => {
                        if (window.confirm('Unblock this slot?')) {
                            handleUnblockSlot(booking.id);
                        }
                    }}
                    className="bg-slate-100 border border-slate-300 backdrop-blur-md rounded-xl p-4 flex flex-col items-center justify-center text-center gap-2 h-24 cursor-pointer hover:bg-slate-200 hover:border-slate-400 transition-all shadow-sm"
                >
                    <Unlock size={18} className="text-slate-500" />
                    <span className="text-xs font-bold text-slate-700">Blocked</span>
                </div>
            );
        }

        return (
            <div
                onClick={() => {
                    if (window.confirm('Block this slot?')) {
                        handleBlockSlot(slotString);
                    }
                }}
                className="bg-white/60 border border-white/80 backdrop-blur-md rounded-xl p-4 flex flex-col items-center justify-center text-center gap-2 h-24 cursor-pointer hover:border-primary hover:bg-white hover:text-primary transition-all shadow-sm hover:-translate-y-1 group"
            >
                <CheckCircle2 size={18} className="text-slate-400 group-hover:text-primary transition-colors" />
                <span className="text-xs font-bold text-slate-700 group-hover:text-primary transition-colors">Available</span>
            </div>
        );
    };

    if (loading && !facility) {
        return (
            <div className="page-container flex h-[60vh] items-center justify-center">
                <div className="w-12 h-12 border-4 border-white/30 border-t-white rounded-full animate-spin"></div>
            </div>
        );
    }

    return (
        <div className="page-container py-8 animate-fade-in relative z-10 px-4">
            <button
                onClick={() => navigate('/facility-owner/facilities')}
                className="mb-8 flex items-center gap-2 text-slate-600 hover:text-primary transition-colors"
            >
                <ArrowLeft size={18} />
                <span className="font-semibold">Back to Facilities</span>
            </button>

            <div className="flex flex-col md:flex-row md:items-end justify-between gap-4 mb-8">
                <div>
                    <h1 className="text-3xl font-black text-slate-900 tracking-tight mb-2">{facility?.name}</h1>
                    <p className="text-slate-500 font-medium">Manage time slots and availability</p>
                </div>

                <div className="relative w-full md:w-auto">
                    <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                        <Calendar size={18} className="text-slate-400" />
                    </div>
                    <input
                        type="date"
                        value={selectedDate.toISOString().split('T')[0]}
                        onChange={(e) => {
                            if (e.target.value) {
                                setSelectedDate(new Date(e.target.value));
                            }
                        }}
                        className="w-full md:w-auto bg-white/60 backdrop-blur-md border border-white/80 rounded-xl pl-12 pr-4 py-3 text-sm font-bold text-slate-800 focus:outline-none focus:border-white focus:ring-4 focus:ring-white/50 appearance-none cursor-pointer shadow-sm"
                    />
                </div>
            </div>

            <div className="glass-panel p-6 md:p-8 shadow-xl rounded-3xl relative overflow-hidden bg-white/40 border-white/60 backdrop-blur-2xl">
                <div className="absolute inset-0 bg-gradient-to-br from-white/40 to-transparent pointer-events-none" />
                <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-4 relative z-10">
                    {timeSlots.map(startTime => {
                        const slotString = makeTimeSlotString(startTime);
                        const booking = bookings.find(b => b.time_slot === slotString);

                        return (
                            <div key={startTime} className="flex flex-col gap-2">
                                <span className="text-xs font-bold text-slate-500 text-center">
                                    {startTime}
                                </span>
                                <StatusBox slotString={slotString} booking={booking} />
                            </div>
                        );
                    })}
                </div>
            </div>
        </div>
    );
}
