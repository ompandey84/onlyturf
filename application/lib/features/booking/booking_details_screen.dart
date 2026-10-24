import 'package:application/core/theme/app_colors.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:application/core/widgets/ticket_clipper.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const BookingDetailsScreen({super.key, required this.booking});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  late Razorpay _razorpay;
  bool _isRetrying = false;
  late Map<String, dynamic> _currentBooking;

  @override
  void initState() {
    super.initState();
    _currentBooking = Map<String, dynamic>.from(widget.booking);
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
    debugPrint('Payment Success: ${response.paymentId}');
    _finalizeBooking('confirmed').then((_) {
      if (mounted) {
        setState(() {
          _isRetrying = false;
          _currentBooking['status'] = 'confirmed';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful! Booking confirmed.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isRetrying = false);
    debugPrint('Payment Error: ${response.code} - ${response.message}');
    final isCancelled = response.code == 2;
    if (isCancelled && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment cancelled.'),
          backgroundColor: Colors.orange,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment Failed: ${response.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() => _isRetrying = false);
    debugPrint('External Wallet: ${response.walletName}');
  }

  Future<void> _finalizeBooking(String newStatus) async {
    final supabase = Supabase.instance.client;
    final bookingId = _currentBooking['id'];
    if (bookingId == null) return;
    try {
      await supabase
          .from('bookings')
          .update({'status': newStatus})
          .eq('id', bookingId);
    } catch (e) {
      debugPrint('Error updating booking status: $e');
    }
  }

  void _initiateRetryPayment() {
    setState(() => _isRetrying = true);
    final user = Supabase.instance.client.auth.currentUser;
    final price = _currentBooking['total_price'] as num;
    final amountInPaise = (price * 100).toInt();

    final options = {
      'key': 'rzp_test_SFk35ZapWyLOpX',
      'amount': amountInPaise,
      'name': 'CTSD Sports',
      'description': 'Booking Retry',
      'prefill': {'contact': user?.phone ?? '', 'email': user?.email ?? ''},
      'external': {
        'wallets': ['paytm'],
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error initiating retry: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isRetrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _currentBooking['date'];
    final timeSlot = _currentBooking['time_slot'] ?? '';
    final status = _currentBooking['status'] ?? 'pending';
    final price = _currentBooking['total_price'];
    final passId =
        _currentBooking['pass_id'] ??
        _currentBooking['id'].toString().substring(0, 8).toUpperCase();
    final sport = _currentBooking['sport'] ?? 'Sports';
    final facilityName =
        _currentBooking['facility_name'] ??
        _currentBooking['facilities']?['name'] ??
        'Venue';

    final DateTime date = DateTime.tryParse(dateStr ?? '') ?? DateTime.now();
    final fmtDate = DateFormat('EEEE, d MMMM yyyy').format(date);

    final isPendingPayment =
        status.toString().toLowerCase().trim() == 'pending_payment';

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textMain(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'View Pass',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain(context),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Status Badge ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getStatusColor(status).withOpacity(0.15),
                    _getStatusColor(status).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getStatusColor(status).withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getStatusColor(status).withOpacity(0.2),
                    ),
                    child: Icon(
                      _getStatusIcon(status),
                      size: 24,
                      color: _getStatusColor(status),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (status == 'pending_payment'
                        ? 'PAYMENT INCOMPLETE'
                        : status.toUpperCase()),
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _getStatusColor(status),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Ticket Card ──
            PhysicalShape(
              clipper: TicketClipper(punchRadius: 10),
              color: AppColors.card(context),
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.06),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    // ── Top Section: Venue Info ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
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
                                      facilityName,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textMain(context),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(
                                          0.1,
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
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '₹$price',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Date row
                          _buildInfoRow(
                            context,
                            Icons.calendar_today,
                            'Date',
                            fmtDate,
                          ),
                          const SizedBox(height: 12),

                          // Time row
                          _buildInfoRow(
                            context,
                            Icons.access_time,
                            'Time',
                            timeSlot,
                          ),
                        ],
                      ),
                    ),

                    // ── Tear Line ──
                    Row(
                      children: [
                        Container(
                          width: 14,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.background(context),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(14),
                              bottomRight: Radius.circular(14),
                            ),
                          ),
                        ),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              const dashWidth = 6.0;
                              const dashSpace = 4.0;
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
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: dashSpace / 2,
                                    ),
                                    color: AppColors.divider(context),
                                  );
                                }),
                              );
                            },
                          ),
                        ),
                        Container(
                          width: 14,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.background(context),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(14),
                              bottomLeft: Radius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ── Bottom Section: Pass ID ──
                    if (status.toString().trim().toLowerCase() == 'confirmed' ||
                        status.toString().trim().toLowerCase() == 'booked' ||
                        isPendingPayment)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        child: Column(
                          children: [
                            Text(
                              'PASS ID',
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSec(context),
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              passId,
                              style: GoogleFonts.montserrat(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isPendingPayment
                                    ? Colors.orange
                                    : AppColors.primary,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (isPendingPayment
                                            ? Colors.orange
                                            : AppColors.primary)
                                        .withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isPendingPayment
                                    ? 'Pass inactive until payment completes'
                                    : 'Show this pass at the venue',
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isPendingPayment
                                      ? Colors.orange
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Retry Payment Button ──
            if (isPendingPayment) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isRetrying ? null : _initiateRetryPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isRetrying
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: Lottie.asset(
                            'assets/animations/loader.json',
                            fit: BoxFit.contain,
                          ),
                        )
                      : Text(
                          'RETRY PAYMENT',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Complete your payment to confirm the booking.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: AppColors.textSec(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.subtleBg(context),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSec(context),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
      case 'pending_payment':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'pending':
      case 'pending_payment':
        return Icons.access_time_filled;
      default:
        return Icons.help;
    }
  }
}
