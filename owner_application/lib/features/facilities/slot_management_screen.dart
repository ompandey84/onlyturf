import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SlotManagementScreen extends StatefulWidget {
  final Map<String, dynamic> facility;

  const SlotManagementScreen({super.key, required this.facility});

  @override
  State<SlotManagementScreen> createState() => _SlotManagementScreenState();
}

class _SlotManagementScreenState extends State<SlotManagementScreen> {
  DateTime _selectedDate = DateTime.now();
  late Stream<List<Map<String, dynamic>>> _bookingsStream;

  // 1 Hour Slots
  // Dynamic slots based on facility schedule
  List<String> get _timeSlots => _generateTimeSlots();

  List<String> _generateTimeSlots() {
    try {
      final schedule = widget.facility['operating_schedule'];
      if (schedule == null) return _defaultSlots();

      final schedMap = schedule is String
          ? (jsonDecode(schedule) as Map<String, dynamic>)
          : (schedule as Map<String, dynamic>);

      // Default to 6 AM - 11 PM if parsing fails
      int openHour = 6;
      int closeHour = 23;

      if (schedMap['opening_time'] != null) {
        final parts = (schedMap['opening_time'] as String).split(':');
        openHour = int.tryParse(parts[0]) ?? 6;
      }
      if (schedMap['closing_time'] != null) {
        final parts = (schedMap['closing_time'] as String).split(':');
        closeHour = int.tryParse(parts[0]) ?? 23;
      }

      // Handle overnight (e.g., 9 PM to 2 AM -> 21 to 26)
      if (closeHour < openHour) {
        closeHour += 24;
      }

      final slots = <String>[];
      for (int i = openHour; i < closeHour; i++) {
        // Create a date for formatting
        // We use a dummy date, just need the hour
        final dt = DateTime(2024, 1, 1, i);
        final format = DateFormat('hh:00 a');
        slots.add(format.format(dt));
      }
      return slots;
    } catch (e) {
      debugPrint('Error generating slots: $e');
      return _defaultSlots();
    }
  }

  List<String> _defaultSlots() {
    return [
      '06:00 AM',
      '07:00 AM',
      '08:00 AM',
      '09:00 AM',
      '10:00 AM',
      '11:00 AM',
      '12:00 PM',
      '01:00 PM',
      '02:00 PM',
      '03:00 PM',
      '04:00 PM',
      '05:00 PM',
      '06:00 PM',
      '07:00 PM',
      '08:00 PM',
      '09:00 PM',
      '10:00 PM',
      '11:00 PM',
    ];
  }

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  void _initStream() {
    // Stream all bookings for this facility, filter by date in the UI
    _bookingsStream = Supabase.instance.client
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('facility_id', widget.facility['id']);
  }

  // Helper to create "06:00 AM - 07:00 AM"
  String _makeTimeSlotString(String startTime) {
    // Parse time
    final format = DateFormat('hh:00 a');
    final start = format.parse(startTime);
    final end = start.add(const Duration(hours: 1));
    return '${format.format(start)} - ${format.format(end)}';
  }

  void _showSlotOptions(
    BuildContext context,
    String startTime,
    List<Map<String, dynamic>> currentBookings,
  ) {
    final slotString = _makeTimeSlotString(startTime);

    final existingBooking = currentBookings.firstWhere(
      (b) => b['time_slot'] == slotString,
      orElse: () => {},
    );

    final isBooked = existingBooking.isNotEmpty;
    final isBlocked = isBooked && existingBooking['status'] == 'blocked';
    final isCustomerBooking = isBooked && !isBlocked;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Slot: $slotString',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (isCustomerBooking) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Booked to User\nID: ${existingBooking['user_id']}',
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ),
              ] else if (isBlocked) ...[
                const Text(
                  'Status: Blocked by You',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _unblockSlot(existingBooking['id']);
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Unblock SLOT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ] else ...[
                const Text(
                  'Status: Available',
                  style: TextStyle(color: Colors.green),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _blockSlot(slotString);
                    },
                    icon: const Icon(Icons.block),
                    label: const Text('Block Slot'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _blockSlot(String timeSlotString) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final userId = Supabase.instance.client.auth.currentUser!.id;

      await Supabase.instance.client.from('bookings').insert({
        'facility_id': widget.facility['id'],
        'date': dateStr,
        'time_slot': timeSlotString,
        'user_id': userId,
        'status': 'blocked',
        'total_price': 0,
        'sport': widget.facility['sport_type'] ?? 'General',
      });
      // No need to fetch, Stream updates automatically
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to block: $e')));
      }
    }
  }

  Future<void> _unblockSlot(String bookingId) async {
    try {
      await Supabase.instance.client
          .from('bookings')
          .delete()
          .eq('id', bookingId);
      // No need to fetch, Stream updates automatically
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to unblock: $e')));
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF137fec),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _initStream(); // Re-init stream for new date
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.facility['name']),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: InkWell(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: Color(0xFF137fec),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _initStream();
          setState(() {});
        },
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _bookingsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final allBookings = snapshot.data ?? [];
            final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
            final bookings = allBookings
                .where((b) => b['date'] == dateStr)
                .toList();

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _timeSlots.length,
              itemBuilder: (context, index) {
                final startTime = _timeSlots[index];
                final slotString = _makeTimeSlotString(startTime);

                final booking = bookings.firstWhere(
                  (b) => b['time_slot'] == slotString,
                  orElse: () => {},
                );

                final isBooked = booking.isNotEmpty;
                final isBlocked = isBooked && booking['status'] == 'blocked';
                final isCustomerBooking = isBooked && !isBlocked;

                Color bgColor = Colors.white;
                Color borderColor = Colors.grey.shade300;
                Color textColor = Colors.black;
                IconData? icon;

                if (isCustomerBooking) {
                  bgColor = Colors.red.shade50;
                  borderColor = Colors.red.shade200;
                  textColor = Colors.red.shade900;
                  icon = Icons.lock_outline;
                } else if (isBlocked) {
                  bgColor = Colors.grey.shade200;
                  borderColor = Colors.grey.shade400;
                  textColor = Colors.grey.shade700;
                  icon = Icons.block;
                }

                return InkWell(
                  onTap: () => _showSlotOptions(context, startTime, bookings),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 16, color: textColor),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          startTime,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: isBooked
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                        if (isCustomerBooking)
                          Text(
                            'Booked',
                            style: TextStyle(fontSize: 10, color: textColor),
                          ),
                        if (isBlocked)
                          Text(
                            'Blocked',
                            style: TextStyle(fontSize: 10, color: textColor),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
