import React from 'react';
import { Link } from 'react-router-dom';
import { Trophy, Home } from 'lucide-react';

export default function NotFound() {
    return (
        <div className="min-h-[70vh] flex flex-col items-center justify-center px-4 text-center relative z-10 py-12">
            <div className="glass-panel w-full max-w-md bg-white/40 border-white/60 backdrop-blur-3xl rounded-3xl p-12 shadow-xl relative overflow-hidden">
                <div className="absolute inset-0 bg-gradient-to-br from-white/40 to-transparent pointer-events-none" />
                <div className="w-20 h-20 rounded-2xl bg-white/60 border border-white/80 flex items-center justify-center mx-auto mb-6 shadow-sm relative z-10">
                    <Trophy size={48} className="text-primary" />
                </div>
                <h1 className="text-7xl font-black text-slate-900 tracking-tight mb-2 relative z-10">404</h1>
                <h2 className="text-2xl font-black text-slate-900 tracking-tight mb-3 relative z-10">Page Not Found</h2>
                <p className="text-[15px] font-bold text-slate-500 mb-8 relative z-10">
                    Looks like you missed the goal! This page doesn't exist.
                </p>
                <div className="flex flex-col gap-3 relative z-10">
                    <Link to="/" className="h-12 flex items-center justify-center rounded-xl bg-slate-900 text-white font-bold hover:bg-slate-800 transition-all shadow-md hover:-translate-y-0.5">
                        <Home size={18} className="mr-1.5" />
                        Back to Home
                    </Link>
                    <Link to="/facilities" className="h-12 flex items-center justify-center rounded-xl bg-white/60 border border-white/80 text-slate-700 font-bold hover:bg-white hover:text-primary transition-all shadow-sm hover:-translate-y-0.5">Browse Facilities</Link>
                </div>
            </div>
        </div>
    );
}
