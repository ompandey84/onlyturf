import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class BookingsTab extends StatefulWidget {
  const BookingsTab({super.key});

  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab> {
  final _userId = Supabase.instance.client.auth.currentUser!.id;
  bool _showUpcoming = true; // Toggle between Upcoming and History
  bool _isLoading = true;
  List<Map<String, dynamic>> _bookings = [];

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() => _isLoading = true);
    try {
      // Fetch all bookings
      // We will filter client-side for simplicity in this demo,
      // or we could add .gte('date', today) for upcoming but simpler to fetch recent batch and sort.
      // For a real app with many bookings, server-side filtering is better.
      final response = await Supabase.instance.client
          .from('bookings')
          .select(
            '*, facilities!inner(name, owner_id), profiles(full_name, phone_number)',
          )
          .eq('facilities.owner_id', _userId)
          .order('date', ascending: false);

      if (mounted) {
        setState(() {
          _bookings = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  List<Map<String, dynamic>> get _filteredBookings {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    return _bookings.where((b) {
      final dateStr = (b['date'] as String?) ?? '';
      // Simple string comparison works for yyyy-MM-dd
      if (_showUpcoming) {
        return dateStr.compareTo(todayStr) >= 0; // Today or future
      } else {
        return dateStr.compareTo(todayStr) < 0; // Past
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredBookings;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Bookings',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchBookings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Custom Toggle
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                _buildToggleOption('Upcoming', _showUpcoming),
                _buildToggleOption('History', !_showUpcoming),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _showUpcoming
                              ? Icons.event_available_outlined
                              : Icons.history_edu_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _showUpcoming
                              ? 'No upcoming bookings'
                              : 'No past bookings',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: filteredList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final booking = filteredList[index];
                      return _buildBookingCard(booking);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String title, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showUpcoming = title == 'Upcoming';
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: GoogleFonts.outfit(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final facility = booking['facilities'];
    final facilityName = facility != null
        ? (facility['name']?.toString() ?? 'Unknown Venue')
        : 'Unknown Venue';
    final status = booking['status']?.toString() ?? 'confirmed';

    // Format date as DD MMM YY
    String formattedDate = 'Unknown Date';
    final dateStr = booking['date']?.toString();
    if (dateStr != null && dateStr.isNotEmpty) {
      try {
        final parsedDate = DateTime.parse(dateStr);
        formattedDate = DateFormat('dd MMM yy').format(parsedDate);
      } catch (e) {
        formattedDate = dateStr;
      }
    }

    final timeSlot = booking['time_slot']?.toString() ?? 'Unknown Time';
    final totalPrice = booking['total_price']?.toString() ?? '0';

    final profile = booking['profiles'];
    final customerName = profile != null
        ? (profile['full_name']?.toString() ?? 'Guest')
        : 'Guest';
    final customerPhone = profile != null
        ? (profile['phone_number']?.toString() ?? 'N/A')
        : 'N/A';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  facilityName,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: status == 'confirmed'
                      ? Colors.green[50]
                      : Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toString().toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: status == 'confirmed'
                        ? Colors.green[700]
                        : Colors.orange[700],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_month,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    timeSlot,
                    style: GoogleFonts.outfit(
                      color: Colors.grey[500],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[100],
                child: Icon(Icons.person, size: 16, color: Colors.grey[500]),
              ),
              const SizedBox(height: 8, width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      customerPhone,
                      style: GoogleFonts.outfit(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₹$totalPrice',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
