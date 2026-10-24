import 'package:application/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class TermsServiceScreen extends StatelessWidget {
  const TermsServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Agreement',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Last Updated: Feb 2026',
              style: TextStyle(color: AppColors.textSec(context), fontSize: 14),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '1. Introduction',
              'Welcome to our sports venue booking platform. By accessing or using our application, you agree to be bound by these Terms of Service. If you do not agree with any part of these terms, you may not access the service.',
            ),
            _buildSection(
              context,
              '2. Booking Policy',
              'All bookings are subject to availability. You must arrive at the venue at least 10 minutes prior to your scheduled slot. The booking slot includes time for warm-up and cool-down within the allocated hour(s).',
            ),
            _buildSection(
              context,
              '3. Cancellations & Refunds',
              '- Cancellations made **24 hours prior** to the booking time are eligible for a full refund.\n'
                  '- Cancellations made within 24 hours of the slot are **non-refundable**.\n'
                  '- In case of venue unavailability due to maintenance or weather (for open turfs), a full refund or reschedule option will be provided.',
            ),
            _buildSection(
              context,
              '4. User Conduct',
              'Users are expected to maintain professional decorum at the venue. Any damage to venue property, equipment, or abusive behavior towards staff will result in a permanent ban and potential legal action. Proper sports attire (e.g., non-marking shoes for wooden courts) is mandatory.',
            ),
            _buildSection(
              context,
              '5. Liability Disclaimer',
              'Sports activities involve physical risk. By using this service, you acknowledge that you participate at your own risk. neither the App nor the Venue Owner shall be liable for any physical injuries, accidents, or loss of personal belongings occurring at the venue.',
            ),
            _buildSection(
              context,
              '6. Privacy Policy',
              'We respect your privacy. All personal data including contact details and payment information is handled in accordance with our Privacy Policy. We do not sell your data to third parties.',
            ),
            _buildSection(
              context,
              '7. Modifications',
              'We reserve the right to modify these terms at any time. Continued use of the application after any such changes constitutes your acceptance of the new Terms of Service.',
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Play Hard, Play Fair!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSec(context),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppColors.textSec(context),
            ),
          ),
        ],
      ),
    );
  }
}
