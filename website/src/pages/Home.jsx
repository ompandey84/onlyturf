import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { supabase } from '../supabase';
import { useApp } from '../context/AppContext';
import FacilityCard from '../components/FacilityCard';

import { Dumbbell, Clock, CheckCircle2, ShieldCheck, CreditCard, Headset, ArrowRight, Dribbble } from 'lucide-react';

const features = [
    { icon: Dumbbell, title: 'Pro Equipment', desc: 'Top-tier gear maintained daily for your best performance on every court and field.' },
    { icon: Clock, title: '24/7 Access', desc: 'Book and play anytime, day or night, with our automated entry systems.' },
    { icon: CheckCircle2, title: 'Instant Confirmation', desc: 'Secure your spot immediately with real-time availability and instant booking.' },
    { icon: ShieldCheck, title: 'Verified Venues', desc: 'Every facility is inspected and verified to meet our quality standards.' },
    { icon: CreditCard, title: 'Flexible Payment', desc: 'Pay securely online. Transparent pricing with no hidden charges.' },
    { icon: Headset, title: '24/7 Support', desc: 'Our support team is always ready to help you with any questions or concerns.' },
];

const stats = [
    { value: '500+', label: 'Venues' },
    { value: '50K+', label: 'Bookings' },
    { value: '40+', label: 'Cities' },
    { value: '4.8★', label: 'Rating' },
];

export default function Home() {
    const { selectedCity } = useApp();
    const [facilities, setFacilities] = useState([]);
    const [banners, setBanners] = useState([]);
    const [currentBanner, setCurrentBanner] = useState(0);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchFacilities();
        fetchBanners();
    }, [selectedCity]);

    // Banner auto-play
    useEffect(() => {
        if (banners.length <= 1) return;
        const interval = setInterval(() => {
            setCurrentBanner(prev => (prev + 1) % banners.length);
        }, 4000);
        return () => clearInterval(interval);
    }, [banners]);

    const fetchFacilities = async () => {
        try {
            setLoading(true);
            const { data, error } = await supabase.from('facilities').select('*').limit(6);
            if (error) throw error;
            setFacilities(data || []);
        } catch (e) {
            console.error(e);
        } finally {
            setLoading(false);
        }
    };

    const fetchBanners = async () => {
        try {
            const { data } = await supabase.from('app_banners').select('*').eq('is_active', true).order('created_at', { ascending: false });
            if (data?.length) setBanners(data);
        } catch (e) {
            console.error(e);
        }
    };

    const heroImg = banners.length > 0
        ? banners[currentBanner]?.image_url
        : 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=1600&q=80';

    const heroTitle = banners[currentBanner]?.title || 'Elevate Your Game';
    const heroSubtitle = banners[currentBanner]?.subtitle || 'Experience world-class facilities at your fingertips. Book your spot instantly.';

    return (
        <div className="flex flex-col">
            {/* ── Hero ── */}
            <section className="relative w-full h-[70vh] min-h-[500px] max-h-[750px] overflow-hidden">
                {/* Background */}
                <div
                    className="absolute inset-0 bg-cover bg-center transition-all duration-1000"
                    style={{ backgroundImage: `url("${heroImg}")` }}
                />
                <div className="absolute inset-0 bg-gradient-to-b from-black/50 via-black/40 to-black/70" />

                {/* Content */}
                <div className="relative z-10 h-full flex flex-col items-center justify-center text-center px-4">
                    <div className="animate-fade-in-up max-w-4xl">
                        <h1 className="text-4xl sm:text-5xl md:text-6xl lg:text-7xl font-black text-white leading-tight mb-4 drop-shadow-2xl">
                            {heroTitle}
                        </h1>
                        <p className="text-white/90 text-lg md:text-xl max-w-2xl mx-auto mb-8 drop-shadow">
                            {heroSubtitle}
                        </p>

                        <div className="flex flex-wrap items-center justify-center gap-2 mb-6">
                            <Link to="/facilities">
                                <button className="h-12 px-8 rounded-xl bg-primary hover:bg-[var(--primary-dark)] text-white font-bold text-[15px] shadow-lg shadow-primary/30 hover:shadow-primary/50 transition-all hover:-translate-y-0.5">
                                    Book a Court
                                </button>
                            </Link>
                            <Link to="/facilities">
                                <button className="h-12 px-8 rounded-xl bg-white/20 backdrop-blur-md border border-white/40 text-white font-bold text-[15px] hover:bg-white/30 transition-all shadow-md">
                                    Explore Venues
                                </button>
                            </Link>
                        </div>
                    </div>

                    {/* Carousel Dots */}
                    {banners.length > 1 && (
                        <div className="flex gap-2">
                            {banners.map((_, i) => (
                                <button
                                    key={i}
                                    onClick={() => setCurrentBanner(i)}
                                    className={`h-2 rounded-full transition-all ${i === currentBanner ? 'bg-white w-6' : 'bg-white/40 w-2'}`}
                                />
                            ))}
                        </div>
                    )}
                </div>

                {/* Stats Bar */}
                <div className="absolute bottom-0 left-0 right-0 bg-white/60 backdrop-blur-2xl border-t border-white/80 shadow-[0_-4px_20px_rgba(0,0,0,0.05)]">
                    <div className="page-container py-4">
                        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-center">
                            {stats.map(({ value, label }) => (
                                <div key={label} className="flex flex-col">
                                    <span className="text-2xl font-black text-slate-800">{value}</span>
                                    <span className="text-xs text-slate-500 font-bold uppercase tracking-wider">{label}</span>
                                </div>
                            ))}
                        </div>
                    </div>
                </div>
            </section>

            <section className="py-16 md:py-24 relative z-10">
                <div className="page-container">
                    <div className="text-center mb-12">
                        <span className="inline-block px-4 py-1.5 rounded-full bg-white/60 text-primary text-sm font-bold mb-4 backdrop-blur-md border border-white/80 shadow-sm">Why Choose Us</span>
                        <h2 className="text-4xl md:text-5xl font-black text-slate-900 tracking-tight">Everything You Need to Play</h2>
                        <p className="mt-4 max-w-xl mx-auto text-slate-600 font-medium text-lg">
                            We've built the best platform for athletes to discover and book sports facilities.
                        </p>
                    </div>

                    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
                        {features.map(({ icon: Icon, title, desc }) => (
                            <div key={title} className="group flex flex-col gap-4 p-8 glass-panel rounded-3xl border border-white/80 shadow-lg hover:shadow-xl hover:bg-white/60 hover:border-white transition-all duration-300 hover:-translate-y-1 relative overflow-hidden bg-white/40">
                                <div className="absolute inset-0 bg-gradient-to-br from-white/40 to-transparent pointer-events-none" />
                                <div className="relative z-10 w-14 h-14 rounded-2xl bg-white/80 backdrop-blur-md flex items-center justify-center text-primary group-hover:bg-white group-hover:text-primary transition-all duration-300 border border-white shadow-sm">
                                    <Icon size={28} />
                                </div>
                                <div className="relative z-10">
                                    <h3 className="text-xl font-black text-slate-800 mb-2">{title}</h3>
                                    <p className="text-[15px] text-slate-600 leading-relaxed font-medium">{desc}</p>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
            </section>

            {/* ── Popular Facilities ── */}
            <section className="py-16 md:py-20 relative z-10">
                <div className="page-container relative z-10">
                    <div className="flex items-center justify-between mb-8">
                        <div>
                            <h2 className="text-3xl md:text-4xl font-black text-slate-900 tracking-tight">Popular in <span className="text-primary">{selectedCity}</span></h2>
                            <p className="text-slate-500 font-medium mt-2 text-lg">Top-rated venues near you</p>
                        </div>
                        <Link to="/facilities" className="flex flex-col sm:flex-row items-center gap-2 px-4 py-2 rounded-xl bg-white/60 hover:bg-white/90 backdrop-blur-md border border-white/80 text-[15px] font-bold text-slate-700 transition-all shadow-sm hover:-translate-y-0.5">
                            <span className="hidden sm:inline">View All</span>
                            <ArrowRight size={18} />
                        </Link>
                    </div>

                    {loading ? (
                        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
                            {[...Array(6)].map((_, i) => (
                                <div key={i} className="glass-panel overflow-hidden">
                                    <div className="skeleton aspect-[16/10] opacity-50" />
                                    <div className="p-4">
                                        <div className="skeleton h-4 rounded w-3/4 mb-2 opacity-50" />
                                        <div className="skeleton h-3 rounded w-1/2 opacity-50" />
                                    </div>
                                </div>
                            ))}
                        </div>
                    ) : facilities.length === 0 ? (
                        <div className="glass-panel text-center py-16">
                            <Dribbble size={64} className="mx-auto text-white/30 mb-4" />
                            <p className="mt-4 text-white/70">No facilities found in {selectedCity}. Try another city!</p>
                        </div>
                    ) : (
                        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
                            {facilities.map(f => <FacilityCard key={f.id} facility={f} />)}
                        </div>
                    )}
                </div>
            </section>

            {/* ── CTA Banner ── */}
            <section className="py-16 md:py-24 relative overflow-hidden z-10 mt-12 bg-white/30 backdrop-blur-2xl border-t border-white/60">
                <div className="absolute inset-0 bg-gradient-to-r from-primary/5 to-transparent pointer-events-none" />
                <div className="page-container text-center relative z-10">
                    <h2 className="text-3xl md:text-5xl font-black text-slate-900 mb-6">
                        Ready to Play?
                    </h2>
                    <p className="text-slate-600 font-medium text-lg mb-10 max-w-xl mx-auto">
                        Join thousands of athletes who book their favourite sports venues on OnlyTurf every day.
                    </p>
                    <div className="flex flex-col sm:flex-row gap-4 justify-center">
                        <Link to="/signup">
                            <button className="w-full sm:w-auto h-14 px-8 rounded-xl bg-slate-900 text-white font-bold text-[15px] hover:bg-slate-800 shadow-xl shadow-slate-900/20 transition-all hover:-translate-y-1 border border-transparent">
                                Get Started Free
                            </button>
                        </Link>
                        <Link to="/facilities">
                            <button className="w-full sm:w-auto h-14 px-8 rounded-xl bg-white/70 hover:bg-white backdrop-blur-md text-slate-800 font-bold text-[15px] transition-all border border-white/80 shadow-sm hover:-translate-y-1">
                                Browse Venues
                            </button>
                        </Link>
                    </div>
                </div>
            </section>
        </div>
    );
}
