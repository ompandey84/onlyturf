import React from 'react';
import { Link } from 'react-router-dom';
import { Users, Target, Heart, Award, MapPin } from 'lucide-react';
import OnlyTurfLogo from '../components/OnlyTurfLogo';

export default function AboutUs() {
    const stats = [
        { value: '500+', label: 'Venues Listed' },
        { value: '10K+', label: 'Happy Players' },
        { value: '50K+', label: 'Games Booked' },
        { value: '15+', label: 'Sports' },
    ];

    const values = [
        { icon: Target, title: 'Our Mission', desc: 'To make sports accessible for everyone in Indore by connecting players with the best venues in their area.' },
        { icon: Heart, title: 'Built with Love', desc: 'We are a team of sports enthusiasts from Indore who believe everyone deserves access to world-class sports facilities.' },
        { icon: Users, title: 'Community First', desc: 'OnlyTurf is not just a booking platform - it is a community of athletes, beginners, and weekend warriors.' },
        { icon: Award, title: 'Quality Assured', desc: 'Every venue on our platform is personally verified to ensure quality courts, clean facilities, and fair pricing.' },
    ];

    return (
        <div className="min-h-screen">
            {/* Hero */}
            <div className="glass-panel mx-4 mt-24 mb-6 rounded-3xl border border-white/60 shadow-xl relative overflow-hidden bg-white/40 backdrop-blur-3xl">
                <div className="absolute inset-0 bg-gradient-to-br from-white/40 to-transparent pointer-events-none" />
                <div className="page-container py-16 px-6 sm:px-10 lg:px-12 relative z-10 text-center">
                    <div className="inline-flex items-center gap-2 mb-6">
                        <OnlyTurfLogo size={48} />
                    </div>
                    <h1 className="text-4xl md:text-5xl font-black text-slate-900 mb-4 tracking-tight animate-fade-in-up">About OnlyTurf</h1>
                    <p className="text-slate-600 font-medium text-lg max-w-2xl mx-auto animate-fade-in-up" style={{ animationDelay: '0.1s' }}>
                        Indore's favourite platform for finding, comparing, and booking sports venues.
                        We're on a mission to get more people playing, one booking at a time.
                    </p>
                </div>
            </div>

            <div className="page-container py-10 relative z-10">
                {/* Stats */}
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-12">
                    {stats.map((s, i) => (
                        <div key={s.label} className="glass-panel p-6 rounded-2xl border border-white/60 bg-white/40 text-center animate-fade-in-up" style={{ animationDelay: `${i * 0.1}s` }}>
                            <p className="text-3xl font-black text-slate-900 mb-1">{s.value}</p>
                            <p className="text-sm font-bold text-slate-500">{s.label}</p>
                        </div>
                    ))}
                </div>

                {/* Values */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-12">
                    {values.map((v, i) => (
                        <div key={v.title} className="glass-panel p-8 rounded-3xl border border-white/60 bg-white/40 animate-fade-in-up" style={{ animationDelay: `${i * 0.1}s` }}>
                            <div className="w-12 h-12 rounded-xl bg-primary/10 border border-primary/20 flex items-center justify-center mb-4">
                                <v.icon size={24} className="text-primary" />
                            </div>
                            <h3 className="text-xl font-black text-slate-900 mb-2 tracking-tight">{v.title}</h3>
                            <p className="text-slate-600 font-medium leading-relaxed">{v.desc}</p>
                        </div>
                    ))}
                </div>

                {/* Location */}
                <div className="glass-panel p-10 rounded-3xl border border-white/60 bg-white/40 text-center animate-fade-in-up">
                    <div className="inline-flex items-center gap-2 mb-4">
                        <MapPin size={24} className="text-primary" />
                        <h3 className="text-2xl font-black text-slate-900 tracking-tight">Made in Indore 🏏</h3>
                    </div>
                    <p className="text-slate-600 font-medium text-lg max-w-xl mx-auto mb-6">
                        We're proudly based in Indore, Madhya Pradesh. Our platform is designed specifically for the sports community of our city.
                    </p>
                    <Link to="/facilities" className="inline-flex h-12 items-center justify-center px-8 rounded-xl bg-slate-900 text-white font-bold text-[15px] shadow-lg hover:bg-slate-800 transition-all hover:-translate-y-0.5">
                        Explore Venues
                    </Link>
                </div>
            </div>
        </div>
    );
}
