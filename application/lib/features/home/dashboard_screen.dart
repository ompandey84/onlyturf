import 'package:application/core/theme/app_colors.dart';
import 'package:application/core/widgets/lottie_loader.dart';

import 'package:application/features/auth/login_screen.dart';
import 'package:application/features/booking/booking_details_screen.dart';
import 'package:application/features/facilities/facilities_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardScreen extends StatefulWidget {
  final bool showHistoryOnly;
  final bool isActiveTab;

  const DashboardScreen({
    super.key,
    this.showHistoryOnly = false,
    this.isActiveTab =
        true, // default to true so it works when pushed standalone
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _bookings = [];
  Map<String, dynamic> _profile = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-refresh when the tab becomes active
    if (!oldWidget.isActiveTab && widget.isActiveTab) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await Future.wait([_fetchBookings(), _fetchProfile()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchBookings() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('bookings')
          .select('*, facilities(name, sport_type)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final data = List<Map<String, dynamic>>.from(response);
      debugPrint('DASHBOARD_DEBUG: Fetched ${data.length} bookings');
      if (data.isNotEmpty) {
        debugPrint('DASHBOARD_DEBUG: First booking: ${data.first}');
        debugPrint(
          'DASHBOARD_DEBUG: First booking facility: ${data.first['facilities']}',
        );
      }

      // Map facility details to top level for easier access
      final mappedData = data.map((b) {
        final facility = b['facilities'] as Map<String, dynamic>?;
        return {
          ...b,
          'facility_name': facility?['name'] ?? 'Venue',
          'sport': facility?['sport_type'] ?? 'Sports',
        };
      }).toList();

      if (mounted) {
        setState(() => _bookings = mappedData);
      }
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating registry: $e')));
      }
    }
  }

  Future<void> _fetchProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      if (mounted) setState(() => _profile = data);
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background(context),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.confirmation_number,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Access Required',
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to view your booking registry',
                style: GoogleFonts.montserrat(color: AppColors.textSec(context)),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: Text(
                  'GRANT ACCESS',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontSize: 12,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Filter bookings
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final List<Map<String, dynamic>> bookings;
    if (widget.showHistoryOnly) {
      // History: past bookings (date < today) or status == 'completed'
      bookings = _bookings.where((b) {
        try {
          final status = (b['status'] ?? '').toString().toLowerCase().trim();
          if (status == 'completed') return true;
          final bookingDate = DateTime.parse(b['date']);
          final dateOnly = DateTime(
            bookingDate.year,
            bookingDate.month,
            bookingDate.day,
          );
          return dateOnly.isBefore(today);
        } catch (_) {
          return false;
        }
      }).toList();
    } else {
      // Upcoming: today + future
      bookings = _bookings.where((b) {
        try {
          final bookingDate = DateTime.parse(b['date']);
          final dateOnly = DateTime(
            bookingDate.year,
            bookingDate.month,
            bookingDate.day,
          );
          return !dateOnly.isBefore(today);
        } catch (_) {
          return false;
        }
      }).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: _isLoading
          ? const LottieLoader(message: 'Loading bookings...')
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: CustomScrollView(
                slivers: [
                  // ── Registry Header ──
                  SliverToBoxAdapter(
                    child: _buildRegistryHeader(
                      user,
                      bookings.length,
                      isHistory: widget.showHistoryOnly,
                    ),
                  ),

                  // ── Booking Cards ──
                  bookings.isEmpty
                      ? SliverToBoxAdapter(child: _buildEmptyState())
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildTicketCard(bookings[index]),
                              ),
                              childCount: bookings.length,
                            ),
                          ),
                        ),

                  // ── Find Court CTA ──
                  SliverToBoxAdapter(child: _buildFindCourtCTA()),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
    );
  }

  // ── Registry Header ──
  Widget _buildRegistryHeader(
    dynamic user,
    int bookingCount, {
    bool isHistory = false,
  }) {
    final name = _profile['full_name'] ?? 'Member';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'M';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      color: AppColors.background(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button for history mode
          if (isHistory)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_back_ios,
                      size: 18,
                      color: AppColors.textSec(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Back',
                      style: GoogleFonts.montserrat(
                        color: AppColors.textSec(context),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Title
          Text(
            isHistory ? 'Booking History' : 'Registry',
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain(context),
            ),
          ),
          const SizedBox(height: 20),

          // Profile Row
          Row(
            children: [
              // Avatar with badge
              Stack(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.1),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.background(context),
                        border: Border.all(color: AppColors.divider(context)),
                      ),
                      child: const Icon(
                        Icons.workspace_premium,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.montserrat(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'PRESTIGE MEMBER',
                    style: GoogleFonts.montserrat(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Sport Icon Helper ──

  IconData _getSportIcon(String sport) {
    switch (sport.toLowerCase()) {
      case 'cricket':
        return Icons.sports_cricket;
      case 'football':
      case 'soccer':
        return Icons.sports_soccer;
      case 'badminton':
        return Icons.sports_tennis;
      case 'tennis':
        return Icons.sports_tennis;
      case 'basketball':
        return Icons.sports_basketball;
      case 'volleyball':
        return Icons.sports_volleyball;
      case 'hockey':
        return Icons.sports_hockey;
      case 'swimming':
        return Icons.pool;
      default:
        return Icons.sports;
    }
  }

  // ── Ticket-style Booking Card ──
  Widget _buildTicketCard(Map<String, dynamic> booking) {
    final dateStr = booking['date'];
    final timeSlot = booking['time_slot'] ?? '';
    final status = booking['status'] ?? 'pending';
    final price = booking['total_price'] ?? 0;
    // Prefer pass_id, fallback to id
    final bookingId = booking['pass_id'] ?? booking['id']?.toString() ?? '';

    final DateTime date = DateTime.parse(dateStr);
    final fmtDate = DateFormat('EEE, d MMM yyyy').format(date);

    final isConfirmed = status.toLowerCase() == 'confirmed';
    final isCancelled = status.toLowerCase() == 'cancelled';

    Color accentColor;
    if (isConfirmed) {
      accentColor = AppColors.primary;
    } else if (isCancelled) {
      accentColor = AppColors.statusCancelled;
    } else {
      accentColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingDetailsScreen(booking: booking),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // ── Left accent bar + content ──
            IntrinsicHeight(
              child: Row(
                children: [
                  // Left color bar
                  Container(
                    width: 5,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                      ),
                    ),
                  ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sport icon
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _getSportIcon(booking['sport'] ?? 'Sports'),
                              color: accentColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Name + type
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking['facility_name'] ?? 'Venue',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMain(context),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'COURT RESERVATION',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.5,
                                    color: AppColors.textSec(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Passport stamp badge
                          _buildPassportStamp(status),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Dashed tear-line ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Dashed line
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final dashWidth = 5.0;
                        final dashCount =
                            (constraints.maxWidth / (dashWidth * 2)).floor();
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(dashCount, (_) {
                            return SizedBox(
                              width: dashWidth,
                              height: 1,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppColors.divider(context),
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ),
                  // Left cutout
                  Positioned(
                    left: -8,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.background(context),
                      ),
                    ),
                  ),
                  // Right cutout
                  Positioned(
                    right: -8,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.background(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Details Grid ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildDetailItem('Date', fmtDate)),
                      Expanded(child: _buildDetailItem('Time', timeSlot)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          'Pass ID',
                          (status.trim().toLowerCase() == 'confirmed' ||
                                  status.trim().toLowerCase() == 'booked')
                              ? bookingId.toUpperCase()
                              : '--------',
                          isMono: true,
                        ),
                      ),
                      Expanded(
                        child: _buildDetailItem('Cost', '₹${price.toString()}'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── View Pass link ──
            if (status.trim().toLowerCase() == 'confirmed' ||
                status.trim().toLowerCase() == 'booked')
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BookingDetailsScreen(booking: booking),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Pass',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isMono = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 10,
            color: AppColors.textSec(context),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: isMono
              ? GoogleFonts.robotoMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMain(context),
                  letterSpacing: 1,
                )
              : GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain(context),
                ),
        ),
      ],
    );
  }

  // ── Passport Stamp Badge ──
  Widget _buildPassportStamp(String status) {
    Color color;
    String label;
    final normalizedStatus = status.trim().toLowerCase();

    if (normalizedStatus == 'confirmed' || normalizedStatus == 'booked') {
      color = AppColors.statusConfirmed;
      label = 'CONFIRMED';
    } else if (normalizedStatus == 'cancelled') {
      color = AppColors.statusCancelled;
      label = 'CANCELLED';
    } else if (normalizedStatus == 'completed') {
      color = AppColors.statusCompleted;
      label = 'COMPLETED';
    } else {
      color = AppColors.textSec(context);
      label = 'PENDING';

      // If status is specifically 'pending_payment', maybe clarify?
      if (normalizedStatus == 'pending_payment') {
        label = 'PAYING...';
      }
    }
    return Transform.rotate(
      angle: -0.08, // slight rotation like passport stamp
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2.5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.courierPrime(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          Icon(
            Icons.confirmation_number,
            size: 48,
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No passes yet',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your upcoming reservations will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: AppColors.textSec(context),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFindCourtCTA() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FacilitiesScreen(
                selectedCity: 'Indore',
                onCityChanged: (_) {},
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.add,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reserve your next session',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMain(context),
                      ),
                    ),
                    Text(
                      'Explore venues and secure your slot',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: AppColors.textSec(context),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
