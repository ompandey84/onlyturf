import React from 'react';
import { Link } from 'react-router-dom';
import { ArrowRight, MapPin, Tag } from 'lucide-react';

const PLACEHOLDER_IMG = 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=600&q=80';

export default function FacilityCard({ facility, className = '' }) {
    const imgSrc = (facility.images?.length > 0 && facility.images[0]) ? facility.images[0] : (facility.image_url || PLACEHOLDER_IMG);

    return (
        <Link
            to={`/facility-details?id=${facility.id}`}
            className={`group flex flex-col glass-panel rounded-3xl overflow-hidden transition-all duration-300 hover:scale-[1.02] shadow-lg hover:shadow-xl border border-white/60 hover:border-white hover:bg-white/60 bg-white/40 backdrop-blur-2xl ${className}`}
        >
            {/* Image */}
            <div className="relative w-full aspect-[16/10] overflow-hidden bg-black/20">
                <div
                    className="absolute inset-0 bg-cover bg-center transition-transform duration-500 group-hover:scale-105"
                    style={{ backgroundImage: `url("${imgSrc}")` }}
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent opacity-80" />

                {/* Highlight Tag */}
                {facility.highlight_tag && (
                    <div className="absolute top-3 left-3">
                        <span className="px-2.5 py-1 rounded-full bg-primary/95 backdrop-blur-md text-white text-[10px] font-black uppercase tracking-wider shadow-md flex items-center gap-1">
                            <Tag size={10} />
                            {facility.highlight_tag}
                        </span>
                    </div>
                )}

                {/* Sport badge */}
                <div className="absolute top-3 right-3">
                    <span className="px-2.5 py-1 rounded-full bg-black/50 backdrop-blur-md text-white text-[10px] font-bold uppercase tracking-wide border border-white/20">
                        {facility.sport_type}
                    </span>
                </div>

                {/* Price badge */}
                <div className="absolute bottom-3 right-3">
                    <span className="px-3 py-1.5 rounded-xl bg-white/95 text-[#111418] text-xs font-black shadow-lg">
                        ₹{facility.price_per_hour}/hr
                    </span>
                </div>
            </div>

            {/* Content */}
            <div className="p-5 flex flex-col gap-2.5 flex-1 justify-between relative z-10">
                <div className="absolute inset-0 bg-gradient-to-br from-white/60 to-transparent pointer-events-none" />
                <div className="relative z-10">
                    <div className="flex items-start justify-between gap-2 mb-1.5">
                        <h3 className="text-[18px] font-black text-slate-800 leading-tight line-clamp-1 group-hover:text-primary transition-colors">
                            {facility.name}
                        </h3>
                    </div>

                    <div className="flex items-center gap-1.5 text-[14px] font-semibold text-slate-500">
                        <MapPin size={16} className="text-primary shrink-0" />
                        <span className="truncate">{facility.location}, {facility.city}</span>
                    </div>
                </div>

                {/* Amenities preview */}
                {facility.amenities?.length > 0 && (
                    <div className="flex flex-wrap gap-1.5 mt-2 relative z-10">
                        {facility.amenities.slice(0, 3).map(a => (
                            <span key={a} className="text-[11px] font-bold px-2.5 py-1 rounded-lg bg-white/80 text-slate-600 border border-white/80 backdrop-blur-md shadow-sm">
                                {a}
                            </span>
                        ))}
                        {facility.amenities.length > 3 && (
                            <span className="text-[11px] font-bold px-2.5 py-1 rounded-lg bg-primary/10 text-primary border border-primary/20 backdrop-blur-md shadow-sm">
                                +{facility.amenities.length - 3}
                            </span>
                        )}
                    </div>
                )}
            </div>
        </Link>
    );
}
