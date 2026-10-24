import React, { useState } from 'react';
import { Phone, Mail, MapPin, CheckCircle2, Send, Headset } from 'lucide-react';

const contactDetails = [
    { icon: Phone, label: 'Phone', value: '+91 98765 43210', href: 'tel:+919876543210' },
    { icon: Mail, label: 'Email', value: 'support@justturf.in', href: 'mailto:support@justturf.in' },
    { icon: MapPin, label: 'Office', value: '123 Sports Avenue, Indore, MP', href: '#' },
];

export default function ContactUs() {
    const [formData, setFormData] = useState({ name: '', email: '', subject: '', message: '' });
    const [submitted, setSubmitted] = useState(false);

    const handleChange = (e) => setFormData(p => ({ ...p, [e.target.name]: e.target.value }));

    const handleSubmit = (e) => {
        e.preventDefault();
        setSubmitted(true);
        setTimeout(() => {
            setSubmitted(false);
            setFormData({ name: '', email: '', subject: '', message: '' });
        }, 4000);
    };

    return (
        <div className="min-h-screen relative z-10">
            {/* Hero */}
            <div className="glass-panel bg-white/40 border-b border-white/60 backdrop-blur-3xl relative z-20 shadow-sm">
                <div className="page-container py-12 text-center">
                    <span className="inline-block px-4 py-1.5 rounded-full bg-white/80 border border-white text-primary text-sm font-bold mb-4 shadow-sm">Get in Touch</span>
                    <h1 className="text-4xl md:text-5xl font-black text-slate-900 tracking-tight mb-3">Contact Our Team</h1>
                    <p className="text-[17px] text-slate-600 font-medium max-w-xl mx-auto">
                        Have questions about booking, venues, or partnerships? We're here to help.
                    </p>
                </div>
            </div>

            <div className="page-container py-12">
                <div className="grid grid-cols-1 lg:grid-cols-5 gap-10">
                    {/* Form */}
                    <div className="lg:col-span-3 glass-panel bg-white/40 border-white/60 backdrop-blur-3xl rounded-3xl p-8 shadow-sm">
                        {submitted ? (
                            <div className="flex flex-col items-center justify-center py-16 text-center">
                                <div className="w-16 h-16 rounded-full bg-emerald-50 border border-emerald-100 shadow-sm flex items-center justify-center mb-4">
                                    <CheckCircle2 size={40} className="text-emerald-500" />
                                </div>
                                <h3 className="text-2xl font-black text-slate-900 tracking-tight mb-2">Message Sent!</h3>
                                <p className="text-[15px] font-bold text-slate-500">We'll get back to you within 24 hours.</p>
                            </div>
                        ) : (
                            <>
                                <h2 className="text-2xl font-black text-slate-900 tracking-tight mb-6">Send a Message</h2>
                                <form onSubmit={handleSubmit} className="flex flex-col gap-5">
                                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                                        <div className="flex flex-col gap-1.5">
                                            <label className="text-[15px] font-bold text-slate-700 ml-1">Full Name *</label>
                                            <input type="text" name="name" placeholder="John Doe" value={formData.name} onChange={handleChange} required className="w-full rounded-xl border border-white/80 bg-white/60 px-4 py-3 text-[15px] font-bold text-slate-900 placeholder:text-slate-400 outline-none focus:border-white focus:ring-4 focus:ring-white/50 transition-all shadow-sm backdrop-blur-md" />
                                        </div>
                                        <div className="flex flex-col gap-1.5">
                                            <label className="text-[15px] font-bold text-slate-700 ml-1">Email *</label>
                                            <input type="email" name="email" placeholder="john@example.com" value={formData.email} onChange={handleChange} required className="w-full rounded-xl border border-white/80 bg-white/60 px-4 py-3 text-[15px] font-bold text-slate-900 placeholder:text-slate-400 outline-none focus:border-white focus:ring-4 focus:ring-white/50 transition-all shadow-sm backdrop-blur-md" />
                                        </div>
                                    </div>
                                    <div className="flex flex-col gap-1.5">
                                        <label className="text-[15px] font-bold text-slate-700 ml-1">Subject *</label>
                                        <select name="subject" value={formData.subject} onChange={handleChange} required className="w-full rounded-xl border border-white/80 bg-white/60 px-4 py-3 text-[15px] font-bold text-slate-900 outline-none focus:border-white focus:ring-4 focus:ring-white/50 transition-all shadow-sm backdrop-blur-md appearance-none">
                                            <option value="">Select a topic</option>
                                            <option value="booking">Booking Inquiry</option>
                                            <option value="venue">Venue Partnership</option>
                                            <option value="support">Technical Support</option>
                                            <option value="other">Other</option>
                                        </select>
                                    </div>
                                    <div className="flex flex-col gap-1.5">
                                        <label className="text-[15px] font-bold text-slate-700 ml-1">Message *</label>
                                        <textarea
                                            name="message" placeholder="How can we help you?" value={formData.message} onChange={handleChange} required
                                            className="w-full rounded-xl border border-white/80 bg-white/60 px-4 py-3 text-[15px] font-bold text-slate-900 placeholder:text-slate-400 outline-none focus:border-white focus:ring-4 focus:ring-white/50 transition-all shadow-sm backdrop-blur-md min-h-[140px] resize-y"
                                        />
                                    </div>
                                    <button type="submit" className="w-full h-12 rounded-xl bg-slate-900 text-white font-bold text-lg hover:bg-slate-800 transition-all shadow-md flex items-center justify-center gap-2 hover:-translate-y-1">
                                        Send Message
                                        <Send size={18} />
                                    </button>
                                </form>
                            </>
                        )}
                    </div>

                    {/* Contact Info */}
                    <div className="lg:col-span-2 flex flex-col gap-6">
                        <div className="glass-panel bg-white/40 border-white/60 backdrop-blur-3xl rounded-3xl p-6 shadow-sm">
                            <h3 className="text-xl font-black text-slate-900 tracking-tight mb-5">Contact Details</h3>
                            <div className="flex flex-col gap-5">
                                {contactDetails.map(({ icon: Icon, label, value, href }) => (
                                    <a key={label} href={href} className="flex items-start gap-4 group">
                                        <div className="w-10 h-10 rounded-xl bg-white/60 border border-white/80 flex items-center justify-center text-primary shadow-sm group-hover:bg-primary group-hover:text-white transition-all shrink-0">
                                            <Icon size={20} />
                                        </div>
                                        <div>
                                            <p className="text-[11px] font-black text-slate-500 uppercase tracking-wide">{label}</p>
                                            <p className="text-[15px] font-bold text-slate-900 group-hover:text-primary transition-colors">{value}</p>
                                        </div>
                                    </a>
                                ))}
                            </div>
                        </div>

                        <div className="glass-panel bg-white/40 border-white/60 backdrop-blur-3xl rounded-3xl p-6 shadow-sm">
                            <h3 className="text-xl font-black text-slate-900 tracking-tight mb-4">Office Hours</h3>
                            <div className="flex flex-col gap-3 text-[15px] text-slate-600 font-medium">
                                <div className="flex justify-between items-center bg-white/40 px-3 py-2 rounded-lg border border-white/60">
                                    <span>Monday – Friday</span>
                                    <span className="font-bold text-slate-900">9:00 AM – 8:00 PM</span>
                                </div>
                                <div className="flex justify-between items-center bg-white/40 px-3 py-2 rounded-lg border border-white/60">
                                    <span>Saturday</span>
                                    <span className="font-bold text-slate-900">10:00 AM – 6:00 PM</span>
                                </div>
                                <div className="flex justify-between items-center bg-white/40 px-3 py-2 rounded-lg border border-white/60">
                                    <span>Sunday</span>
                                    <span className="font-bold text-slate-500">Closed</span>
                                </div>
                            </div>
                        </div>

                        <div className="glass-panel bg-slate-900 border-slate-800 rounded-3xl p-6 shadow-lg text-white">
                            <Headset size={36} className="mb-4 block text-white/80" />
                            <h4 className="font-black tracking-tight text-xl mb-1">Need Urgent Help?</h4>
                            <p className="text-[15px] text-white/70 mb-5 font-medium leading-relaxed">Our support team is available 24/7 for booking-related emergencies.</p>
                            <a href="tel:+919876543210" className="inline-flex items-center gap-2 px-5 py-3 bg-white/10 hover:bg-white/20 border border-white/20 text-white rounded-xl text-[15px] font-bold transition-all hover:scale-105">
                                <Phone size={18} />
                                Call Now
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}
