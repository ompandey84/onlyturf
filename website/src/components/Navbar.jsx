import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { useApp } from '../context/AppContext';
import { Sun, Moon, ChevronDown, Calendar, LayoutDashboard, LogOut, X, Menu, MapPin } from 'lucide-react';
import OnlyTurfLogo from './OnlyTurfLogo';

export default function Navbar() {
    const { user, role, signOut } = useAuth();
    const { selectedCity, setSelectedCity, indianCities, darkMode, setDarkMode, appMode, setAppMode } = useApp();
    const navigate = useNavigate();
    const [menuOpen, setMenuOpen] = useState(false);
    const [userMenuOpen, setUserMenuOpen] = useState(false);
    const [isScrolled, setIsScrolled] = useState(false);

    useEffect(() => {
        const handleScroll = () => {
            setIsScrolled(window.scrollY > 20);
        };
        window.addEventListener('scroll', handleScroll);
        return () => window.removeEventListener('scroll', handleScroll);
    }, []);

    const handleSignOut = async () => {
        await signOut();
        navigate('/');
        setUserMenuOpen(false);
        setMenuOpen(false);
    };

    const userLinks = [
        { to: '/', label: 'Home' },
        { to: '/facilities', label: 'Facilities' },
    ];

    const ownerLinks = [
        { to: '/facility-owner/dashboard', label: 'Dashboard' },
        { to: '/facility-owner/bookings', label: 'Bookings' },
        { to: '/facility-owner/facilities', label: 'My Facilities' },
        { to: '/facility-owner/profile', label: 'Profile' },
    ];

    const isOwnerContext = (role === 'owner' || role === 'admin') && appMode === 'owner';
    const activeLinks = isOwnerContext ? ownerLinks : userLinks;

    return (
        <nav className={`fixed w-full z-50 transition-all duration-300 ${isScrolled ? 'py-2 mt-2 px-4 md:px-8' : 'py-4 mt-2 px-4 md:px-8'}`}>
            <div className={`mx-auto max-w-7xl transition-all duration-300 rounded-2xl ${isScrolled ? 'glass-panel shadow-xl border border-white/60 backdrop-blur-xl' : 'bg-transparent'}`}>
                <div className={`flex items-center justify-between transition-all duration-300 ${isScrolled ? 'h-16 px-6' : 'h-20 px-4'}`}>

                    <div className="flex items-center gap-8 lg:gap-12">
                        {/* Logo */}
                        <Link to="/" className="flex items-center gap-2 shrink-0 group">
                            <OnlyTurfLogo size={38} />
                            <span className="text-[24px] font-black tracking-tight text-slate-800 group-hover:text-primary transition-colors">OnlyTurf</span>
                        </Link>

                        {/* Desktop Nav */}
                        <nav className="hidden lg:flex items-center gap-2">
                            {activeLinks.map(({ to, label }) => (
                                <Link
                                    key={to}
                                    to={to}
                                    className="px-4 py-2 rounded-xl text-[15px] font-bold text-slate-600 hover:text-primary hover:bg-white/40 border border-transparent hover:border-white/60 transition-all backdrop-blur-sm"
                                >
                                    {label}
                                </Link>
                            ))}
                        </nav>
                    </div>

                    {/* Right Controls */}
                    <div className="flex items-center gap-3 ml-auto">
                        {/* City Selector */}
                        <div className="hidden sm:flex flex-row items-center bg-white/50 backdrop-blur-md rounded-xl border border-white/80 hover:border-white transition-colors px-3 shadow-[0_2px_10px_rgba(0,0,0,0.02)]">
                            <MapPin size={16} className="text-primary shrink-0" />
                            <select
                                value={selectedCity}
                                onChange={(e) => setSelectedCity(e.target.value)}
                                className="h-10 bg-transparent text-slate-800 px-2 pr-6 text-sm font-bold outline-none cursor-pointer appearance-none max-w-[160px] md:max-w-xs truncate"
                            >
                                {indianCities.map(city => (
                                    <option key={city} value={city} className="bg-white text-slate-800">{city}</option>
                                ))}
                            </select>
                            <ChevronDown size={14} className="text-slate-400 shrink-0 pointer-events-none absolute right-3" />
                        </div>

                        {/* Dark Mode Toggle - Hidden as glass theme acts as dark mode inherently, keeping logic just in case it's heavily tied to App */}
                        <button
                            onClick={() => setDarkMode(!darkMode)}
                            className="hidden sm:flex h-10 w-10 items-center justify-center rounded-xl bg-white/50 hover:bg-white/80 backdrop-blur-md border border-white/80 transition-colors text-slate-600 hover:text-primary shadow-[0_2px_10px_rgba(0,0,0,0.02)]"
                            title="Toggle dark mode"
                        >
                            {darkMode ? <Sun size={18} /> : <Moon size={18} />}
                        </button>

                        {/* Auth / User */}
                        {user ? (
                            <div className="relative">
                                <button
                                    onClick={() => setUserMenuOpen(!userMenuOpen)}
                                    className="flex items-center gap-2 h-10 px-3 rounded-xl bg-white/50 hover:bg-white/80 backdrop-blur-md border border-white/80 transition-colors shadow-[0_2px_10px_rgba(0,0,0,0.02)]"
                                >
                                    <div className="w-7 h-7 rounded-full bg-primary/10 border border-primary/20 flex items-center justify-center">
                                        <span className="text-primary text-xs font-black">
                                            {user.email?.[0]?.toUpperCase()}
                                        </span>
                                    </div>
                                    <span className="hidden sm:block text-[15px] font-bold text-slate-800 max-w-[90px] truncate">
                                        {user.email?.split('@')[0]}
                                    </span>
                                    <ChevronDown size={16} className="text-slate-400" />
                                </button>

                                {userMenuOpen && (
                                    <div className="absolute right-0 top-full mt-3 w-56 glass-panel rounded-2xl shadow-xl border border-white/80 overflow-hidden animate-fade-in z-50">
                                        <div className="px-4 py-4 border-b border-slate-100 bg-white/40">
                                            <p className="text-xs font-bold text-slate-500 uppercase tracking-wider mb-1">Signed in as</p>
                                            <p className="text-sm font-bold text-slate-900 truncate">{user.email}</p>
                                        </div>
                                        <div className="py-2 bg-white/40">
                                            <Link
                                                to="/dashboard"
                                                onClick={() => setUserMenuOpen(false)}
                                                className="flex items-center gap-3 px-4 py-2.5 text-sm font-bold text-slate-700 hover:text-primary hover:bg-white/60 transition-colors"
                                            >
                                                <Calendar size={18} className="text-primary" />
                                                My Bookings
                                            </Link>
                                            {(role === 'owner' || role === 'admin') && (
                                                <button
                                                    onClick={() => {
                                                        const newMode = appMode === 'owner' ? 'user' : 'owner';
                                                        setAppMode(newMode);
                                                        setUserMenuOpen(false);
                                                        navigate(newMode === 'owner' ? '/facility-owner/dashboard' : '/');
                                                    }}
                                                    className="w-full flex items-center gap-3 px-4 py-2.5 text-sm font-bold text-slate-700 hover:text-emerald-600 hover:bg-white/60 transition-colors text-left"
                                                >
                                                    <LayoutDashboard size={18} className="text-emerald-500" />
                                                    {appMode === 'owner' ? 'Switch to User' : 'Switch to Owner'}
                                                </button>
                                            )}
                                            <button
                                                onClick={handleSignOut}
                                                className="w-full flex items-center gap-3 px-4 py-2.5 text-sm font-bold text-red-500 hover:text-red-600 hover:bg-red-50 transition-colors text-left"
                                            >
                                                <LogOut size={18} />
                                                Sign Out
                                            </button>
                                        </div>
                                    </div>
                                )}
                            </div>
                        ) : (
                            <div className="flex items-center gap-3">
                                <Link to="/login">
                                    <button className="h-10 px-5 rounded-xl text-[15px] font-bold text-slate-700 bg-white/50 hover:bg-white/90 backdrop-blur-md border border-white/80 shadow-sm transition-colors">
                                        Login
                                    </button>
                                </Link>
                                <Link to="/signup" className="hidden sm:block">
                                    <button className="h-10 px-5 rounded-xl text-[15px] font-bold text-white bg-slate-900 hover:bg-slate-800 transition-all shadow-md shadow-slate-900/20 hover:-translate-y-0.5">
                                        Sign Up
                                    </button>
                                </Link>
                            </div>
                        )}

                        {/* Mobile Hamburger */}
                        <button
                            onClick={() => setMenuOpen(!menuOpen)}
                            className="md:hidden flex h-10 w-10 items-center justify-center rounded-xl bg-white/50 backdrop-blur-md border border-white/80 text-slate-800 shadow-sm hover:bg-white/80 transition-colors"
                        >
                            {menuOpen ? <X size={20} /> : <Menu size={20} />}
                        </button>
                    </div>
                </div>
            </div>

            {/* Mobile Menu */}
            {menuOpen && (
                <div className={`md:hidden absolute top-full left-4 right-4 mt-2 transition-all duration-300 origin-top transform ${menuOpen ? 'scale-y-100 opacity-100' : 'scale-y-0 opacity-0 pointer-events-none'}`}>
                    <div className="glass-panel rounded-2xl p-5 flex flex-col gap-2 shadow-xl border border-white/80 relative overflow-hidden bg-white/80 backdrop-blur-2xl">
                        <div className="absolute inset-0 bg-gradient-to-br from-white/40 to-transparent pointer-events-none" />
                        <div className="relative z-10 flex flex-col gap-2">
                            {activeLinks.map(({ to, label }) => (
                                <Link
                                    key={to}
                                    to={to}
                                    onClick={() => setMenuOpen(false)}
                                    className="flex items-center gap-3 px-4 py-3.5 rounded-xl text-[15px] font-bold text-slate-800 hover:bg-white/60 hover:text-primary transition-colors"
                                >
                                    {label}
                                </Link>
                            ))}
                            {(role === 'owner' || role === 'admin') && (
                                <button
                                    onClick={() => {
                                        const newMode = appMode === 'owner' ? 'user' : 'owner';
                                        setAppMode(newMode);
                                        setMenuOpen(false);
                                        navigate(newMode === 'owner' ? '/facility-owner/dashboard' : '/');
                                    }}
                                    className="w-full text-left flex items-center gap-3 px-4 py-3.5 rounded-xl text-[15px] font-bold text-emerald-600 hover:bg-emerald-50 transition-colors"
                                >
                                    <LayoutDashboard size={18} />
                                    {appMode === 'owner' ? 'Switch to User' : 'Switch to Owner'}
                                </button>
                            )}
                            <div className="border-t border-slate-200 mt-3 pt-4">
                                {/* City Picker */}
                                <div className="relative mb-3">
                                    <select
                                        value={selectedCity}
                                        onChange={(e) => setSelectedCity(e.target.value)}
                                        className="w-full h-12 rounded-xl bg-white/60 text-slate-800 px-4 text-[15px] font-bold outline-none border border-white/80 appearance-none backdrop-blur-md shadow-sm"
                                    >
                                        {indianCities.map(city => (
                                            <option key={city} value={city} className="bg-white text-slate-800">{city}</option>
                                        ))}
                                    </select>
                                    <MapPin size={18} className="absolute right-4 top-1/2 -translate-y-1/2 text-primary pointer-events-none" />
                                </div>
                                <div className="flex gap-3">
                                    {!user && (
                                        <Link to="/login" onClick={() => setMenuOpen(false)} className="flex-1">
                                            <button className="w-full h-12 rounded-xl bg-slate-900 text-white text-[15px] font-bold border border-transparent shadow-md hover:bg-slate-800 transition-colors">Login</button>
                                        </Link>
                                    )}
                                    {user && (
                                        <button onClick={handleSignOut} className="flex-1 h-12 rounded-xl bg-red-50 text-red-600 text-[15px] font-bold border border-red-100 hover:bg-red-100 transition-colors">
                                            Sign Out
                                        </button>
                                    )}
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </nav>
    );
}
