import React from 'react';

/**
 * OnlyTurf Pin Logo — 1:1 replica from the splash screen.
 * Dark rounded square with dot grid + crimson pin icon.
 */
export default function OnlyTurfLogo({ size = 40 }) {
    return (
        <div
            className="relative overflow-hidden flex items-center justify-center"
            style={{
                width: size,
                height: size,
                borderRadius: size * 0.22,
                background: 'rgba(44, 44, 46, 0.85)',
                backdropFilter: 'blur(4px)',
                border: '1px solid rgba(255,255,255,0.05)',
                boxShadow: '0 4px 24px rgba(0,0,0,0.3)',
            }}
        >
            {/* Dot grid pattern */}
            <div
                className="absolute inset-0 opacity-[0.08]"
                style={{
                    backgroundImage: 'radial-gradient(#ffffff 1px, transparent 1px)',
                    backgroundSize: `${Math.max(size * 0.14, 5)}px ${Math.max(size * 0.14, 5)}px`,
                }}
            />
            {/* Pin SVG */}
            <svg
                width={size * 0.55}
                height={size * 0.55}
                viewBox="0 0 100 100"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
                className="relative z-10"
            >
                <circle cx="50" cy="35" r="18" fill="#DC143C" />
                <path d="M50 53 L50 85" stroke="white" strokeWidth="8" strokeLinecap="round" />
                <path d="M30 85 L70 85" stroke="white" strokeOpacity="0.4" strokeWidth="6" strokeLinecap="round" />
            </svg>
        </div>
    );
}
