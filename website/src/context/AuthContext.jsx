import React, { createContext, useContext, useEffect, useState } from 'react';
import { supabase } from '../supabase';

const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
    const [user, setUser] = useState(null);
    const [role, setRole] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const getSession = async () => {
            console.log('AuthContext: Fetching session...');
            try {
                const { data: { session }, error } = await supabase.auth.getSession();
                if (error) {
                    console.error('AuthContext: getSession error:', error);
                }

                if (session?.user) {
                    console.log('AuthContext: User found:', session.user.id);
                    setUser(session.user);
                    await fetchUserRole(session.user.id);
                } else {
                    console.log('AuthContext: No active session.');
                    setLoading(false);
                }
            } catch (err) {
                console.error('AuthContext: getSession exception:', err);
                setLoading(false);
            }
        };
        getSession();

        const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event, session) => {
            console.log('AuthContext: onAuthStateChange event:', event, ' session:', !!session);
            if (session?.user) {
                setUser(session.user);
                await fetchUserRole(session.user.id);
            } else {
                setUser(null);
                setRole(null);
                setLoading(false);
            }
        });

        return () => subscription.unsubscribe();
    }, []);

    const fetchUserRole = async (userId) => {
        console.log('AuthContext: Fetching role for user:', userId);

        // Timeout promise to prevent indefinite hang
        const timeoutPromise = new Promise((_, reject) =>
            setTimeout(() => reject(new Error('fetchUserRole: Timeout after 5s')), 5000)
        );

        try {
            const fetchPromise = (async () => {
                const { data, error } = await supabase
                    .from('profiles')
                    .select('role')
                    .eq('id', userId)
                    .single();

                if (error) {
                    console.error('AuthContext: fetchUserRole database error:', error);
                    throw error;
                }
                return data;
            })();

            const data = await Promise.race([fetchPromise, timeoutPromise]);

            console.log('AuthContext: Role fetched successfully:', data?.role);
            setRole(data?.role || 'customer');
        } catch (err) {
            console.warn('AuthContext: fetchUserRole failed or timed out, defaulting to customer:', err.message);
            setRole('customer');
        } finally {
            console.log('AuthContext: fetchUserRole complete (or timed out), setting loading to false.');
            setLoading(false);
        }
    };

    const signOut = async () => {
        await supabase.auth.signOut();
    };

    return (
        <AuthContext.Provider value={{ user, role, loading, signOut }}>
            {loading ? (
                <div className="min-h-screen bg-[#f6f7f8] dark:bg-[#101922] flex flex-col">
                    <div className="h-16 bg-white dark:bg-[#1a2632] border-b border-[#f0f2f4] dark:border-gray-800 flex items-center px-4 md:px-8">
                        <div className="skeleton w-32 h-6 rounded-md"></div>
                        <div className="hidden md:flex gap-4 ml-8">
                            <div className="skeleton w-16 h-4 rounded-md"></div>
                            <div className="skeleton w-20 h-4 rounded-md"></div>
                        </div>
                    </div>
                    <div className="flex-1 p-8">
                        <div className="skeleton w-64 h-8 rounded-lg mb-6"></div>
                        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
                            {[1, 2, 3].map(i => (
                                <div key={i} className="skeleton w-full h-64 rounded-2xl"></div>
                            ))}
                        </div>
                    </div>
                </div>
            ) : children}
        </AuthContext.Provider>
    );
};

export const useAuth = () => useContext(AuthContext);
