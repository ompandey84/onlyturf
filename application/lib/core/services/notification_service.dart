import 'dart:convert';
import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:application/main.dart';
import 'package:application/features/facilities/facility_details_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          final data = jsonDecode(response.payload!);
          final facilityId = data['facility_id'];
          if (facilityId != null && navigatorKey.currentContext != null) {
            final facilityResponse = await Supabase.instance.client
                .from('facilities')
                .select('*, vendors(*)')
                .eq('id', facilityId)
                .single();
            if (facilityResponse.isNotEmpty) {
              Navigator.push(
                navigatorKey.currentContext!,
                MaterialPageRoute(
                  builder: (_) =>
                      FacilityDetailsScreen(facility: facilityResponse),
                ),
              );
            }
          }
        }
      },
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleTurfNotifications(String city) async {
    try {
      // Cancel previous scheduled notifications
      await _localNotificationsPlugin.cancelAll();

      final prefs = await SharedPreferences.getInstance();
      final isPushEnabled = prefs.getBool('push_notifications') ?? true;
      if (!isPushEnabled) return;

      final response = await Supabase.instance.client
          .from('facilities')
          .select('name, location')
          .ilike('location', '%$city%')
          .limit(10);

      final facilities = List<Map<String, dynamic>>.from(response);
      if (facilities.isEmpty) return;

      final random = Random();

      final messages = [
        "Hey! Bored? (venue) in (city) is looking perfect for a game ⚽️",
        "Your turf is waiting! Check out (venue) to play today 🏏",
        "Kya plan hai aaj? Gather the squad, (venue) is open! 🔥",
        "Time for some action! How about a session at (venue)? 🏆",
        "Don't miss out! Book your slot at (venue) in (city) today! ✨",
      ];

      List<Map<String, dynamic>> upcomingNotifications = [];

      for (int i = 1; i <= 3; i++) {
        final facility = facilities[random.nextInt(facilities.length)];
        final name = facility['name'] ?? 'a top venue';
        final facilityCity = facility['location'] ?? city;
        final facilityId = facility['id'];

        String msg = messages[random.nextInt(messages.length)]
            .replaceAll('(venue)', name)
            .replaceAll('(city)', facilityCity);

        // Schedule notification for i * 8 hours from now (approx 3 per day)
        final scheduledTime = tz.TZDateTime.now(
          tz.local,
        ).add(Duration(hours: 8 * i));

        // Save the payload for in-app display later
        final payloadData = {
          'facility_id': facilityId,
          'title': 'Ready to play? ⚡️',
          'body': msg,
          'timestamp': scheduledTime.millisecondsSinceEpoch,
        };
        upcomingNotifications.add(payloadData);

        await _localNotificationsPlugin.zonedSchedule(
          id: i,
          title: 'Ready to play? ⚡️',
          body: msg,
          scheduledDate: scheduledTime,
          payload: jsonEncode(payloadData),
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'turf_channel',
              'Turf Reminders',
              channelDescription: 'Reminders to play sports',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }

      // Save to SharedPreferences for the NotificationsScreen to read
      final savedLogs = prefs.getStringList('saved_notifications') ?? [];
      // Combine new ones with old ones, keeping only the last 50
      final List<String> newLogsToSave = upcomingNotifications
          .map((e) => jsonEncode(e))
          .toList();
      savedLogs.insertAll(0, newLogsToSave);
      if (savedLogs.length > 50) {
        savedLogs.removeRange(50, savedLogs.length);
      }
      await prefs.setStringList('saved_notifications', savedLogs);
    } catch (e) {
      debugPrint('Error scheduling notifications: $e');
    }
  }
}
