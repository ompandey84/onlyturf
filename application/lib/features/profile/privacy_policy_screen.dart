import 'package:application/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Last Updated: Jan 2026',
              style: TextStyle(color: AppColors.textSec(context)),
            ),
            SizedBox(height: 24),
            Text(
              '1. Introduction\n\n'
              'Welcome to Turf Booking. We respect your privacy and are committed to protecting your personal data.\n\n'
              '2. Data We Collect\n\n'
              '- Contact Information: Name, Email, Phone Number.\n'
              '- Usage Data: Booking history, interactions with the app.\n\n'
              '3. How We Use Your Data\n\n'
              'We use your data to manage bookings, improve our services, and communicate with you regarding your reservations.\n\n'
              '4. Data Security\n\n'
              'We implement appropriate security measures to prevent your personal data from being accidentally lost, used or accessed in an unauthorized way.\n\n'
              '5. Contact Us\n\n'
              'If you have any questions about this privacy policy, please contact us at support@turfbooking.com',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
