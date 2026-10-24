import React from 'react';
import { ScrollText } from 'lucide-react';

export default function TermsOfService() {
    const sections = [
        { title: '1. Acceptance of Terms', content: 'By accessing and using OnlyTurf ("the Platform"), you agree to be bound by these Terms of Service. If you do not agree with any part of these terms, you must not use our platform.' },
        { title: '2. User Accounts', content: 'You must provide accurate and complete information when creating an account. You are responsible for maintaining the confidentiality of your login credentials and all activities under your account. You must be at least 13 years of age to create an account.' },
        { title: '3. Bookings & Payments', content: 'All bookings are subject to availability. Prices displayed are set by individual venue owners and may change without notice. Payment is required at the time of booking confirmation. OnlyTurf acts as an intermediary and does not own or operate the venues.' },
        { title: '4. Cancellation Policy', content: 'Cancellation policies vary by venue and are displayed on each facility\'s page. Refunds, if applicable, will be processed according to the venue\'s stated cancellation policy. OnlyTurf is not responsible for any disputes between users and venue owners regarding cancellations.' },
        { title: '5. User Conduct', content: 'Users agree to use the platform respectfully and lawfully. Any abusive behavior, fraudulent bookings, or misuse of the platform may result in account suspension or termination. Users must follow all facility rules posted by venue owners.' },
        { title: '6. Venue Owners', content: 'Venue owners are responsible for the accuracy of information listed on their facilities, including pricing, amenities, and availability. OnlyTurf reserves the right to remove any listing that violates our guidelines or receives consistent negative feedback.' },
        { title: '7. Limitation of Liability', content: 'OnlyTurf is a booking platform and does not guarantee the quality, safety, or condition of any venue. We are not liable for any injury, loss, or damage incurred while using a booked facility. Users participate in sports activities at their own risk.' },
        { title: '8. Changes to Terms', content: 'We reserve the right to modify these terms at any time. Continued use of the platform after changes constitutes acceptance of the new terms. Users will be notified of significant changes via email or in-app notifications.' },
    ];

    return (
        <div className="min-h-screen">
            <div className="glass-panel mx-4 mt-24 mb-6 rounded-3xl border border-white/60 shadow-xl relative overflow-hidden bg-white/40 backdrop-blur-3xl">
                <div className="absolute inset-0 bg-gradient-to-br from-white/40 to-transparent pointer-events-none" />
                <div className="page-container py-12 px-6 sm:px-10 lg:px-12 relative z-10">
                    <div className="flex items-center gap-3 mb-3">
                        <ScrollText size={28} className="text-primary" />
                        <h1 className="text-3xl md:text-4xl font-black text-slate-900 tracking-tight">Terms of Service</h1>
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
