import React, { useEffect, useState } from 'react';
import { useSearchParams, useNavigate, Link } from 'react-router-dom';
import { supabase } from '../supabase';
import { useAuth } from '../context/AuthContext';
import { amenitiesList } from '../constants';
import * as Icons from 'lucide-react';
import { ArrowLeft, MapPin, CheckCircle2, ShieldCheck, Tag, ScrollText, Star, ThumbsUp } from 'lucide-react';

const getAmenityIcon = (name) => {
    const defaultIcon = <Icons.CheckCircle2 size={18} className="text-primary" />;
    const mapped = amenitiesList.find(a => a.name === name);
    if (!mapped || !mapped.icon) return defaultIcon;
    const IconComponent = Icons[mapped.icon];
    return IconComponent ? <IconComponent size={18} className="text-primary" /> : defaultIcon;
};

// Fake reviews data
const FAKE_REVIEWS = [
    { name: 'Rahul Sharma', rating: 5, time: '2 days ago', text: 'Mast jagah hai bhai! Turf ki quality ekdum top-notch. Har weekend yahi aata hoon ab. 🔥' },
    { name: 'Priya Patel', rating: 4, time: '5 days ago', text: 'Bahut acchi facility hai, lights bhi proper hain. Bas parking thoda door hai but overall worth it!' },
    { name: 'Arjun Malhotra', rating: 5, time: '1 week ago', text: 'Bhai ye turf toh next level hai! Grass quality itni smooth hai ki sliding tackle maar ke maza aa gaya 😂' },
    { name: 'Sneha Gupta', rating: 4, time: '1 week ago', text: 'Girls group ke saath aayi thi, staff bahut cooperative tha. Changing room bhi clean hai. Will come again!' },
    { name: 'Vikram Singh', rating: 5, time: '2 weeks ago', text: 'Cricket ke liye best turf in Indore. Pitch bahut acchi hai aur bounce bhi consistent milta hai. Paisa vasool! 💯' },
    { name: 'Ananya Desai', rating: 3, time: '2 weeks ago', text: 'Achha hai but weekend pe bahut rush hota hai. Advance booking karo toh sahi rahega. Facility wise no complaints.' },
    { name: 'Kunal Joshi', rating: 5, time: '3 weeks ago', text: 'Arre waah! Night lights mein match ka feel hi alag hai. Friends ke saath 2 ghante khele, full paisa vasool. 🏏' },
    { name: 'Divya Thakur', rating: 4, time: '1 month ago', text: 'Badminton court ki flooring bahut acchi hai. AC bhi chal raha tha. Premium feel aata hai idhar. Recommended!' },
];

function ReviewCard({ review, index }) {
    const initials = review.name.split(' ').map(n => n[0]).join('');
    return (
        <div
            className="glass-panel p-5 rounded-2xl border border-white/60 bg-white/40 backdrop-blur-md animate-fade-in-up"
            style={{ animationDelay: `${index * 0.08}s` }}
        >
            <div className="flex items-start gap-3">
                <div className="w-10 h-10 rounded-full bg-primary/10 border border-primary/20 flex items-center justify-center shrink-0">
                    <span className="text-primary text-sm font-black">{initials}</span>
                </div>
                <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between gap-2 mb-1">
                        <h4 className="text-[15px] font-black text-slate-900 truncate">{review.name}</h4>
                        <span className="text-[12px] font-bold text-slate-400 shrink-0">{review.time}</span>
                    </div>
                    <div className="flex items-center gap-0.5 mb-2">
                        {[...Array(5)].map((_, i) => (
                            <Star
                                key={i}
                                size={14}
                                className={i < review.rating ? 'text-amber-400 fill-amber-400' : 'text-slate-200'}
                            />
                        ))}
                    </div>
                    <p className="text-[14px] text-slate-600 font-medium leading-relaxed">{review.text}</p>
                </div>
            </div>
        </div>
    );
}

function ImageWithLoader({ src, alt, className }) {
    const [loaded, setLoaded] = useState(false);
    return (
        <div className={`relative overflow-hidden ${className}`}>
            {!loaded && (
                <div className="absolute inset-0 skeleton bg-white/40 rounded-2xl" />
            )}
            <img
                src={src}
                alt={alt}
                className={`w-full h-full object-cover transition-opacity duration-500 ${loaded ? 'opacity-100' : 'opacity-0'}`}
                onLoad={() => setLoaded(true)}
            />
        </div>
    );
}

export default function FacilityDetails() {
    const [searchParams] = useSearchParams();
    const navigate = useNavigate();
    const { user } = useAuth();
    const facilityId = searchParams.get('id');

    const [facility, setFacility] = useState(null);
    const [loading, setLoading] = useState(true);
    const [activeImg, setActiveImg] = useState(0);

    useEffect(() => {
        window.scrollTo(0, 0);
        if (facilityId) { fetchFacility(); }
    }, [facilityId]);

    const fetchFacility = async () => {
        try {
            setLoading(true);
            const { data, error } = await supabase.from('facilities').select('*').eq('id', facilityId).single();
            if (error) throw error;
            setFacility(data);
        } catch (e) { console.error(e); }
        finally { setLoading(false); }
    };

    if (loading) return (
        <div className="min-h-screen animate-fade-in">
            {/* Back nav shimmer */}
            <div className="glass-panel mx-4 mt-24 mb-6 rounded-3xl border border-white/60 bg-white/40 backdrop-blur-2xl">
                <div className="page-container py-4">
                    <div className="skeleton h-5 w-32 rounded-lg bg-white/60"></div>
                </div>
            </div>

            <div className="page-container py-8">
                <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                    <div className="lg:col-span-2 flex flex-col gap-6">
                        {/* Main image shimmer */}
                        <div className="flex flex-col gap-3">
                            <div className="skeleton w-full h-[320px] md:h-[420px] rounded-2xl bg-white/40 relative overflow-hidden">
                                <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent animate-pulse"></div>
                            </div>
                            <div className="flex gap-2">
                                {[1, 2, 3, 4].map(i => (
                                    <div key={i} className="skeleton h-16 w-16 rounded-xl bg-white/40"></div>
                                ))}
                            </div>
                        </div>

                        {/* Title & Location shimmer */}
                        <div className="glass-panel p-6 bg-white/40 border border-white/60 rounded-3xl">
                            <div className="skeleton h-8 w-3/4 rounded-lg mb-3 bg-white/60"></div>
                            <div className="skeleton h-5 w-1/3 rounded-lg mb-4 bg-white/60"></div>
                            <div className="flex gap-3">
                                <div className="skeleton h-7 w-24 rounded-full bg-white/50"></div>
                                <div className="skeleton h-7 w-28 rounded-full bg-white/50"></div>
                            </div>
                        </div>

                        {/* About shimmer */}
                        <div className="glass-panel p-6 bg-white/40 border border-white/60 rounded-3xl">
                            <div className="skeleton h-6 w-48 rounded-lg mb-4 bg-white/60"></div>
                            <div className="space-y-2">
                                <div className="skeleton h-4 w-full rounded bg-white/60"></div>
                                <div className="skeleton h-4 w-5/6 rounded bg-white/60"></div>
                                <div className="skeleton h-4 w-4/6 rounded bg-white/60"></div>
                            </div>
                        </div>

                        {/* Amenities shimmer */}
                        <div className="glass-panel p-6 bg-white/40 border border-white/60 rounded-3xl">
                            <div className="skeleton h-6 w-32 rounded-lg mb-4 bg-white/60"></div>
                            <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                                {[1, 2, 3, 4, 5, 6].map(i => (
                                    <div key={i} className="flex items-center gap-2">
                                        <div className="skeleton h-5 w-5 rounded bg-white/50"></div>
                                        <div className="skeleton h-4 w-20 rounded bg-white/60"></div>
                                    </div>
                                ))}
                            </div>
                        </div>

                        {/* Reviews shimmer */}
                        <div className="glass-panel p-6 bg-white/40 border border-white/60 rounded-3xl">
                            <div className="skeleton h-6 w-48 rounded-lg mb-4 bg-white/60"></div>
                            <div className="space-y-4">
                                {[1, 2, 3].map(i => (
                                    <div key={i} className="flex gap-3">
                                        <div className="skeleton h-10 w-10 rounded-full bg-white/50 shrink-0"></div>
                                        <div className="flex-1 space-y-2">
                                            <div className="skeleton h-4 w-32 rounded bg-white/60"></div>
                                            <div className="skeleton h-3 w-20 rounded bg-white/50"></div>
                                            <div className="skeleton h-4 w-full rounded bg-white/60"></div>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        </div>
                    </div>

                    {/* Booking widget shimmer */}
                    <div className="lg:col-span-1">
                        <div className="glass-panel p-6 bg-white/40 border border-white/60 rounded-3xl">
                            <div className="skeleton h-6 w-40 rounded-lg mb-6 bg-white/60"></div>
                            <div className="flex justify-between items-center mb-6">
                                <div className="skeleton h-4 w-28 rounded bg-white/60"></div>
                                <div className="skeleton h-8 w-20 rounded bg-white/60"></div>
                            </div>
                            <div className="skeleton h-14 w-full rounded-xl bg-white/50 mb-6"></div>
                            <div className="space-y-3">
                                <div className="skeleton h-4 w-44 rounded bg-white/60"></div>
                                <div className="skeleton h-4 w-36 rounded bg-white/60"></div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );

    if (!facility) return (
        <div className="flex h-[60vh] items-center justify-center animate-fade-in">
            <div className="glass-panel p-8 text-center rounded-3xl border border-white/60 shadow-xl bg-white/40 backdrop-blur-2xl">
                <h2 className="text-2xl font-black text-slate-900 tracking-tight">Facility not found</h2>
                <p className="text-slate-600 font-medium mt-2">The facility you are looking for does not exist or has been removed.</p>
                <Link to="/facilities" className="mt-6 inline-block px-6 py-2 rounded-xl bg-slate-900 text-white font-bold backdrop-blur-md shadow-md hover:bg-slate-800 transition-colors">
                    Browse Facilities
                </Link>
            </div>
        </div>
    );

    const images = (facility.images?.length > 0 && facility.images[0]) ? facility.images : [facility.image_url || 'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=800&q=80'];

    // Pick random reviews (seeded by facility id for consistency)
    const reviewSeed = facility.id ? facility.id.charCodeAt(0) % 4 : 0;
    const displayReviews = [...FAKE_REVIEWS].slice(reviewSeed, reviewSeed + 5);
    if (displayReviews.length < 5) displayReviews.push(...FAKE_REVIEWS.slice(0, 5 - displayReviews.length));
    const avgRating = (displayReviews.reduce((acc, r) => acc + r.rating, 0) / displayReviews.length).toFixed(1);

    return (
        <div className="min-h-screen">
            {/* Back Nav */}
            <div className="glass-panel mx-4 mt-24 mb-6 rounded-3xl border border-white/60 shadow-md overflow-hidden relative bg-white/40 backdrop-blur-2xl animate-fade-in">
                <div className="absolute inset-0 bg-gradient-to-r from-white/40 to-transparent pointer-events-none" />
                <div className="page-container py-4 flex items-center gap-3 relative z-10">
                    <Link to="/facilities" className="flex items-center gap-2 text-[15px] font-bold text-slate-600 hover:text-primary transition-all hover:-translate-x-1 group">
                        <ArrowLeft size={20} className="text-slate-400 group-hover:text-primary transition-colors" />
                        Back to Facilities
                    </Link>
                </div>
            </div>

            <div className="page-container py-8">
                <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                    {/* LEFT: Details */}
                    <div className="lg:col-span-2 flex flex-col gap-6">
                        {/* Image Gallery */}
                        <div className="flex flex-col gap-3 animate-fade-in-up">
                            <ImageWithLoader
                                src={images[activeImg]}
                                alt={facility.name}
                                className="w-full h-[320px] md:h-[420px] rounded-2xl shadow-lg"
                            />
                            {facility.highlight_tag && (
                                <div className="absolute top-4 left-4 bg-primary text-white text-sm font-black uppercase tracking-wider px-4 py-1.5 rounded-full shadow-lg border border-primary-light/50 flex items-center gap-2 z-10">
                                    <Tag size={14} className="opacity-90" />
                                    {facility.highlight_tag}
                                </div>
                            )}
                            {images.length > 1 && (
                                <div className="flex gap-2">
                                    {images.map((img, i) => {
                                        if (!img) return null;
                                        return (
                                            <button
                                                key={i}
                                                onClick={() => setActiveImg(i)}
                                                className={`h-16 w-16 rounded-xl overflow-hidden border-2 transition-all ${i === activeImg ? 'border-primary shadow-md scale-105' : 'border-transparent opacity-70 hover:opacity-100'}`}
                                            >
                                                <ImageWithLoader src={img} alt={`${facility.name} ${i + 1}`} className="w-full h-full" />
                                            </button>
                                        )
                                    })}
                                </div>
                            )}
                        </div>

                        {/* Title & Location */}
                        <div className="glass-panel p-6 bg-white/40 border-white/60 backdrop-blur-md rounded-3xl animate-fade-in-up" style={{ animationDelay: '0.1s' }}>
                            <h1 className="text-3xl font-black text-slate-900 tracking-tight">{facility.name}</h1>
                            <div className="flex items-center gap-1.5 mt-2 text-slate-500 font-medium">
                                <MapPin size={18} className="text-primary" />
                                <span>{facility.location}, {facility.city}</span>
                            </div>
                            <div className="flex flex-wrap gap-3 mt-4">
                                <span className="px-3 py-1 rounded-full bg-white/80 text-slate-700 text-[13px] font-bold border border-white/80 shadow-sm">
                                    {facility.sport_type}
                                </span>
                                <span className="px-3 py-1 rounded-full bg-emerald-50 text-emerald-700 text-[13px] font-bold border border-emerald-200 shadow-sm">
                                    Rs. {facility.price_per_hour}/hr
                                </span>
                                <span className="px-3 py-1 rounded-full bg-amber-50 text-amber-700 text-[13px] font-bold border border-amber-200 shadow-sm flex items-center gap-1">
                                    <Star size={12} className="fill-amber-500 text-amber-500" />
                                    {avgRating} ({displayReviews.length} reviews)
                                </span>
                            </div>
                        </div>

                        {/* About */}
                        <div className="glass-panel p-6 bg-white/40 border-white/60 backdrop-blur-md rounded-3xl animate-fade-in-up" style={{ animationDelay: '0.15s' }}>
                            <h2 className="text-lg font-black text-slate-900 mb-3 tracking-tight">About This Venue</h2>
                            <p className="text-slate-600 font-medium leading-relaxed">
                                {facility.description || 'No description available for this venue.'}
                            </p>
                        </div>

                        {/* Amenities */}
                        {facility.amenities?.length > 0 && (
                            <div className="glass-panel p-6 bg-white/40 border-white/60 backdrop-blur-md rounded-3xl animate-fade-in-up" style={{ animationDelay: '0.2s' }}>
                                <h2 className="text-lg font-black text-slate-900 mb-4 tracking-tight">Amenities</h2>
                                <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                                    {facility.amenities.map(a => (
                                        <div key={a} className="flex items-center gap-2 text-[15px] font-semibold text-slate-700">
                                            {getAmenityIcon(a)}
                                            {a}
                                        </div>
                                    ))}
                                </div>
                            </div>
                        )}

                        {/* Rules & Policies */}
                        {((facility.rules && facility.rules.trim() !== '') || facility.cancellation_policy) && (
                            <div className="glass-panel p-6 flex flex-col gap-6 bg-white/40 border-white/60 backdrop-blur-md rounded-3xl animate-fade-in-up" style={{ animationDelay: '0.25s' }}>
                                {facility.rules && facility.rules.trim() !== '' && (
                                    <div>
                                        <h2 className="text-lg font-black text-slate-900 mb-3 flex items-center gap-2 tracking-tight">
                                            <ScrollText size={20} className="text-primary" /> Facility Rules
                                        </h2>
                                        <div className="text-slate-600 font-medium leading-relaxed bg-white/60 p-4 rounded-xl text-sm whitespace-pre-wrap border border-white/80 shadow-sm">
                                            {facility.rules}
                                        </div>
                                    </div>
                                )}

                                {facility.cancellation_policy && (
                                    <div>
                                        <h2 className="text-lg font-black text-slate-900 mb-3 flex items-center gap-2 tracking-tight">
                                            <ShieldCheck size={20} className="text-primary" /> Cancellation Policy
                                        </h2>
                                        <p className="text-[15px] font-semibold text-slate-600 bg-white/60 border border-white/80 p-4 rounded-xl shadow-sm">
                                            <span className="text-slate-900 font-black">{facility.cancellation_policy}</span> - {
                                                facility.cancellation_policy === 'Flexible' ? 'Full refund if canceled 24 hours prior.' :
                                                    facility.cancellation_policy === 'Moderate' ? 'Full refund if canceled 48 hours prior.' :
                                                        'No refunds once booked.'
                                            }
                                        </p>
                                    </div>
                                )}
                            </div>
                        )}

                        {/* Reviews Section */}
                        <div className="glass-panel p-6 bg-white/40 border-white/60 backdrop-blur-md rounded-3xl animate-fade-in-up" style={{ animationDelay: '0.3s' }}>
                            <div className="flex items-center justify-between mb-5">
                                <h2 className="text-lg font-black text-slate-900 tracking-tight flex items-center gap-2">
                                    <ThumbsUp size={20} className="text-primary" />
                                    Player Reviews
                                </h2>
                                <div className="flex items-center gap-1.5 text-sm font-bold text-slate-500">
                                    <Star size={16} className="fill-amber-400 text-amber-400" />
                                    {avgRating} avg
                                </div>
                            </div>
                            <div className="flex flex-col gap-4">
                                {displayReviews.map((review, i) => (
                                    <ReviewCard key={i} review={review} index={i} />
                                ))}
                            </div>
                        </div>
                    </div>

                    {/* RIGHT: Booking Widget */}
                    <div className="lg:col-span-1">
                        <div className="sticky top-24 glass-panel p-6 shadow-xl border border-white/60 bg-white/40 backdrop-blur-3xl rounded-3xl animate-scale-in">
                            <h2 className="text-xl font-black text-slate-900 mb-5 tracking-tight">Price & Booking</h2>
                            <div className="flex justify-between items-center mb-6">
                                <span className="text-slate-500 font-bold">Price per hour</span>
                                <span className="text-3xl font-black text-slate-900">Rs. {facility.price_per_hour}</span>
                            </div>

                            <button
                                onClick={() => navigate(`/book/${facility.id}`)}
                                className="w-full h-14 rounded-xl bg-slate-900 hover:bg-slate-800 text-white font-bold transition-all shadow-md flex items-center justify-center gap-2 hover:-translate-y-1"
                            >
                                Book this Venue
                            </button>

                            <div className="mt-6 flex flex-col gap-3 text-[15px] text-slate-600 font-medium">
                                <span className="flex items-center gap-2"><CheckCircle2 size={18} className="text-emerald-500" /> Instant Confirmation</span>
                                <span className="flex items-center gap-2"><CheckCircle2 size={18} className="text-emerald-500" /> Secure Payments</span>
                                <span className="flex items-center gap-2"><CheckCircle2 size={18} className="text-emerald-500" /> Free Cancellation</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}
