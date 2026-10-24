import 'dart:convert';
import 'package:application/core/theme/app_colors.dart';
import 'package:application/features/facilities/facility_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLogs = prefs.getStringList('saved_notifications') ?? [];

    // Convert string JSON back to maps
    setState(() {
      _notifications = savedLogs
          .map((log) => jsonDecode(log) as Map<String, dynamic>)
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _navigateToFacility(dynamic facilityId) async {
    if (facilityId == null) return;
    try {
      final facilityResponse = await Supabase.instance.client
          .from('facilities')
          .select('*, vendors(*)')
          .eq('id', facilityId)
          .single();

      if (facilityResponse.isNotEmpty && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FacilityDetailsScreen(facility: facilityResponse),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error navigating to facility from notification: $e');
    }
  }

  void _clearNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_notifications');
    setState(() {
      _notifications.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: _clearNotifications,
              child: Text(
                'Clear all',
                style: GoogleFonts.montserrat(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
        backgroundColor: AppColors.background(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textMain(context)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 64,
                    color: AppColors.textSec(context).withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No new notifications',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We will notify you when there\'s an update.',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: AppColors.textSec(context),
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              itemCount: _notifications.length,
              separatorBuilder: (context, index) =>
                  Divider(color: AppColors.divider(context), height: 1),
              itemBuilder: (context, index) {
                final notif = _notifications[index];
                final timestamp = notif['timestamp'] as int?;
                final date = timestamp != null
                    ? DateTime.fromMillisecondsSinceEpoch(timestamp)
                    : DateTime.now();

                return InkWell(
                  onTap: () => _navigateToFacility(notif['facility_id']),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.sports_soccer,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notif['title'] ?? 'Notification',
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppColors.textMain(context),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notif['body'] ?? '',
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  color: AppColors.textSec(context),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                timeago.format(date),
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
