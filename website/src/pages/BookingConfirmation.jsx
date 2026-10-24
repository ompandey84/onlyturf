import React, { useState } from 'react';
import { useLocation, Link, useNavigate } from 'react-router-dom';
import { supabase } from '../supabase';
import { useAuth } from '../context/AuthContext';
import { AlertCircle, CheckCircle2, ArrowLeft, Calendar, Clock, Activity, IndianRupee, Smartphone, Copy, Check } from 'lucide-react';

const UPI_PAYEE_ID = '9770511893@ptaxis';
const UPI_PAYEE_NAME = 'OnlyTurf';

function generateUpiLink(amount, facilityName, bookingRef) {
    const params = new URLSearchParams({
        pa: UPI_PAYEE_ID,
        pn: UPI_PAYEE_NAME,
        am: String(amount),
        tn: `${facilityName} - ${bookingRef}`,
        cu: 'INR',
    });
    return `upi://pay?${params.toString()}`;
}

export default function BookingConfirmation() {
    const location = useLocation();
    const navigate = useNavigate();
    const { user } = useAuth();
    const { facility, date, slot } = location.state || {};
    const [loading, setLoading] = useState(false);
    const [confirmed, setConfirmed] = useState(false);
    const [copied, setCopied] = useState(false);

    if (!facility || !date || !slot) {
        return (
            <div className="flex min-h-[60vh] items-center justify-center flex-col gap-4 relative z-10">
                <AlertCircle size={48} className="text-slate-400" />
                <p className="text-slate-600 font-medium">Invalid booking details.</p>
                <Link to="/" className="h-12 px-6 flex items-center justify-center rounded-xl bg-slate-900 text-white font-bold hover:bg-slate-800 transition-all shadow-md">Go Home</Link>
            </div>
        );
    }

    const [startStr, endStr] = slot.split(' - ');
    const startTime = `${startStr}:00`;
    const endTime = `${endStr}:00`;
    const bookingRef = `BK${Date.now().toString(36).toUpperCase()}`;

    const confirmBooking = async () => {
        if (!user) return;
        setLoading(true);
        try {
            await supabase.from('profiles').upsert({
                id: user.id,
                email: user.email,
                role: user.user_metadata?.role || 'customer',
                full_name: user.user_metadata?.full_name || user.email?.split('@')[0] || '',
            }, { onConflict: 'id', ignoreDuplicates: true });

            const { error } = await supabase.from('bookings').insert([{
                user_id: user.id,
                facility_id: facility.id,
                date: date,
                time_slot: slot,
                status: 'confirmed',
                total_price: facility.price_per_hour
            }]);
            if (error) throw error;
            setConfirmed(true);
        } catch (e) {
            alert('Failed to book: ' + e.message);
        } finally {
            setLoading(false);
        }
    };

    const handlePayUpi = () => {
        const upiLink = generateUpiLink(facility.price_per_hour, facility.name, bookingRef);
        window.location.href = upiLink;
    };

    const handleCopyUpi = async () => {
        try {
            await navigator.clipboard.writeText(UPI_PAYEE_ID);
            setCopied(true);
            setTimeout(() => setCopied(false), 2000);
        } catch {
            const el = document.createElement('textarea');
            el.value = UPI_PAYEE_ID;
            document.body.appendChild(el);
            el.select();
            document.execCommand('copy');
            document.body.removeChild(el);
            setCopied(true);
            setTimeout(() => setCopied(false), 2000);
        }
    };

    if (confirmed) {
        return (
            <div className="min-h-screen flex items-center justify-center px-4 relative z-10">
                <div className="glass-panel w-full max-w-md bg-white/40 border-white/60 backdrop-blur-3xl rounded-3xl shadow-xl p-8 text-center animate-fade-in relative overflow-hidden">
                    <div className="absolute inset-0 bg-gradient-to-br from-white/40 to-transparent pointer-events-none" />
                    <div className="mx-auto mb-6 flex h-20 w-20 items-center justify-center rounded-full bg-emerald-50 border border-emerald-100 shadow-sm relative z-10">
                        <CheckCircle2 size={48} className="text-emerald-500" />
                    </div>
                    <h2 className="text-2xl font-black text-slate-900 tracking-tight mb-2 relative z-10">Booking Confirmed!</h2>
                    <p className="text-slate-600 font-medium mb-2 relative z-10">
                        Your slot at <strong className="text-slate-900 font-black">{facility.name}</strong> has been secured.
                    </p>
                    <p className="text-[15px] font-bold text-slate-500 mb-6 relative z-10">
                        {date} &middot; {slot}
                    </p>

                    {/* UPI Payment Section */}
                    <div className="relative z-10 mb-6 p-5 rounded-2xl bg-white/60 border border-white/80 shadow-sm text-left">
                        <div className="flex items-center gap-2 mb-3">
                            <IndianRupee size={18} className="text-emerald-600" />
                            <span className="text-[15px] font-black text-slate-900">Pay Rs. {facility.price_per_hour}</span>
                        </div>

                        <button
                            onClick={handlePayUpi}
                            className="w-full h-12 rounded-xl bg-[#5f259f] text-white font-bold text-[15px] hover:bg-[#4a1d7a] transition-all shadow-md hover:-translate-y-0.5 flex items-center justify-center gap-2 mb-3"
                        >
                            <Smartphone size={18} />
                            Pay via UPI App
                        </button>

                        <div className="flex items-center gap-2">
                            <div className="flex-1 px-3 py-2 rounded-lg bg-white/80 border border-white text-[13px] font-bold text-slate-600 truncate">
                                UPI: {UPI_PAYEE_ID}
                            </div>
                            <button
                                onClick={handleCopyUpi}
                                className="h-9 px-3 rounded-lg bg-white/80 border border-white/80 text-[13px] font-bold text-slate-600 hover:bg-white hover:text-primary transition-all flex items-center gap-1.5 shrink-0"
                            >
                                {copied ? <><Check size={14} className="text-emerald-500" /> Copied</> : <><Copy size={14} /> Copy</>}
                            </button>
                        </div>
                        <p className="text-[11px] font-medium text-slate-400 mt-2 text-center">
                            Opens GPay, PhonePe, Paytm etc. on mobile
                        </p>
                    </div>

                    <div className="flex flex-col gap-3 relative z-10">
                        <Link to="/dashboard" className="h-12 flex items-center justify-center rounded-xl bg-slate-900 text-white font-bold hover:bg-slate-800 transition-all shadow-md hover:-translate-y-0.5">View My Bookings</Link>
                        <Link to="/facilities" className="h-12 flex items-center justify-center rounded-xl bg-white/60 border border-white/80 text-slate-700 font-bold hover:bg-white hover:text-primary transition-all shadow-sm hover:-translate-y-0.5">Book Another</Link>
                    </div>
                </div>
            </div>
        );
    }

    const imgSrc = facility.images?.[0] || facility.image_url || 'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=400&q=80';

    return (
        <div className="min-h-screen flex items-center justify-center px-4 py-12 relative z-10">
            <div className="w-full max-w-lg">
                <button onClick={() => navigate(-1)} className="flex items-center gap-1.5 text-[15px] font-bold text-slate-600 hover:text-primary mb-6 transition-colors">
                    <ArrowLeft size={20} className="text-slate-400" />
                    Go Back
                </button>

                <div className="glass-panel bg-white/40 border-white/60 backdrop-blur-3xl rounded-3xl shadow-xl p-8 relative overflow-hidden">
                    <div className="absolute inset-0 bg-gradient-to-br from-white/40 to-transparent pointer-events-none" />
                    <h1 className="text-2xl font-black text-slate-900 tracking-tight mb-6 relative z-10">Confirm Booking</h1>

                    {/* Facility */}
                    <div className="flex gap-4 items-center mb-6 p-4 rounded-2xl bg-white/60 border border-white/80 shadow-sm relative z-10">
                        <div
                            className="h-16 w-20 rounded-xl bg-cover bg-center shrink-0 shadow-sm"
                            style={{ backgroundImage: `url("${imgSrc}")` }}
                        />
                        <div>
                            <h3 className="font-black text-slate-900 tracking-tight">{facility.name}</h3>
                            <p className="text-[13px] font-bold text-slate-500">{facility.location}, {facility.city}</p>
                            <span className="text-[13px] text-primary font-black mt-1 inline-block">{facility.sport_type}</span>
                        </div>
                    </div>

                    {/* Booking Details */}
                    <div className="rounded-2xl border border-white/80 bg-white/60 shadow-sm divide-y divide-white/80 mb-8 relative z-10">
                        {[
                            { label: 'Date', value: new Date(date).toLocaleDateString('en-IN', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' }), icon: Calendar },
                            { label: 'Time Slot', value: slot, icon: Clock },
                            { label: 'Sport', value: facility.sport_type, icon: Activity },
                        ].map(({ label, value, icon: Icon }) => (
                            <div key={label} className="flex items-center justify-between px-5 py-4">
                                <div className="flex items-center gap-2.5 text-[15px] font-bold text-slate-600">
                                    <Icon size={18} className="text-slate-400" />
                                    {label}
                                </div>
                                <span className="text-[15px] font-black text-slate-900">{value}</span>
                            </div>
                        ))}
                        <div className="flex items-center justify-between px-5 py-5 bg-white/40 rounded-b-2xl">
                            <span className="font-black text-slate-600">Total Amount</span>
                            <span className="text-2xl font-black text-emerald-600">Rs. {facility.price_per_hour}</span>
                        </div>
                    </div>

                    <button
                        onClick={confirmBooking}
                        disabled={loading}
                        className="w-full h-14 rounded-xl bg-slate-900 text-white font-bold text-lg hover:bg-slate-800 disabled:opacity-50 transition-all shadow-md hover:-translate-y-1 relative z-10 border border-transparent"
                    >
                        {loading ? (
                            <span className="flex items-center justify-center gap-2">
                                <span className="w-5 h-5 rounded-full border-2 border-white/30 border-t-white animate-spin"></span>
                                Processing...
                            </span>
                        ) : 'Confirm & Pay'}
                    </button>
                    <p className="text-[13px] font-bold text-slate-500 text-center mt-5 relative z-10">
                        By confirming, you agree to our terms and cancellation policy.
                    </p>
                </div>
            </div>
        </div>
    );
}
