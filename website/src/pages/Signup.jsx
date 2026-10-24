import React, { useState, useRef, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { supabase } from '../supabase';
import { AlertCircle, Dumbbell, Building2, Mail, ArrowLeft, CheckCircle2, RefreshCw } from 'lucide-react';
import OnlyTurfLogo from '../components/OnlyTurfLogo';

export default function Signup() {
    const navigate = useNavigate();
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [step, setStep] = useState('form'); // 'form' | 'otp' | 'success'
    const [formData, setFormData] = useState({
        name: '', email: '', phone: '', password: '', confirmPassword: '', role: 'customer'
    });

    // OTP state
    const [otp, setOtp] = useState(['', '', '', '', '', '']);
    const [resendCooldown, setResendCooldown] = useState(0);
    const inputRefs = useRef([]);

    // Cooldown timer
    useEffect(() => {
        if (resendCooldown > 0) {
            const timer = setTimeout(() => setResendCooldown(resendCooldown - 1), 1000);
            return () => clearTimeout(timer);
        }
    }, [resendCooldown]);

    // Auto-focus first OTP input when step changes
    useEffect(() => {
        if (step === 'otp') {
            setTimeout(() => inputRefs.current[0]?.focus(), 100);
        }
    }, [step]);

    // Auto-submit OTP when all 6 digits are entered
    useEffect(() => {
        if (step === 'otp' && otp.every(d => d !== '') && otp.join('').length === 6) {
            handleVerifyOtp();
        }
    }, [otp]);

    const handleChange = (e) => setFormData({ ...formData, [e.target.name]: e.target.value });

    // Step 1: Create account & send OTP
    const handleSignup = async (e) => {
        e.preventDefault();
        setError('');
        if (formData.password !== formData.confirmPassword) {
            setError('Passwords do not match.');
            return;
        }
        if (formData.password.length < 6) {
            setError('Password must be at least 6 characters.');
            return;
        }
        setLoading(true);
        try {
            const { data, error } = await supabase.auth.signUp({
                email: formData.email,
                password: formData.password,
                options: {
                    data: { full_name: formData.name, phone: formData.phone, role: formData.role }
                }
            });
            if (error) throw error;
            if (data.user) {
                // Create the profile row so that foreign key constraints are satisfied
                const { error: profileError } = await supabase.from('profiles').upsert({
                    id: data.user.id,
                    full_name: formData.name,
                    email: formData.email,
                    phone: formData.phone,
                    role: formData.role
                }, { onConflict: 'id' });
                if (profileError) {
                    console.warn('Profile creation warning:', profileError.message);
                }
                setStep('otp');
                setResendCooldown(60);
            }
        } catch (err) {
            setError(err.message);
        } finally {
            setLoading(false);
        }
    };

    // OTP input handlers
    const handleOtpChange = (index, value) => {
        if (value.length > 1) {
            // Handle paste
            const digits = value.replace(/\D/g, '').slice(0, 6).split('');
            const newOtp = [...otp];
            digits.forEach((d, i) => {
                if (index + i < 6) newOtp[index + i] = d;
            });
            setOtp(newOtp);
            const nextIndex = Math.min(index + digits.length, 5);
            inputRefs.current[nextIndex]?.focus();
            return;
        }

        if (!/^\d*$/.test(value)) return;
        const newOtp = [...otp];
        newOtp[index] = value;
        setOtp(newOtp);

        if (value && index < 5) {
            inputRefs.current[index + 1]?.focus();
        }
    };

    const handleOtpKeyDown = (index, e) => {
        if (e.key === 'Backspace' && !otp[index] && index > 0) {
            inputRefs.current[index - 1]?.focus();
        }
    };

    // Step 2: Verify OTP
    const handleVerifyOtp = async () => {
        const otpString = otp.join('');
        if (otpString.length !== 6) {
            setError('Please enter the complete 6-digit code.');
            return;
        }
        setError('');
        setLoading(true);
        try {
            const { data, error } = await supabase.auth.verifyOtp({
                email: formData.email,
                token: otpString,
                type: 'signup'
            });
            if (error) throw error;
            if (data.user) {
                setStep('success');
            }
        } catch (err) {
            setError(err.message);
            setOtp(['', '', '', '', '', '']);
            inputRefs.current[0]?.focus();
        } finally {
            setLoading(false);
        }
    };

    // Resend OTP
    const handleResendOtp = async () => {
        if (resendCooldown > 0) return;
        setError('');
        setLoading(true);
        try {
            const { error } = await supabase.auth.resend({
                type: 'signup',
                email: formData.email
            });
            if (error) throw error;
            setResendCooldown(60);
            setOtp(['', '', '', '', '', '']);
        } catch (err) {
            setError(err.message);
        } finally {
            setLoading(false);
        }
    };

    const inputClass = "w-full rounded-xl border border-white/80 bg-white/60 px-4 py-3 text-[15px] font-bold text-slate-900 placeholder:text-slate-400 outline-none focus:border-white focus:ring-4 focus:ring-white/50 transition-all shadow-sm backdrop-blur-md";

    // ── Success Screen ──
    if (step === 'success') {
        return (
            <div className="min-h-screen flex items-center justify-center px-4 py-12 relative overflow-hidden">
                <div className="w-full max-w-md relative z-10">
                    <div className="glass-panel p-10 shadow-xl relative overflow-hidden bg-white/40 border-white/60 backdrop-blur-3xl rounded-3xl text-center">
                        <div className="absolute inset-0 bg-gradient-to-br from-white/40 to-transparent pointer-events-none" />
                        <div className="relative z-10">
                            <div className="mx-auto mb-6 flex h-24 w-24 items-center justify-center rounded-full bg-emerald-50 border-2 border-emerald-100 shadow-lg">
                                <CheckCircle2 size={56} className="text-emerald-500" />
                            </div>
                            <h2 className="text-3xl font-black text-slate-900 tracking-tight mb-3">You're In! 🎉</h2>
                            <p className="text-slate-600 font-medium text-[15px] mb-2">
                                Your account has been verified and is ready to go.
                            </p>
                            <p className="text-slate-500 text-sm font-medium mb-8">
                                Welcome to <span className="font-black text-primary">OnlyTurf</span>, {formData.name || 'Champion'}!
                            </p>

                            <div className="flex flex-col gap-3">
                                <button
                                    onClick={() => navigate('/')}
                                    className="w-full h-14 rounded-xl bg-slate-900 text-white font-bold text-lg hover:bg-slate-800 transition-all shadow-md hover:-translate-y-1 border border-transparent"
                                >
                                    Start Exploring
                                </button>
                                <button
                                    onClick={() => navigate('/facilities')}
                                    className="w-full h-12 rounded-xl bg-white/60 border border-white/80 text-slate-700 font-bold text-[15px] hover:bg-white hover:text-primary transition-all shadow-sm hover:-translate-y-0.5"
                                >
                                    Browse Venues
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        );
    }

    // ── OTP Verification Screen ──
    if (step === 'otp') {
        return (
            <div className="min-h-screen flex items-center justify-center px-4 py-12 relative overflow-hidden">
                <div className="w-full max-w-md relative z-10">
                    <div className="text-center mb-8">
                        <Link to="/" className="inline-flex items-center gap-2 mb-6 group">
                            <OnlyTurfLogo size={38} />
                            <span className="text-3xl font-black tracking-tight text-slate-900 transition-colors">OnlyTurf</span>
                        </Link>
                    </div>

                    <div className="glass-panel p-8 shadow-xl relative overflow-hidden bg-white/40 border-white/60 backdrop-blur-3xl rounded-3xl">
                        <div className="absolute inset-0 bg-gradient-to-br from-white/40 to-transparent pointer-events-none" />
                        <div className="relative z-10">
                            {/* Back button */}
                            <button
                                onClick={() => { setStep('form'); setError(''); setOtp(['', '', '', '', '', '']); }}
                                className="flex items-center gap-1.5 text-[14px] font-bold text-slate-500 hover:text-primary mb-6 transition-colors"
                            >
                                <ArrowLeft size={16} />
                                Back to Sign Up
                            </button>

                            {/* Email Icon */}
                            <div className="mx-auto mb-6 flex h-20 w-20 items-center justify-center rounded-full bg-primary/10 border border-primary/20 shadow-sm">
                                <Mail size={40} className="text-primary" />
                            </div>

                            <h2 className="text-2xl font-black text-slate-900 tracking-tight text-center mb-2">Verify Your Email</h2>
                            <p className="text-[15px] text-slate-500 font-medium text-center mb-1">
                                We've sent a 6-digit code to
                            </p>
                            <p className="text-[15px] font-black text-slate-800 text-center mb-8">
                                {formData.email}
                            </p>

                            {error && (
                                <div className="mb-5 flex items-center gap-2 rounded-xl bg-red-50 border border-red-200 p-3 shadow-sm">
                                    <AlertCircle size={18} className="text-red-500 shrink-0" />
                                    <p className="text-[14px] font-medium text-red-700">{error}</p>
                                </div>
                            )}

                            {/* OTP Input Boxes */}
                            <div className="flex justify-center gap-3 mb-8">
                                {otp.map((digit, index) => (
                                    <input
                                        key={index}
                                        ref={(el) => inputRefs.current[index] = el}
                                        type="text"
                                        inputMode="numeric"
                                        maxLength={6}
                                        value={digit}
                                        onChange={(e) => handleOtpChange(index, e.target.value)}
                                        onKeyDown={(e) => handleOtpKeyDown(index, e)}
                                        className={`w-12 h-14 sm:w-14 sm:h-16 rounded-xl border-2 text-center text-2xl font-black outline-none transition-all shadow-sm backdrop-blur-md ${digit
                                            ? 'border-primary bg-primary/5 text-slate-900'
                                            : 'border-white/80 bg-white/60 text-slate-900'
                                            } focus:border-primary focus:ring-4 focus:ring-primary/20`}
                                    />
                                ))}
                            </div>

                            {/* Verify Button */}
                            <button
                                onClick={handleVerifyOtp}
                                disabled={loading || otp.join('').length !== 6}
                                className="w-full h-14 rounded-xl bg-slate-900 text-white font-bold text-lg hover:bg-slate-800 disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-md hover:-translate-y-1 border border-transparent mb-5"
                            >
                                {loading ? (
                                    <span className="flex items-center justify-center gap-2">
                                        <span className="w-5 h-5 rounded-full border-2 border-white/30 border-t-white animate-spin"></span>
                                        Verifying...
                                    </span>
                                ) : 'Verify & Continue'}
                            </button>

                            {/* Resend */}
                            <div className="text-center">
                                <p className="text-[14px] text-slate-500 font-medium mb-2">Didn't receive the code?</p>
                                <button
                                    onClick={handleResendOtp}
                                    disabled={resendCooldown > 0 || loading}
                                    className={`inline-flex items-center gap-1.5 text-[14px] font-bold transition-colors ${resendCooldown > 0
                                        ? 'text-slate-400 cursor-not-allowed'
                                        : 'text-primary hover:text-primary-dark cursor-pointer'
                                        }`}
                                >
                                    <RefreshCw size={14} className={loading ? 'animate-spin' : ''} />
                                    {resendCooldown > 0
                                        ? `Resend in ${resendCooldown}s`
                                        : 'Resend Code'
                                    }
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        );
    }

    // ── Signup Form ──
    return (
        <div className="min-h-screen flex items-center justify-center px-4 py-12 relative overflow-hidden">
            <div className="w-full max-w-md relative z-10">
                <div className="text-center mb-8">
                    <Link to="/" className="inline-flex items-center gap-2 mb-6 group">
                        <OnlyTurfLogo size={38} />
                        <span className="text-3xl font-black tracking-tight text-slate-900 transition-colors">OnlyTurf</span>
                    </Link>
                    <h1 className="text-2xl font-black text-slate-900 tracking-tight">Create Account</h1>
                    <p className="text-[15px] text-slate-500 font-medium mt-1">Start booking your favourite sports venues</p>
                </div>

                <div className="glass-panel p-8 shadow-xl relative overflow-hidden bg-white/40 border-white/60 backdrop-blur-3xl rounded-3xl">
                    <div className="absolute inset-0 bg-gradient-to-br from-white/40 to-transparent pointer-events-none" />
                    {error && (
                        <div className="relative mb-4 flex items-center gap-2 rounded-xl bg-red-50 border border-red-200 p-3 shadow-sm z-10">
                            <AlertCircle size={18} className="text-red-500" />
                            <p className="text-[15px] font-medium text-red-700">{error}</p>
                        </div>
                    )}

                    <form onSubmit={handleSignup} className="flex flex-col gap-4 relative z-10">
                        <div className="flex flex-col gap-1.5">
                            <label className="text-[15px] font-bold text-slate-700 ml-1">Full Name</label>
                            <input type="text" name="name" placeholder="John Doe" value={formData.name} onChange={handleChange} required className={inputClass} />
                        </div>
                        <div className="grid grid-cols-2 gap-3">
                            <div className="flex flex-col gap-1.5">
                                <label className="text-[15px] font-bold text-slate-700 ml-1">Email</label>
                                <input type="email" name="email" placeholder="you@example.com" value={formData.email} onChange={handleChange} required className={inputClass} />
                            </div>
                            <div className="flex flex-col gap-1.5">
                                <label className="text-[15px] font-bold text-slate-700 ml-1">Phone</label>
                                <input type="tel" name="phone" placeholder="+91 9876543210" value={formData.phone} onChange={handleChange} className={inputClass} />
                            </div>
                        </div>
                        <div className="grid grid-cols-2 gap-3">
                            <div className="flex flex-col gap-1.5">
                                <label className="text-[15px] font-bold text-slate-700 ml-1">Password</label>
                                <input type="password" name="password" placeholder="Min 6 chars" value={formData.password} onChange={handleChange} required className={inputClass} />
                            </div>
                            <div className="flex flex-col gap-1.5">
                                <label className="text-[15px] font-bold text-slate-700 ml-1">Confirm</label>
                                <input type="password" name="confirmPassword" placeholder="Repeat password" value={formData.confirmPassword} onChange={handleChange} required className={inputClass} />
                            </div>
                        </div>

                        {/* Role Selection */}
                        <div className="flex flex-col gap-2 mt-2">
                            <label className="text-[15px] font-bold text-slate-700 ml-1">Account Type</label>
                            <div className="grid grid-cols-2 gap-3">
                                {[{ val: 'customer', icon: Dumbbell, label: 'User (Play)' }, { val: 'owner', icon: Building2, label: 'Owner (List)' }].map(({ val, icon: Icon, label }) => (
                                    <label
                                        key={val}
                                        className={`flex items-center justify-center gap-2 p-3 rounded-xl cursor-pointer transition-all shadow-sm ${formData.role === val ? 'bg-slate-900 border border-slate-900 scale-105 shadow-md' : 'bg-white/60 border border-white/80 hover:bg-white hover:border-white'}`}
                                    >
                                        <input type="radio" name="role" value={val} checked={formData.role === val} onChange={handleChange} className="sr-only" />
                                        <Icon size={20} className={formData.role === val ? 'text-white' : 'text-slate-400'} />
                                        <span className={`text-[14px] font-bold ${formData.role === val ? 'text-white' : 'text-slate-600'}`}>{label}</span>
                                    </label>
                                ))}
                            </div>
                        </div>

                        <button
                            type="submit" disabled={loading}
                            className="w-full h-12 rounded-xl bg-slate-900 px-8 text-white font-bold text-lg hover:bg-slate-800 disabled:opacity-50 transition-all shadow-md border border-transparent hover:-translate-y-1 mt-4"
                        >
                            {loading ? (
                                <span className="flex items-center justify-center gap-2">
                                    <span className="w-5 h-5 rounded-full border-2 border-white/30 border-t-white animate-spin"></span>
                                    Creating Account...
                                </span>
                            ) : 'Create Account'}
                        </button>
                    </form>

                    <div className="relative z-10 mt-8 pt-6 border-t border-white/80 text-center text-[15px] font-medium text-slate-600">
                        Already have an account?{' '}
                        <Link to="/login" className="font-bold text-primary hover:underline transition-colors">Sign In</Link>
                    </div>
                </div>
            </div>
        </div>
    );
}
