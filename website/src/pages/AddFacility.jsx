import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../supabase';
import { useAuth } from '../context/AuthContext';
import { sportsTypes, amenitiesList, cancellationPolicies } from '../constants';
import * as Icons from 'lucide-react';
import { AlertCircle, Building2, MapPin, AlignLeft, IndianRupee, Image as ImageIcon, ArrowLeft, Check, Dumbbell, ShieldCheck, Tag } from 'lucide-react';

const defaultForm = {
    name: '', location: '', city: 'Indore - Bhawarkua', sport_type: 'Cricket', description: '',
    price_per_hour: '', image_url_1: '', image_url_2: '', image_url_3: '', amenities: [],
    rules: '', cancellation_policy: 'Flexible', highlight_tag: ''
};

export default function AddFacility() {
    const navigate = useNavigate();
    const { user } = useAuth();
    const [formData, setFormData] = useState(defaultForm);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const handleChange = (e) => setFormData(p => ({ ...p, [e.target.name]: e.target.value }));

    const toggleAmenity = (a) => setFormData(p => ({
        ...p,
        amenities: p.amenities.includes(a) ? p.amenities.filter(x => x !== a) : [...p.amenities, a]
    }));

    const handleSubmit = async (e) => {
        e.preventDefault();

        // --- STRICT VALIDATION RULES ---
        if (!formData.price_per_hour || isNaN(formData.price_per_hour) || parseFloat(formData.price_per_hour) <= 0) {
            setError('Please enter a valid price strictly greater than 0.'); return;
        }
        if (!formData.image_url_1 || !formData.image_url_2 || !formData.image_url_3) {
            setError('Please provide exactly 3 valid image URLs to showcase your facility.'); return;
        }
        if (formData.description.trim().length < 50) {
            setError('Description must be at least 50 characters long to provide enough detail for users.'); return;
        }
        if (formData.amenities.length < 3) {
            setError('Please select at least 3 amenities available at your venue.'); return;
        }

        setLoading(true);
        setError('');
        try {
            const { error } = await supabase.from('facilities').insert([{
                name: formData.name,
                location: formData.location,
                city: formData.city,
                sport_type: formData.sport_type,
                description: formData.description,
                price_per_hour: parseFloat(formData.price_per_hour),
                image_url: formData.image_url_1, // Primary display image
                images: [formData.image_url_1, formData.image_url_2, formData.image_url_3], // Gallery
                amenities: formData.amenities,
                rules: formData.rules,
                cancellation_policy: formData.cancellation_policy,
                highlight_tag: formData.highlight_tag,
                owner_id: user.id,
                is_active: true,
            }]);
            if (error) throw error;
            navigate('/facility-owner/facilities');
        } catch (err) {
            setError(err.message);
        } finally { setLoading(false); }
    };

    return (
        <div className="page-container py-8 md:py-12 animate-fade-in relative z-10 px-4">
            <button
                onClick={() => navigate('/facility-owner/facilities')}
                className="mb-8 flex items-center gap-2 text-blue-100 hover:text-white transition-colors drop-shadow"
            >
                <ArrowLeft size={18} />
                <span className="font-semibold">Back to Facilities</span>
            </button>

            <div className="max-w-4xl mx-auto">
                <div className="mb-10 text-center">
                    <h1 className="text-3xl font-bold text-white mb-2 drop-shadow-md">Add New Facility</h1>
                    <p className="text-blue-100/90 drop-shadow">List your sports venue on OnlyTurf and start accepting bookings.</p>
                </div>

                <form onSubmit={handleSubmit} className="glass-panel p-6 md:p-10 shadow-2xl flex flex-col gap-8 relative overflow-hidden">
                    <div className="absolute inset-0 bg-gradient-to-br from-white/10 to-transparent pointer-events-none" />

                    {error && (
                        <div className="relative flex items-center gap-3 rounded-2xl bg-red-500/10 border border-red-500/20 p-4 backdrop-blur-md">
                            <AlertCircle size={24} className="text-red-400 shrink-0" />
                            <p className="text-sm font-medium text-red-100">{error}</p>
                        </div>
                    )}

                    {/* Basic Info */}
                    <div className="space-y-6 relative">
                        <div className="flex items-center gap-2 mb-6 pb-4 border-b border-white/10">
                            <Building2 size={24} className="text-blue-300" />
                            <h2 className="text-xl font-bold text-white">Basic Information</h2>
                        </div>

                        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                            <div className="flex flex-col gap-2">
                                <label className="text-sm font-bold text-blue-50/90 ml-1">Venue Name <span className="text-red-400">*</span></label>
                                <input type="text" name="name" value={formData.name} onChange={handleChange} required className="w-full rounded-xl border border-white/20 bg-black/20 px-4 py-3 text-sm text-white placeholder:text-white/40 outline-none focus:border-white focus:ring-2 focus:ring-white/20 transition-all backdrop-blur-md" placeholder="e.g. Green Cricket Ground" />
                            </div>

                            <div className="flex flex-col gap-2">
                                <label className="text-sm font-bold text-blue-50/90 ml-1">Sport Type <span className="text-red-400">*</span></label>
                                <div className="relative">
                                    <select name="sport_type" value={formData.sport_type} onChange={handleChange} className="w-full rounded-xl border border-white/20 bg-black/40 px-4 py-3 text-sm text-white outline-none focus:border-white focus:ring-2 focus:ring-white/20 transition-all backdrop-blur-md appearance-none pr-10">
                                        {sportsTypes.filter(s => s !== 'All').map(s => <option key={s} className="bg-gray-800 text-white">{s}</option>)}
                                    </select>
                                    <Dumbbell size={18} className="absolute right-4 top-1/2 -translate-y-1/2 text-white/50 pointer-events-none" />
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Location */}
                    <div className="space-y-6 relative">
                        <div className="flex items-center gap-2 mb-6 pb-4 border-b border-white/10">
                            <MapPin size={24} className="text-blue-300" />
                            <h2 className="text-xl font-bold text-white">Location Details</h2>
                        </div>

                        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                            <div className="flex flex-col gap-2">
                                <label className="text-sm font-bold text-blue-50/90 ml-1">Address / Area <span className="text-red-400">*</span></label>
                                <input type="text" name="location" value={formData.location} onChange={handleChange} required className="w-full rounded-xl border border-white/20 bg-black/20 px-4 py-3 text-sm text-white placeholder:text-white/40 outline-none focus:border-white focus:ring-2 focus:ring-white/20 transition-all backdrop-blur-md" placeholder="e.g. Near Vijay Nagar Square" />
                            </div>

                            <div className="flex flex-col gap-2">
                                <label className="text-sm font-bold text-blue-50/90 ml-1">City <span className="text-red-400">*</span></label>
                                <div className="relative">
                                    <select name="city" value={formData.city} onChange={handleChange} className="w-full rounded-xl border border-white/20 bg-black/40 px-4 py-3 text-sm text-white outline-none focus:border-white focus:ring-2 focus:ring-white/20 transition-all backdrop-blur-md appearance-none pr-10">
                                        <option value="Indore - Bhawarkua" className="bg-gray-800 text-white">Indore - Bhawarkua</option>
                                        <option value="Indore - Palda" className="bg-gray-800 text-white">Indore - Palda</option>
                                        <option value="Indore - Geeta Bhawan" className="bg-gray-800 text-white">Indore - Geeta Bhawan</option>
                                    </select>
                                    <MapPin size={18} className="absolute right-4 top-1/2 -translate-y-1/2 text-white/50 pointer-events-none" />
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Pricing & Media */}
                    <div className="space-y-6 relative">
                        <div className="flex items-center gap-2 mb-6 pb-4 border-b border-white/10">
                            <ImageIcon size={24} className="text-blue-300" />
                            <h2 className="text-xl font-bold text-white">Pricing & Minimum 3 Images</h2>
                        </div>

                        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                            <div className="flex flex-col gap-2">
                                <label className="text-sm font-bold text-blue-50/90 ml-1">Price Per Hour (₹) <span className="text-red-400">*</span></label>
                                <div className="relative">
                                    <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                                        <IndianRupee size={16} className="text-white/50" />
                                    </div>
                                    <input type="number" name="price_per_hour" value={formData.price_per_hour} onChange={handleChange} required min={1} className="w-full rounded-xl border border-white/20 bg-black/20 px-4 py-3 text-sm text-white placeholder:text-white/40 outline-none focus:border-white focus:ring-2 focus:ring-white/20 transition-all backdrop-blur-md pl-10" placeholder="500" />
                                </div>
                                <span className="text-xs text-blue-100/60 ml-1">Must be strictly greater than 0</span>
                            </div>

                            <div className="flex flex-col gap-3">
                                <label className="text-sm font-bold text-blue-50/90 ml-1">Provide 3 Image URLs <span className="text-red-400">*</span></label>
                                {[1, 2, 3].map(num => (
                                    <div key={num} className="relative">
                                        <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                                            <ImageIcon size={14} className="text-white/50" />
                                        </div>
                                        <input type="url" name={`image_url_${num}`} value={formData[`image_url_${num}`]} onChange={handleChange} required className="w-full rounded-xl border border-white/20 bg-black/20 px-4 py-2.5 text-sm text-white placeholder:text-white/40 outline-none focus:border-white focus:ring-2 focus:ring-white/20 transition-all backdrop-blur-md pl-10" placeholder={`Image URL ${num} (https://...)`} />
                                    </div>
                                ))}
                            </div>
                        </div>
                    </div>

                    {/* Detailed Info */}
                    <div className="space-y-6 relative">
                        <div className="flex items-center gap-2 mb-6 pb-4 border-b border-white/10">
                            <AlignLeft size={24} className="text-blue-300" />
                            <h2 className="text-xl font-bold text-white">Detailed Description</h2>
                        </div>

                        <div className="flex flex-col gap-2">
                            <label className="text-sm font-bold text-blue-50/90 ml-1">Facility Description <span className="text-red-400">*</span></label>
                            <textarea name="description" value={formData.description} onChange={handleChange} required rows={5} className="w-full rounded-xl border border-white/20 bg-black/20 px-4 py-4 text-sm text-white placeholder:text-white/40 outline-none focus:border-white focus:ring-2 focus:ring-white/20 transition-all backdrop-blur-md resize-y" placeholder="Provide a detailed description of your facility, the pitch quality, surrounding environment, etc." />
                            <div className={`text-xs text-right font-medium ${formData.description.length < 50 ? 'text-red-400' : 'text-emerald-400'}`}>
                                {formData.description.length}/50 minimum characters required
                            </div>
                        </div>

                        <div className="flex flex-col gap-4 mt-8">
                            <div className="flex items-center justify-between">
                                <label className="text-sm font-bold text-blue-50/90 ml-1">Select Amenities (Minimum 3) <span className="text-red-400">*</span></label>
                                <span className={`text-xs font-bold px-3 py-1.5 rounded-full backdrop-blur-md border ${formData.amenities.length >= 3 ? 'bg-emerald-500/20 text-emerald-300 border-emerald-500/30' : 'bg-red-500/20 text-red-300 border-red-500/30'}`}>{formData.amenities.length} Selected</span>
                            </div>
                            <div className="flex flex-wrap gap-3">
                                {amenitiesList.map(a => {
                                    const isSelected = formData.amenities.includes(a.name);
                                    const IconComponent = Icons[a.icon] || Icons.HelpCircle;
                                    return (
                                        <button
                                            key={a.name} type="button"
                                            onClick={() => toggleAmenity(a.name)}
                                            className={`flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-semibold transition-all border backdrop-blur-md ${isSelected ? 'bg-white/20 border-white/40 text-white shadow-[0_0_15px_rgba(255,255,255,0.2)]' : 'bg-black/20 border-white/10 text-white/70 hover:border-white/30 hover:bg-black/40 hover:text-white'}`}
                                        >
                                            <IconComponent size={16} className={isSelected ? 'text-white' : 'text-white/50'} />
                                            {a.name}
                                        </button>
                                    );
                                })}
                            </div>
                        </div>
                    </div>

                    {/* Optional Cool Fields */}
                    <div className="space-y-6 relative">
                        <div className="flex items-center gap-2 mb-6 pb-4 border-b border-white/10">
                            <Tag size={24} className="text-blue-300" />
                            <h2 className="text-xl font-bold text-white">Cool Factors & Policies (Optional)</h2>
                        </div>

                        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                            <div className="flex flex-col gap-2">
                                <label className="text-sm font-bold text-blue-50/90 ml-1 flex items-center gap-2">
                                    Highlight Tag <span className="bg-white/20 text-white text-[10px] px-2 py-0.5 rounded uppercase tracking-wider border border-white/30">Cool</span>
                                </label>
                                <input type="text" name="highlight_tag" value={formData.highlight_tag} onChange={handleChange} className="w-full rounded-xl border border-white/20 bg-black/20 px-4 py-3 text-sm text-white placeholder:text-white/40 outline-none focus:border-white focus:ring-2 focus:ring-white/20 transition-all backdrop-blur-md" placeholder="e.g. FIFA Certified, Best Turf in Town!" maxLength={25} />
                                <span className="text-xs text-blue-100/60 ml-1">A short catchy phrase to overlay on your listing.</span>
                            </div>

                            <div className="flex flex-col gap-2">
                                <label className="text-sm font-bold text-blue-50/90 ml-1">Cancellation Policy</label>
                                <div className="relative">
                                    <select name="cancellation_policy" value={formData.cancellation_policy} onChange={handleChange} className="w-full rounded-xl border border-white/20 bg-black/40 px-4 py-3 text-sm text-white outline-none focus:border-white focus:ring-2 focus:ring-white/20 transition-all backdrop-blur-md appearance-none pr-10">
                                        {cancellationPolicies.map(c => <option key={c.label} value={c.label} className="bg-gray-800 text-white">{c.label} - {c.description}</option>)}
                                    </select>
                                    <ShieldCheck size={18} className="absolute right-4 top-1/2 -translate-y-1/2 text-white/50 pointer-events-none" />
                                </div>
                            </div>
                        </div>

                        <div className="flex flex-col gap-2">
                            <label className="text-sm font-bold text-blue-50/90 ml-1">Facility Rules</label>
                            <textarea name="rules" value={formData.rules} onChange={handleChange} rows={3} className="w-full rounded-xl border border-white/20 bg-black/20 px-4 py-4 text-sm text-white placeholder:text-white/40 outline-none focus:border-white focus:ring-2 focus:ring-white/20 transition-all backdrop-blur-md resize-y" placeholder="e.g. 1. Non-marking shoes only. 2. No outside food allowed..." />
                        </div>
                    </div>

                    <div className="pt-8 border-t border-white/10 flex flex-col sm:flex-row gap-4 sm:justify-end relative">
                        <button type="button" onClick={() => navigate('/facility-owner/facilities')} className="h-12 px-8 font-bold order-2 sm:order-1 rounded-xl glass hover:bg-white/10 text-white transition-all border border-white/30">Cancel</button>
                        <button type="submit" disabled={loading} className="h-12 px-10 font-bold order-1 sm:order-2 rounded-xl bg-white/20 hover:bg-white/30 text-white transition-all border border-white/40 hover:-translate-y-1 backdrop-blur-md shadow-lg shadow-black/20 disabled:opacity-50 text-[15px]">
                            {loading ? 'Publishing Venue...' : 'Publish Premium Venue'}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
}
