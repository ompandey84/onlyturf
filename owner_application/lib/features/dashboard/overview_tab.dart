import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:owner_application/features/facilities/slot_management_screen.dart';

class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key});

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  bool _isLoading = true;
  double _totalRevenue = 0;
  int _totalBookings = 0;
  List<Map<String, dynamic>> _recentBookings = [];
  List<Map<String, dynamic>> _ownerFacilities = [];
  String _userName = 'Owner';

  // Chart Data
  List<double> _weeklyRevenue = List.filled(7, 0.0);
  double _maxRevenue = 100;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final now = DateTime.now();
      final today = DateFormat('yyyy-MM-dd').format(now);
      final sevenDaysAgo = DateFormat(
        'yyyy-MM-dd',
      ).format(now.subtract(const Duration(days: 6)));

      // 1. Get User Name
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .single();
      _userName = profile['full_name'] ?? 'Owner';

      // 2. Get Owner's Facilities
      final facilitiesResponse = await Supabase.instance.client
          .from('facilities')
          .select('id, name')
          .eq('owner_id', userId);

      final facilitiesList = List<Map<String, dynamic>>.from(
        facilitiesResponse,
      );
      final facilityIds = facilitiesList.map((e) => e['id'] as String).toList();

      if (facilityIds.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 3. Get Bookings for Last 7 Days (for Chart & Today's Stats)
      final bookingsResponse = await Supabase.instance.client
          .from('bookings')
          .select('date, total_price')
          .inFilter('facility_id', facilityIds)
          .gte('date', sevenDaysAgo)
          .lte('date', today);

      double todayRevenue = 0;
      int todayBookingsCount = 0;
      List<double> weeklyRev = List.filled(7, 0.0);

      for (var booking in bookingsResponse as List) {
        final dateStr = booking['date'] as String;
        final price = (booking['total_price'] as num).toDouble();

        // Check if today
        if (dateStr == today) {
          todayRevenue += price;
          todayBookingsCount++;
        }

        // Map to weekly chart (0 = 6 days ago, 6 = today)
        final bookingDate = DateTime.parse(dateStr);
        final diff = now.difference(bookingDate).inDays;
        if (diff >= 0 && diff < 7) {
          weeklyRev[6 - diff] += price;
        }
      }

      // Calculate Max Revenue for Chart Scale
      double maxRev = 100;
      for (var r in weeklyRev) {
        if (r > maxRev) maxRev = r;
      }

      // 4. Get Recent Bookings (Limit 5)
      final recentResponse = await Supabase.instance.client
          .from('bookings')
          .select('*, facilities(name), profiles(full_name)')
          .inFilter('facility_id', facilityIds)
          .order('date', ascending: false)
          .limit(5);

      if (mounted) {
        setState(() {
          _totalRevenue = todayRevenue;
          _totalBookings = todayBookingsCount;
          _weeklyRevenue = weeklyRev;
          _maxRevenue = maxRev;
          _recentBookings = List<Map<String, dynamic>>.from(recentResponse);
          _ownerFacilities = facilitiesList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Welcome back, $_userName',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).primaryColor),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchDashboardData();
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Today\'s Revenue',
                      NumberFormat.currency(
                        locale: 'en_IN',
                        symbol: '₹',
                        decimalDigits: 0,
                      ).format(_totalRevenue),
                      Icons.account_balance_wallet_outlined,
                      Colors.green,
                      Colors.green.withOpacity(0.1),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      "Today's Bookings",
                      _totalBookings.toString(),
                      Icons.bookmarks_outlined,
                      Colors.blue,
                      Colors.blue.withOpacity(0.1),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Revenue Chart
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Revenue Trend (Last 7 Days)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  // Simple usage: just show label for 0 and 6
                                  if (value == 0)
                                    return const Text(
                                      '7d ago',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    );
                                  if (value == 6)
                                    return const Text(
                                      'Today',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    );
                                  return const SizedBox();
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          minX: 0,
                          maxX: 6,
                          minY: 0,
                          maxY: _maxRevenue * 1.2, // Add some buffer
                          lineBarsData: [
                            LineChartBarData(
                              spots: List.generate(7, (index) {
                                return FlSpot(
                                  index.toDouble(),
                                  _weeklyRevenue[index],
                                );
                              }),
                              isCurved: true,
                              color: Theme.of(context).primaryColor,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Quick Actions Header
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),

              // Slot Management Action
              _buildActionCard(
                context,
                title: 'Manage Slots',
                subtitle: 'Update availability & pricing',
                icon: Icons.calendar_month_outlined,
                color: const Color(0xFF6C63FF),
                onTap: () {
                  if (_ownerFacilities.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please add a facility first.'),
                      ),
                    );
                    return;
                  }

                  if (_ownerFacilities.length == 1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SlotManagementScreen(
                          facility: _ownerFacilities.first,
                        ),
                      ),
                    );
                  } else {
                    _showFacilitySelector(context);
                  }
                },
              ),

              const SizedBox(height: 32),

              // Recent Bookings Header
              Text(
                'Recent Bookings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),

              // Recent Lists
              if (_recentBookings.isEmpty)
                Container(
                  padding: const EdgeInsets.all(40),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[100]!),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 48,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No bookings yet',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _recentBookings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final booking = _recentBookings[index];
                    final facilityName =
                        booking['facilities']?['name'] ?? 'Unknown Venue';
                    final customerName =
                        booking['profiles']?['full_name'] ?? 'Guest';
                    final date = booking['date'];
                    // final time = booking['time_slot'];
                    final price = booking['total_price'];
                    final status = booking['status'] ?? 'confirmed';

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: const Icon(
                              Icons.sports_soccer,
                              color: Colors.black87,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  facilityName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$customerName • $date',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹$price',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: status == 'confirmed'
                                      ? Colors.green[50]
                                      : Colors.orange[50],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: status == 'confirmed'
                                        ? Colors.green[700]
                                        : Colors.orange[700],
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFacilitySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Facility',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ..._ownerFacilities.map(
                (f) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.stadium, color: Colors.blue),
                  ),
                  title: Text(
                    f['name'],
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SlotManagementScreen(facility: f),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color contentColor,
    Color bgeColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgeColor, shape: BoxShape.circle),
            child: Icon(icon, color: contentColor, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.black54,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
