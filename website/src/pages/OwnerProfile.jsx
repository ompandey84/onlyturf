import React from 'react';
import { useAuth } from '../context/AuthContext';
import { LogOut, User, Mail, ShieldCheck } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

export default function OwnerProfile() {
    const { user, signOut } = useAuth();
    const navigate = useNavigate();

    const handleSignOut = async () => {
        await signOut();
        navigate('/');
    };

    return (
        <div className="page-container py-8 md:py-12 animate-fade-in">
            <div className="max-w-2xl mx-auto">
                <h1 className="text-3xl font-bold text-[#111418] dark:text-white mb-2">Owner Profile</h1>
                <p className="text-[#617589] dark:text-gray-400 mb-8">Manage your account details and access level.</p>

                <div className="bg-white dark:bg-[#1a2632] rounded-2xl p-6 shadow-sm border border-[#f0f2f4] dark:border-gray-800">
                    <div className="flex items-center gap-6 mb-8">
                        <div className="w-20 h-20 rounded-full bg-primary/10 flex items-center justify-center">
                            <span className="text-primary text-3xl font-bold">
                                {user?.email?.[0]?.toUpperCase()}
                            </span>
                        </div>
                        <div>
                            <h2 className="text-xl font-bold text-[#111418] dark:text-white mb-1">
                                {user?.email?.split('@')[0]}
                            </h2>
                            <div className="flex items-center gap-2 text-sm text-[#617589] dark:text-gray-400">
                                <ShieldCheck size={16} className="text-green-500" />
                                Facility Owner Account
                            </div>
                        </div>
                    </div>

                    <div className="space-y-4">
                        <div className="flex items-center gap-4 p-4 rounded-xl bg-[#f6f7f8] dark:bg-[#111418]">
                            <Mail size={20} className="text-[#617589]" />
                            <div>
                                <p className="text-xs font-semibold text-[#617589] uppercase tracking-wider">Email Address</p>
                                <p className="text-sm font-medium text-[#111418] dark:text-white">{user?.email}</p>
                            </div>
                        </div>

                        <div className="flex items-center gap-4 p-4 rounded-xl bg-[#f6f7f8] dark:bg-[#111418]">
                            <User size={20} className="text-[#617589]" />
                            <div>
                                <p className="text-xs font-semibold text-[#617589] uppercase tracking-wider">Account ID</p>
                                <p className="text-sm font-medium text-[#111418] dark:text-white font-mono">{user?.id}</p>
                            </div>
                        </div>
                    </div>

                    <div className="mt-8 pt-8 border-t border-[#f0f2f4] dark:border-gray-800">
                        <button
                            onClick={handleSignOut}
                            className="w-full flex items-center justify-center gap-2 bg-red-50 hover:bg-red-100 dark:bg-red-900/20 dark:hover:bg-red-900/40 text-red-600 font-semibold py-4 rounded-xl transition-all"
                        >
                            <LogOut size={20} />
                            Sign Out Securely
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
}
