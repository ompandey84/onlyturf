import 'dart:convert';
import 'package:application/features/auth/login_screen.dart';
import 'package:application/core/theme/app_colors.dart';
import 'package:application/core/widgets/shimmer_loading.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:application/core/widgets/ticket_clipper.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> facility;

  const BookingScreen({super.key, required this.facility});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDate = DateTime.now();
  final Set<String> _selectedTimes = {};
  bool _isLoading = false;
  bool _isFetchingSlots = true;
  Set<String> _bookedSlots = {};
  late Razorpay _razorpay;

  Map<String, dynamic>? _getSchedule() {
    try {
      final schedule = widget.facility['operating_schedule'];
      if (schedule == null) return null;

      if (schedule is String) {
        return jsonDecode(schedule) as Map<String, dynamic>;
      }
      if (schedule is Map) {
        return Map<String, dynamic>.from(schedule);
      }
    } catch (e) {
      debugPrint('Error getting schedule: $e');
    }
    return null;
  }

  // Dynamically generate available time slots based on owner's operating schedule
  List<String> _getAvailableSlots() {
    final schedule = _getSchedule();
    int slotDuration = 1;
    int openHour = 6;
    int closeHour = 23;

    if (schedule != null) {
      slotDuration = schedule['slot_duration'] ?? 1;
      if (schedule['opening_time'] != null) {
        final parts = (schedule['opening_time'] as String).split(':');
        openHour = int.tryParse(parts[0]) ?? 6;
      }
      if (schedule['closing_time'] != null) {
        final parts = (schedule['closing_time'] as String).split(':');
        closeHour = int.tryParse(parts[0]) ?? 23;
      }

      // Handle overnight schedule (e.g. 9 PM to 2 AM)
      if (closeHour < openHour) {
        closeHour += 24;
        debugPrint(
          'USER_APP_DEBUG: Overnight schedule detected. Adjusted closeHour to $closeHour',
        );
      }
    }

    final slots = <String>[];
    for (
      int hour = openHour;
      hour + slotDuration <= closeHour;
      hour += slotDuration
    ) {
      final start = DateTime(2024, 1, 1, hour);
      final end = start.add(Duration(hours: slotDuration));
      final format = DateFormat('hh:00 a');
      slots.add('${format.format(start)} - ${format.format(end)}');
    }
    return slots;
  }

  bool _isOperatingDay(DateTime date) {
    final schedule = _getSchedule();
    if (schedule == null) return true;
    final operatingDays = schedule['operating_days'];
    if (operatingDays == null || operatingDays is! List) return true;
    // DateTime.weekday: 1=Monday ... 7=Sunday  →  index 0=Mon ... 6=Sun
    final dayIndex = date.weekday - 1;
    if (dayIndex < 0 || dayIndex >= operatingDays.length) {
      debugPrint(
        'USER_APP_DEBUG: Invalid day index $dayIndex for days ${operatingDays.length}',
      );
      return true;
    }

    final val = operatingDays[dayIndex];
    debugPrint(
      'USER_APP_DEBUG: Checking day $dayIndex ($date). Value: $val (${val.runtimeType})',
    );

    if (val is bool) return val;
    if (val is String) return val.toLowerCase() == 'true';
    return false;
  }

  @override
  void initState() {
    super.initState();
    _fetchBookedSlots();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    // Payment Successful
    debugPrint('Payment Success: ${response.paymentId}');
    _finalizeBookings('confirmed').then((_) {
      _showSuccessAndRedirect();
    });
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Payment Error: ${response.code} - ${response.message}');

    // Razorpay code 2 = user cancelled / pressed back
    final bool isCancelled = response.code == 2;

    if (isCancelled) {
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange.withValues(alpha: 0.1),
                  ),
                  child: const Icon(
                    Icons.pending_actions,
                    size: 36,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Payment Incomplete',
                  style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The transaction was closed. Your booking is saved as Pending. You can retry the payment anytime from your Bookings tab.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: AppColors.textSec(context),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _initiatePayment();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'TRY AGAIN NOW',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    // Navigate to dashboard tab
                    Navigator.pop(context);
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: Text(
                    'RETRY LATER (GO TO BOOKINGS)',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      color: AppColors.textSec(context),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
        setState(() => _isLoading = false);
      }
    } else {
      final String title = 'Payment Failed';
      final String subtitle =
          response.message ??
          'Something went wrong. Your booking is saved as Pending. You can retry from your Bookings tab.';

      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.statusCancelled.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    Icons.error,
                    size: 36,
                    color: AppColors.statusCancelled,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: AppColors.textSec(context),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _initiatePayment();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'RETRY',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'GO BACK',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      color: AppColors.textSec(context),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // External Wallet Selected
    debugPrint('External Wallet: ${response.walletName}');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('External Wallet Selected: ${response.walletName}'),
        ),
      );
    }
  }

  Future<void> _fetchBookedSlots() async {
    setState(() => _isFetchingSlots = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final response = await Supabase.instance.client
          .from('bookings')
          .select('time_slot')
          .eq('facility_id', widget.facility['id'])
          .eq('date', dateStr);

      final bookedSlots = <String>{};
      for (var booking in response as List) {
        final slot = booking['time_slot'] as String;
        bookedSlots.add(slot);
      }

      setState(() {
        _bookedSlots = bookedSlots;
        _isFetchingSlots = false;
      });
    } catch (e) {
      debugPrint('Error fetching booked slots: $e');
      setState(() => _isFetchingSlots = false);
    }
  }

  bool _isPeakHour(String slot) {
    try {
      final parts = slot.split(' - ');
      final startStr = parts[0];
      final format = DateFormat('hh:00 a');
      final date = format.parse(startStr);
      final hour24 = date.hour;
      return hour24 >= 18 && hour24 <= 22;
    } catch (e) {
      return false;
    }
  }

  bool _isSlotBooked(String slot) {
    return _bookedSlots.contains(slot);
  }

  /// Check if a slot's time has already passed (for today only)
  bool _isSlotPast(String slot) {
    final now = DateTime.now();
    // Only applicable if selected date is today
    if (_selectedDate.year != now.year ||
        _selectedDate.month != now.month ||
        _selectedDate.day != now.day) {
      return false;
    }
    try {
      final parts = slot.split(' - ');
      final startStr = parts[0]; // "06:00 AM"
      final format = DateFormat('hh:00 a');
      final slotTime = format.parse(startStr);
      final slotHour = slotTime.hour;
      // If slot start hour is <= current hour, it's past
      return slotHour <= now.hour;
    } catch (e) {
      return false;
    }
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool _isTomorrow(DateTime d) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return d.year == tomorrow.year &&
        d.month == tomorrow.month &&
        d.day == tomorrow.day;
  }

  void _selectQuickDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _selectedTimes.clear();
    });
    _fetchBookedSlots();
  }

  /// iOS-style glassmorphism date picker bottom sheet
  Future<void> _selectDate(BuildContext context) async {
    DateTime tempDate = _selectedDate;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: 380,
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle bar
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: AppColors.textSec(context),
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const Text(
                          'Select Date',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            setState(() {
                              _selectedDate = tempDate;
                              _selectedTimes.clear();
                            });
                            _fetchBookedSlots();
                          },
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Divider(height: 1, color: AppColors.divider(context)),

                  // CupertinoDatePicker
                  Expanded(
                    child: CupertinoTheme(
                      data: CupertinoThemeData(
                        textTheme: CupertinoTextThemeData(
                          dateTimePickerTextStyle: TextStyle(
                            fontSize: 20,
                            color: AppColors.textMain(context),
                          ),
                        ),
                      ),
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.date,
                        initialDateTime: _selectedDate,
                        minimumDate: DateTime.now().subtract(
                          const Duration(hours: 1),
                        ),
                        maximumDate: DateTime.now().add(
                          const Duration(days: 30),
                        ),
                        onDateTimeChanged: (date) {
                          setSheetState(() => tempDate = date);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _toggleSlot(String slot) {
    if (_isSlotBooked(slot) || _isSlotPast(slot)) return;
    setState(() {
      if (_selectedTimes.contains(slot)) {
        _selectedTimes.remove(slot);
      } else {
        _selectedTimes.add(slot);
      }
    });
  }

  Future<void> _initiatePayment() async {
    // Auth guard: redirect to login if not authenticated
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to book a venue')),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    final pricePerHour = (widget.facility['price_per_hour'] ?? 0) as num;
    final totalBaseAmount = pricePerHour * _selectedTimes.length;
    // Calculate 2% Platform Fee and add to total
    final totalAmountWithFee = (totalBaseAmount * 1.02).ceil();

    // Razorpay takes amount in paise (multiply by 100)
    final amountInPaise = totalAmountWithFee * 100;

    var options = {
      'key': 'rzp_test_SFk35ZapWyLOpX', // User's Test Key
      'amount': amountInPaise,
      'name': 'GameVenueX',
      'description': 'Booking for ${widget.facility['name']}',
      'prefill': {
        'contact': Supabase.instance.client.auth.currentUser?.phone ?? '',
        'email': Supabase.instance.client.auth.currentUser?.email ?? '',
      },
      'external': {
        'wallets': ['paytm'],
      },
    };

    try {
      // ── NEW FLOW: Insert 'pending_payment' booking BEFORE payment ──
      await _createPendingBookings();

      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error initiating payment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  String _generatePassId() {
    final now = DateTime.now();
    final datePart =
        '${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final randomPart = (1000 + (now.microsecond % 9000)).toString();
    return 'CTSD-$datePart-$randomPart';
  }

  // Track the pending bookings so we can update them later
  List<String> _pendingBookingIds = [];
  String? _pendingPassId;

  Future<void> _createPendingBookings() async {
    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;

    if (currentUser == null) throw 'User not logged in';

    final pricePerHour = (widget.facility['price_per_hour'] ?? 0) as num;
    _pendingPassId = _generatePassId();
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    _pendingBookingIds.clear();

    for (var slot in _selectedTimes) {
      final bookingData = {
        'facility_id': widget.facility['id'],
        'sport': widget.facility['sport_type'] ?? 'Sports',
        'date': dateStr,
        'time_slot': slot,
        'total_price': pricePerHour,
        'user_id': currentUser.id,
        'status': 'pending_payment', // Initial status
        'pass_id': _pendingPassId,
      };

      final res = await supabase
          .from('bookings')
          .insert(bookingData)
          .select('id')
          .single();
      _pendingBookingIds.add(res['id'] as String);
    }
  }

  Future<void> _finalizeBookings(String status) async {
    if (_pendingBookingIds.isEmpty) return;

    final supabase = Supabase.instance.client;
    try {
      for (final id in _pendingBookingIds) {
        final res = await supabase
            .from('bookings')
            .update({'status': status})
            .eq('id', id)
            .select();
        debugPrint(
          'BOOKING_UPDATE_DEBUG: Updated $id to $status. Result: $res',
        );
      }
    } catch (e) {
      debugPrint('Error finalizing bookings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to confirm booking: $e')),
        );
      }
    }
  }

  Future<void> _showSuccessAndRedirect() async {
    final pricePerHour = (widget.facility['price_per_hour'] ?? 0) as num;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    if (mounted) {
      _showTicketConfirmation(
        passId: _pendingPassId ?? 'UNKNOWN',
        venueName: widget.facility['name'] ?? 'Venue',
        sport: widget.facility['sport_type'] ?? 'Sports',
        date: dateStr,
        slots: _selectedTimes.toList(),
        totalPrice: pricePerHour * _selectedTimes.length,
      );
    }
    setState(() => _isLoading = false);
  }

  void _showTicketConfirmation({
    required String passId,
    required String venueName,
    required String sport,
    required String date,
    required List<String> slots,
    required num totalPrice,
  }) {
    final formattedDate = DateFormat(
      'EEEE, d MMMM yyyy',
    ).format(DateTime.parse(date));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Success Icon ──
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Booking Confirmed!',
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your court has been reserved',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: AppColors.textSec(context),
              ),
            ),
            const SizedBox(height: 24),

            // ── Ticket Card ──
            PhysicalShape(
              clipper: TicketClipper(punchRadius: 10),
              color: AppColors.subtleBg(context),
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              child: Container(
                width: double.infinity,
                // Removed decoration as color is handled by PhysicalShape
                child: Column(
                  children: [
                    // Top section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      venueName,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textMain(context),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        sport.toUpperCase(),
                                        style: GoogleFonts.montserrat(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '₹${totalPrice.toInt()}',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Date
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: AppColors.textSec(context),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  formattedDate,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMain(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Time slots
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: AppColors.textSec(context),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  slots.join(', '),
                                  style: GoogleFonts.montserrat(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMain(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // ── Tear Line with Notches ──
                    Row(
                      children: [
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final dashWidth = 6.0;
                              final dashSpace = 4.0;
                              final dashCount =
                                  (constraints.maxWidth /
                                          (dashWidth + dashSpace))
                                      .floor();
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(dashCount, (index) {
                                  return Container(
                                    width: dashWidth,
                                    height: 1.5,
                                    margin: EdgeInsets.symmetric(
                                      horizontal: dashSpace / 2,
                                    ),
                                    color: AppColors.divider(context),
                                  );
                                }),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    // Bottom section — Pass ID
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      child: Column(
                        children: [
                          Text(
                            'PASS ID',
                            style: GoogleFonts.montserrat(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSec(context),
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            passId,
                            style: GoogleFonts.montserrat(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Show at the venue',
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              color: AppColors.textSec(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Buttons ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'BACK TO HOME',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pricePerHour = widget.facility['price_per_hour'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(
          widget.facility['name'],
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.card(context),
        elevation: 0,
        foregroundColor: AppColors.textMain(context),
      ),
      body: Column(
        children: [
          // Urgency Header
          Container(
            width: double.infinity,
            color: Colors.amber.shade50,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.local_fire_department,
                  size: 16,
                  color: Colors.amber,
                ),
                const SizedBox(width: 8),
                Text(
                  'Evening slots filling fast!',
                  style: TextStyle(
                    color: Colors.amber.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isFetchingSlots
                ? const BookingSlotShimmer()
                : CustomScrollView(
                    slivers: [
                      // Date Section
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Date',
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Quick date chips: Today, Tomorrow, Pick Date
                              Row(
                                children: [
                                  _buildDateChip(
                                    'Today',
                                    _isToday(_selectedDate),
                                    () => _selectQuickDate(DateTime.now()),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildDateChip(
                                    'Tomorrow',
                                    _isTomorrow(_selectedDate),
                                    () => _selectQuickDate(
                                      DateTime.now().add(
                                        const Duration(days: 1),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildDateChip(
                                    'Pick Date',
                                    !_isToday(_selectedDate) &&
                                        !_isTomorrow(_selectedDate),
                                    () => _selectDate(context),
                                    icon: Icons.calendar_today,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Selected date display card
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.06,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.12,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            DateFormat(
                                              'd',
                                            ).format(_selectedDate),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          Text(
                                            DateFormat('MMM')
                                                .format(_selectedDate)
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          DateFormat(
                                            'EEEE',
                                          ).format(_selectedDate),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          _isToday(_selectedDate)
                                              ? 'Today • ${DateFormat('d MMMM yyyy').format(_selectedDate)}'
                                              : _isTomorrow(_selectedDate)
                                              ? 'Tomorrow • ${DateFormat('d MMMM yyyy').format(_selectedDate)}'
                                              : DateFormat(
                                                  'd MMMM yyyy',
                                                ).format(_selectedDate),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSec(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () => _selectDate(context),
                                      child: const Icon(
                                        Icons.edit_calendar,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Past time notice for today
                              if (_isToday(_selectedDate))
                                Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info,
                                        size: 16,
                                        color: Colors.red.shade400,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Past time slots are unavailable for today',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.red.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Slots Header
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Available Slots',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${_selectedTimes.length} selected',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),

                      // Slots Grid (or Closed message)
                      if (!_isOperatingDay(_selectedDate))
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              decoration: BoxDecoration(
                                color: AppColors.subtleBg(context),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.divider(context),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.event_busy,
                                    size: 48,
                                    color: AppColors.textSec(context),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Closed on this day',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSec(context),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'This venue does not operate on the selected day.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSec(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          sliver: Builder(
                            builder: (context) {
                              /*
                               * Fix: Calculate availableSlots once before the grid to avoid 
                               * infinite loop (missing childCount) and expensive re-parsing.
                               */
                              final allSlots = _getAvailableSlots();
                              final availableSlots = allSlots
                                  .where((s) => !_isSlotPast(s))
                                  .toList();

                              return SliverGrid(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      childAspectRatio: 2.2,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                    ),
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final slot = availableSlots[index];
                                  final isSelected = _selectedTimes.contains(
                                    slot,
                                  );
                                  final isPeak = _isPeakHour(slot);
                                  final isBooked = _isSlotBooked(slot);

                                  return GestureDetector(
                                    onTap: isBooked
                                        ? null
                                        : () => _toggleSlot(slot),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isBooked
                                            ? AppColors.subtleBg(context)
                                            : isSelected
                                            ? AppColors.primary
                                            : AppColors.card(context),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isBooked
                                              ? AppColors.divider(context)
                                              : isSelected
                                              ? AppColors.primary
                                              : AppColors.divider(context),
                                          width: isSelected ? 0 : 1,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: AppColors.primary
                                                      .withValues(alpha: 0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Stack(
                                        children: [
                                          Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                if (isBooked)
                                                  Icon(
                                                    Icons.block,
                                                    size: 12,
                                                    color: AppColors.textSec(
                                                      context,
                                                    ),
                                                  ),
                                                Text(
                                                  slot
                                                      .split(' - ')[0]
                                                      .replaceAll(':00', ''),
                                                  style: TextStyle(
                                                    color: isBooked
                                                        ? AppColors.textSec(
                                                            context,
                                                          )
                                                        : isSelected
                                                        ? Colors.white
                                                        : AppColors.textMain(
                                                            context,
                                                          ),
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                    fontSize: isBooked
                                                        ? 11
                                                        : 12,
                                                  ),
                                                ),
                                                if (isBooked)
                                                  Text(
                                                    'Booked',
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      color: AppColors.textSec(
                                                        context,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          if (isPeak &&
                                              !isSelected &&
                                              !isBooked)
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: Container(
                                                width: 6,
                                                height: 6,
                                                decoration: const BoxDecoration(
                                                  color: Colors.orange,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }, childCount: availableSlots.length),
                              );
                            },
                          ),
                        ),

                      // Legend
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildLegendItem(
                                AppColors.card(context),
                                'Available',
                                border: true,
                              ),
                              _buildLegendItem(AppColors.primary, 'Selected'),
                              _buildLegendItem(
                                AppColors.subtleBg(context),
                                'Unavailable',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          // Bottom Payment Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(
                                color: AppColors.textSec(context),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (_selectedTimes.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: AppColors.card(context),
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(24),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Price Breakdown',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Slot Price (${_selectedTimes.length} slots)',
                                                style: TextStyle(
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                              Text(
                                                '₹${(pricePerHour * _selectedTimes.length).toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Platform Fee (2%)',
                                                style: TextStyle(
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                              Text(
                                                '₹${((pricePerHour * _selectedTimes.length) * 0.02).ceil().toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Divider(height: 24),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Total Payable',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                              Text(
                                                '₹${((pricePerHour * _selectedTimes.length) * 1.02).ceil().toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 24),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: Icon(
                                  Icons.info,
                                  size: 16,
                                  color: AppColors.textSec(context),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          _selectedTimes.isEmpty
                              ? '₹0'
                              : '₹${((pricePerHour * _selectedTimes.length) * 1.02).ceil().toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _selectedTimes.isEmpty || _isLoading
                        ? null
                        : _initiatePayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: Lottie.asset(
                              'assets/animations/loader.json',
                              fit: BoxFit.contain,
                            ),
                          )
                        : Text(
                            'CHECKOUT',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
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

  Widget _buildDateChip(
    String label,
    bool isSelected,
    VoidCallback onTap, {
    IconData? icon,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.card(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.divider(context),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 6,
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? Colors.white : AppColors.textSec(context),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : AppColors.textMain(context),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, {bool border = false}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: border
                ? Border.all(color: AppColors.divider(context))
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.textSec(context)),
        ),
      ],
    );
  }
}
