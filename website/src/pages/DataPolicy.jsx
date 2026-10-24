import React from 'react';
import { Shield } from 'lucide-react';

export default function PrivacyPolicy() {
    const sections = [
        { title: '1. Information We Collect', content: 'We collect information you provide directly: name, email address, phone number, and payment information when making bookings. We also collect usage data including device information, IP address, and browsing patterns to improve our services.' },
        { title: '2. How We Use Your Information', content: 'Your information is used to: process bookings and payments, send booking confirmations and reminders, improve our platform and user experience, communicate important updates, and provide customer support. We never sell your personal data to third parties.' },
        { title: '3. Data Sharing', content: 'We share necessary booking details (name, contact) with venue owners to facilitate your bookings. We may share anonymized, aggregated data for analytics purposes. We will disclose information if required by law or to protect our rights and safety.' },
        { title: '4. Data Security', content: 'We use industry-standard encryption (SSL/TLS) to protect data in transit. Payment information is processed through secure, PCI-compliant payment processors. We regularly audit our systems for vulnerabilities and implement security best practices.' },
        { title: '5. Cookies & Tracking', content: 'We use essential cookies for authentication and session management. Analytics cookies help us understand how users interact with our platform. You can manage cookie preferences through your browser settings.' },
        { title: '6. Your Rights', content: 'You have the right to: access your personal data, request correction of inaccurate data, request deletion of your account and data, opt out of marketing communications, and export your data in a portable format.' },
        { title: '7. Data Retention', content: 'We retain your account data as long as your account is active. Booking history is retained for 3 years for record-keeping purposes. You can request deletion of your data at any time by contacting support.' },
        { title: '8. Contact Us', content: 'For any privacy-related questions or requests, please contact us at privacy@onlyturf.in. We aim to respond to all privacy inquiries within 48 hours.' },
    ];

    return (
        <div className="min-h-screen">
            <div className="glass-panel mx-4 mt-24 mb-6 rounded-3xl border border-white/60 shadow-xl relative overflow-hidden bg-white/40 backdrop-blur-3xl">
                <div className="absolute inset-0 bg-gradient-to-br from-white/40 to-transparent pointer-events-none" />
                <div className="page-container py-12 px-6 sm:px-10 lg:px-12 relative z-10">
                    <div className="flex items-center gap-3 mb-3">
                        <Shield size={28} className="text-primary" />
                        <h1 className="text-3xl md:text-4xl font-black text-slate-900 tracking-tight">Privacy Policy</h1>
                    </div>
                    <p className="text-slate-500 font-medium">Last updated: February 2026</p>
                </div>
            </div>

            <div className="page-container py-10 relative z-10">
                <div className="max-w-3xl mx-auto flex flex-col gap-6">
                    {sections.map((s, i) => (
                        <div key={i} className="glass-panel p-6 rounded-2xl border border-white/60 bg-white/40 animate-fade-in-up" style={{ animationDelay: `${i * 0.05}s` }}>
                            <h2 className="text-lg font-black text-slate-900 mb-3 tracking-tight">{s.title}</h2>
                            <p className="text-slate-600 font-medium leading-relaxed">{s.content}</p>
                        </div>
                    ))}
                </div>
            </div>
        </div>
    );
}
