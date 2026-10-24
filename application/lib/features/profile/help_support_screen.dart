import 'package:application/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFAQItem(
            context,
            'How do I book a turf?',
            'Simply select your preferred sport and location on the home screen, browse available venues, select a date and time slot, and confirm your booking. You\'ll receive instant confirmation!',
          ),
          _buildFAQItem(
            context,
            'Can I cancel or modify a booking?',
            'Yes! You can cancel bookings up to 24 hours before the scheduled time for a full refund. For modifications, please cancel the original booking and create a new one.',
          ),
          _buildFAQItem(
            context,
            'What payment methods do you accept?',
            'We accept all major credit/debit cards, UPI, net banking, and popular mobile wallets. All transactions are encrypted and secure.',
          ),
          _buildFAQItem(
            context,
            'What if it rains on my booking day?',
            'For outdoor venues, if severe weather prevents play, you can reschedule for free or receive a full refund. Contact the venue or our support team.',
          ),
          _buildFAQItem(
            context,
            'How do I find the venue location?',
            'Each venue page has a "Get Directions" button that opens the location in your maps app. You can also view the address in booking details.',
          ),
          const SizedBox(height: 32),
          const Text(
            'Contact Us',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Have a question? Our support team is here to help!',
            style: TextStyle(color: AppColors.textSec(context)),
          ),
          const SizedBox(height: 16),
          _buildContactTile(
            context,
            icon: Icons.email,
            title: 'Email Support',
            subtitle: 'support@turfbooking.com',
            color: Colors.blue,
            onTap: () => _launchEmail('support@turfbooking.com'),
          ),
          _buildContactTile(
            context,
            icon: Icons.phone,
            title: 'Call Us',
            subtitle: '+91 98765 43210',
            color: Colors.green,
            onTap: () => _launchPhone('+919876543210'),
          ),
          _buildContactTile(
            context,
            icon: Icons.message,
            title: 'WhatsApp',
            subtitle: 'Chat with us',
            color: Colors.teal,
            onTap: () => _launchWhatsApp('+919876543210'),
          ),
          const SizedBox(height: 32),
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Our support team typically responds within 2-4 hours during business hours (9 AM - 9 PM IST).',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(height: 1.5, color: AppColors.textSec(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Turf Booking Support Request',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    final Uri whatsappUri = Uri.parse('https://wa.me/$phone');

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    }
  }
}
