import 'dart:async';
import 'dart:ui';
import 'package:application/core/services/notification_service.dart';
import 'package:application/core/theme/app_colors.dart';
import 'package:application/core/widgets/shimmer_loading.dart';
import 'package:application/features/facilities/facilities_screen.dart';
import 'package:application/core/widgets/location_search_sheet.dart';
import 'package:application/features/facilities/facility_details_screen.dart';
import 'package:application/features/home/notifications_screen.dart';
import 'package:application/features/home/profile_screen.dart';
import 'package:application/features/home/search_facilities_delegate.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeTab extends StatefulWidget {
  final String selectedCity;
  final String userGender;
  final ValueChanged<String> onCityChanged;

  const HomeTab({
    super.key,
    required this.selectedCity,
    required this.userGender,
    required this.onCityChanged,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

enum ViewStyle { list, grid, card }

class _HomeTabState extends State<HomeTab> with TickerProviderStateMixin {
  String _selectedSport = 'All';
  ViewStyle _viewStyle = ViewStyle.card;

  String get _avatarUrl {
    final seed = widget.userGender.toLowerCase() == 'female' ? 'Lily' : 'Felix';
    return 'https://api.dicebear.com/7.x/micah/png?seed=$seed&backgroundColor=b6e3f4,c0aede,d1d4f9';
  }

  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _facilities = [];
  List<Map<String, dynamic>> _latestFacilities = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _pageSize = 10;

  // Sport selector
  final GlobalKey _sportRowKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _fetchFacilities();
    _fetchLatestFacilities();
    _scrollController.addListener(_onScroll);
    if (widget.selectedCity.isNotEmpty) {
      NotificationService().scheduleTurfNotifications(widget.selectedCity);
    }
  }

  @override
  void didUpdateWidget(HomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCity != oldWidget.selectedCity) {
      _currentPage = 0;
      _facilities.clear();
      _hasMore = true;
      _fetchFacilities();
      if (widget.selectedCity.isNotEmpty) {
        NotificationService().scheduleTurfNotifications(widget.selectedCity);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchFacilities();
    }
  }

  Future<void> _fetchFacilities({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _currentPage = 0;
      _hasMore = true;
      _facilities.clear();
    }
    if (!_hasMore) return;

    setState(() => _isLoading = true);

    try {
      var query = Supabase.instance.client
          .from('facilities')
          .select()
          .ilike('location', '%${widget.selectedCity}%');

      if (_selectedSport != 'All') {
        query = query.ilike('sport_type', '%$_selectedSport%');
      }

      final start = _currentPage * _pageSize;
      final end = start + _pageSize - 1;

      final response = await query.range(start, end);
      final newFacilities = List<Map<String, dynamic>>.from(response);

      if (mounted) {
        setState(() {
          if (newFacilities.length < _pageSize) _hasMore = false;
          _facilities.addAll(newFacilities);
          _currentPage++;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching facilities: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onFilterChanged(String location, String sport) {
    if (location != widget.selectedCity) widget.onCityChanged(location);
    if (sport != _selectedSport) {
      setState(() => _selectedSport = sport);
      _fetchFacilities(refresh: true);
    }
  }

  Future<void> _fetchLatestFacilities() async {
    try {
      var query = Supabase.instance.client
          .from('facilities')
          .select()
          .ilike('location', '%${widget.selectedCity}%')
          .order('created_at', ascending: false)
          .limit(8);

      final response = await query;
      final data = List<Map<String, dynamic>>.from(response);
      if (mounted) {
        setState(() => _latestFacilities = data);
      }
    } catch (e) {
      debugPrint('Error fetching latest facilities: $e');
    }
  }

  static const _sportOptions = [
    {'name': 'All', 'icon': Icons.apps, 'color': Color(0xFFD4AF37)},
    {
      'name': 'Cricket',
      'icon': Icons.sports_cricket,
      'color': Color(0xFF4CAF50),
    },
    {
      'name': 'Football',
      'icon': Icons.sports_soccer,
      'color': Color(0xFF2196F3),
    },
    {
      'name': 'Badminton',
      'icon': Icons.sports_tennis,
      'color': Color(0xFFFF9800),
    },
    {'name': 'Tennis', 'icon': Icons.sports_tennis, 'color': Color(0xFFE91E63)},
    {
      'name': 'Basketball',
      'icon': Icons.sports_basketball,
      'color': Color(0xFFFF5722),
    },
    {'name': 'Swimming', 'icon': Icons.pool, 'color': Color(0xFF3F51B5)},
    {
      'name': 'Pickleball',
      'icon': Icons.sports_handball,
      'color': Color(0xFF9C27B0),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await _fetchFacilities(refresh: true);
            },
            color: AppColors.primary,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // App Bar
                SliverAppBar(
                  pinned: true,
                  backgroundColor: AppColors.background(context),
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  toolbarHeight: 56,
                  title: Text(
                    'COURTSIDE',
                    style: GoogleFonts.montserrat(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 3,
                    ),
                  ),
                  centerTitle: true,
                  automaticallyImplyLeading: false,
                  leading: IconButton(
                    icon: Stack(
                      children: [
                        Icon(
                          Icons.notifications,
                          color: AppColors.textMain(context),
                        ),
                        Positioned(
                          right: 2,
                          top: 2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.statusCancelled,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          backgroundImage:
                              Supabase.instance.client.auth.currentUser != null
                              ? NetworkImage(_avatarUrl)
                              : null,
                          child:
                              Supabase.instance.client.auth.currentUser == null
                              ? const Icon(
                                  Icons.person,
                                  color: AppColors.primary,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),

                // Hero heading
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.montserrat(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMain(context),
                            ),
                            children: [
                              const TextSpan(text: 'Find Your '),
                              TextSpan(
                                text: 'Perfect Game',
                                style: TextStyle(color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Curated courts & exclusive venues',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSec(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Search bar (moved up, bigger)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickySearchDelegate(
                    selectedCity: widget.selectedCity,
                    selectedSport: _selectedSport,
                    backgroundColor: AppColors.background(context),
                    cardColor: AppColors.card(context),
                    textColor: AppColors.textMain(context),
                    secTextColor: AppColors.textSec(context),
                    onCityTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: AppColors.card(context),
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (ctx) => LocationSearchSheet(
                          selectedCity: widget.selectedCity,
                          onCitySelected: (city) {
                            Navigator.pop(ctx);
                            _onFilterChanged(city, _selectedSport);
                          },
                          onUseCurrentLocation: () {
                            Navigator.pop(ctx);
                          },
                        ),
                      );
                    },
                    onSearchTap: () {
                      showSearch(
                        context: context,
                        delegate: SearchFacilitiesDelegate(),
                      );
                    },
                    onFilterTap: () => _showFilterSheet(),
                  ),
                ),

                // ── Latest Added Section (Horizontal scroll) ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Text(
                      'Latest Added',
                      style: GoogleFonts.montserrat(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMain(context),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _latestFacilities.isEmpty
                      ? const SizedBox.shrink()
                      : SizedBox(
                          height: 190,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            reverse: true, // scroll from right to left
                            itemCount: _latestFacilities.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              return _buildLatestCard(
                                context,
                                _latestFacilities[index],
                              );
                            },
                          ),
                        ),
                ),

                // ── Horizontal Sport Selector ──
                SliverToBoxAdapter(
                  child: Padding(
                    key: _sportRowKey,
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
                    child: SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _sportOptions.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final sport = _sportOptions[index];
                          final name = sport['name'] as String;
                          final icon = sport['icon'] as IconData;
                          final color = sport['color'] as Color;
                          final isSelected = _selectedSport == name;
                          return GestureDetector(
                            onTap: () => _onSportTapped(name, color),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color.withValues(alpha: 0.15)
                                    : AppColors.card(context),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: isSelected
                                      ? color
                                      : AppColors.divider(
                                          context,
                                        ).withValues(alpha: 0.5),
                                  width: isSelected ? 1.5 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icon, size: 18, color: color),
                                  const SizedBox(width: 6),
                                  Text(
                                    name,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? color
                                          : AppColors.textMain(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Section header + view toggle
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Popular Venues',
                            style: GoogleFonts.montserrat(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _buildCycleViewToggle(),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FacilitiesScreen(
                                  selectedCity: widget.selectedCity,
                                  onCityChanged: widget.onCityChanged,
                                  initialSport: _selectedSport == 'All'
                                      ? null
                                      : _selectedSport,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'See All',
                            style: GoogleFonts.montserrat(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Venue cards — switches by view style
                _facilities.isEmpty && !_isLoading
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(
                            child: Text(
                              'No facilities found for this location.',
                              style: TextStyle(
                                color: AppColors.textSec(context),
                              ),
                            ),
                          ),
                        ),
                      )
                    : _buildVenueSliver(),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onSportTapped(String sport, Color color) {
    if (sport == _selectedSport) return;

    setState(() {
      _selectedSport = sport;
    });

    _fetchFacilities(refresh: true);
  }

  void _showFilterSheet() {
    String tempSport = _selectedSport;
    String tempCity = widget.selectedCity;
    String tempSort = 'rating';

    final sports = [
      'All',
      'Football',
      'Cricket',
      'Badminton',
      'Tennis',
      'Basketball',
      'Swimming',
      'Pickleball',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filter & Sort',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        tempSport = 'All';
                        tempCity = widget.selectedCity;
                        tempSort = 'rating';
                      });
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Sport Type
              Text(
                'Sport Type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain(context),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sports.map((sport) {
                  final isSelected = tempSport == sport;
                  return GestureDetector(
                    onTap: () => setModalState(() => tempSport = sport),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.subtleBg(context),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.divider(context),
                        ),
                      ),
                      child: Text(
                        sport,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textMain(context),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              // Sort By
              Text(
                'Sort By',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain(context),
                ),
              ),
              const SizedBox(height: 10),
              ...['rating', 'price_low', 'price_high'].map((option) {
                final labels = {
                  'rating': 'Top Rated',
                  'price_low': 'Price: Low to High',
                  'price_high': 'Price: High to Low',
                };
                final icons = {
                  'rating': Icons.star,
                  'price_low': Icons.arrow_downward,
                  'price_high': Icons.arrow_upward,
                };
                final isSelected = tempSort == option;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(
                    icons[option],
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSec(context),
                    size: 20,
                  ),
                  title: Text(
                    labels[option]!,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textMain(context),
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                          size: 20,
                        )
                      : null,
                  onTap: () => setModalState(() => tempSort = option),
                );
              }),
              const SizedBox(height: 16),
              // City
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: AppColors.card(context),
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (ctx2) => LocationSearchSheet(
                      selectedCity: tempCity,
                      onCitySelected: (city) {
                        Navigator.pop(ctx2);
                        _onFilterChanged(city, tempSport);
                      },
                      onUseCurrentLocation: () {
                        Navigator.pop(ctx2);
                      },
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.subtleBg(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider(context)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tempCity,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Text(
                        'Change',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Apply button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _onFilterChanged(tempCity, tempSport);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVenueCard(BuildContext context, Map<String, dynamic> facility) {
    final name = facility['name'] ?? 'Venue';
    final location = facility['location'] ?? '';
    final sport = facility['sport_type'] ?? '';
    final price = facility['price_per_hour'] ?? 0;
    final rating = (facility['rating'] ?? 4.5).toDouble();
    final images = facility['images'];
    final imageUrl = images is List && images.isNotEmpty
        ? images[0]
        : 'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?q=80&w=400';
    final isActive = facility['is_active'] ?? true;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FacilityDetailsScreen(facility: facility),
          ),
        );
      },
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
              child: SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        child: const Icon(
                          Icons.sports,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    // Rating badge
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.7),
                              Colors.black.withValues(alpha: 0.5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 10,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Green dot
                    if (isActive)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.statusConfirmed,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Name + Price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Builder(
                          builder: (context) {
                            int slotDur = 1;
                            try {
                              final sched = facility['operating_schedule'];
                              if (sched is Map)
                                slotDur = sched['slot_duration'] ?? 1;
                            } catch (_) {}
                            return RichText(
                              text: TextSpan(
                                style: GoogleFonts.montserrat(
                                  color: AppColors.textMain(context),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                children: [
                                  TextSpan(text: '₹$price'),
                                  TextSpan(
                                    text: '/${slotDur}hr',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 10,
                                      color: AppColors.textSec(context),
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.place,
                          size: 12,
                          color: AppColors.textSec(context),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSec(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Tags + Book Now
                    Row(
                      children: [
                        _buildTag(sport),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    FacilityDetailsScreen(facility: facility),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.subtleBg(context),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'BOOK',
                              style: GoogleFonts.montserrat(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Single Cycling View Toggle ────────────────────────────────
  Widget _buildCycleViewToggle() {
    final styles = ViewStyle.values;
    final icons = {
      ViewStyle.list: Icons.view_list,
      ViewStyle.grid: Icons.grid_view,
      ViewStyle.card: Icons.view_agenda,
    };
    return GestureDetector(
      onTap: () {
        final nextIndex = (styles.indexOf(_viewStyle) + 1) % styles.length;
        setState(() => _viewStyle = styles[nextIndex]);
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => RotationTransition(
          turns: Tween(begin: 0.5, end: 1.0).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Container(
          key: ValueKey(_viewStyle),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icons[_viewStyle], size: 18, color: AppColors.primary),
        ),
      ),
    );
  }

  // ─── Latest Added Card (horizontal scroll) ────────────────────────
  Widget _buildLatestCard(BuildContext context, Map<String, dynamic> facility) {
    final name = facility['name'] ?? 'Venue';
    final location = facility['location'] ?? '';
    final sport = facility['sport_type'] ?? '';
    final price = facility['price_per_hour'] ?? 0;
    final images = facility['images'];
    final imageUrl = images is List && images.isNotEmpty
        ? images[0]
        : 'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?q=80&w=400';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FacilityDetailsScreen(facility: facility),
        ),
      ),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: SizedBox(
                height: 100,
                width: double.infinity,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.sports,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain(context),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        Icons.place,
                        size: 10,
                        color: AppColors.textSec(context),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSec(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildTag(sport),
                      const Spacer(),
                      Text(
                        '₹$price',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Venue Sliver – pick layout per ViewStyle ──────────────────
  Widget _buildVenueSliver() {
    switch (_viewStyle) {
      case ViewStyle.grid:
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index == _facilities.length) {
                return _isLoading
                    ? ShimmerEffect(
                        child: ShimmerBox(height: 160, borderRadius: 12),
                      )
                    : const SizedBox.shrink();
              }
              return _buildGridCard(context, _facilities[index]);
            }, childCount: _facilities.length + 1),
          ),
        );
      case ViewStyle.card:
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index == _facilities.length) {
                return _isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: ShimmerEffect(
                          child: ShimmerBox(height: 180, borderRadius: 16),
                        ),
                      )
                    : const SizedBox(height: 100);
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildZomatoCard(context, _facilities[index]),
              );
            }, childCount: _facilities.length + 1),
          ),
        );
      case ViewStyle.list:
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index == _facilities.length) {
                return _isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: ShimmerEffect(
                          child: ShimmerBox(height: 90, borderRadius: 12),
                        ),
                      )
                    : const SizedBox(height: 100);
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildVenueCard(context, _facilities[index]),
              );
            }, childCount: _facilities.length + 1),
          ),
        );
    }
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.subtleBg(context),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.textSec(context),
        ),
      ),
    );
  }

  // ─── Flipkart-style 2-column GRID card ─────────────────────────
  Widget _buildGridCard(BuildContext context, Map<String, dynamic> facility) {
    final name = facility['name'] ?? 'Venue';
    final location = facility['location'] ?? '';
    final sport = facility['sport_type'] ?? '';
    final price = facility['price_per_hour'] ?? 0;
    final rating = (facility['rating'] ?? 4.5).toDouble();
    final images = facility['images'];
    final imageUrl = images is List && images.isNotEmpty
        ? images[0]
        : 'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?q=80&w=400';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FacilityDetailsScreen(facility: facility),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: AspectRatio(
                aspectRatio: 1.2,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        child: const Icon(
                          Icons.sports,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                    ),
                    // Rating badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Sport tag
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          sport,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.place,
                          size: 11,
                          color: AppColors.textSec(context),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSec(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Builder(
                          builder: (context) {
                            int slotDur = 1;
                            try {
                              final sched = facility['operating_schedule'];
                              if (sched is Map)
                                slotDur = sched['slot_duration'] ?? 1;
                            } catch (_) {}
                            return RichText(
                              text: TextSpan(
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textMain(context),
                                ),
                                children: [
                                  TextSpan(text: '₹$price'),
                                  TextSpan(
                                    text: '/${slotDur}hr',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 10,
                                      color: AppColors.textSec(context),
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'BOOK',
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Zomato-style large vertical CARD ──────────────────────────
  Widget _buildZomatoCard(BuildContext context, Map<String, dynamic> facility) {
    final name = facility['name'] ?? 'Venue';
    final location = facility['location'] ?? '';
    final sport = facility['sport_type'] ?? '';
    final price = facility['price_per_hour'] ?? 0;
    final rating = (facility['rating'] ?? 4.5).toDouble();
    final images = facility['images'];
    final imageUrl = images is List && images.isNotEmpty
        ? images[0]
        : 'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?q=80&w=800';
    final isActive = facility['is_active'] ?? true;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FacilityDetailsScreen(facility: facility),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Large image with gradient overlay
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        child: const Icon(
                          Icons.sports,
                          color: AppColors.primary,
                          size: 48,
                        ),
                      ),
                    ),
                    // Bottom gradient
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Name overlay
                    Positioned(
                      bottom: 12,
                      left: 14,
                      right: 14,
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Open badge
                    if (isActive)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'OPEN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    // Rating pill
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber.shade700,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Details row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  // Location + sport
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.place,
                              size: 13,
                              color: AppColors.textSec(context),
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSec(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                sport,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Price + Book
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Builder(
                        builder: (context) {
                          int slotDur = 1;
                          try {
                            final sched = facility['operating_schedule'];
                            if (sched is Map)
                              slotDur = sched['slot_duration'] ?? 1;
                          } catch (_) {}
                          return RichText(
                            text: TextSpan(
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMain(context),
                              ),
                              children: [
                                TextSpan(text: '₹$price'),
                                TextSpan(
                                  text: '/${slotDur}hr',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 11,
                                    color: AppColors.textSec(context),
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'RESERVE',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Sticky search delegate for pinned search bar
class _StickySearchDelegate extends SliverPersistentHeaderDelegate {
  final String selectedCity;
  final String selectedSport;
  final Color backgroundColor;
  final Color cardColor;
  final Color textColor;
  final Color secTextColor;
  final VoidCallback onCityTap;
  final VoidCallback onSearchTap;
  final VoidCallback onFilterTap;

  _StickySearchDelegate({
    required this.selectedCity,
    required this.selectedSport,
    required this.backgroundColor,
    required this.cardColor,
    required this.textColor,
    required this.secTextColor,
    required this.onCityTap,
    required this.onSearchTap,
    required this.onFilterTap,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          // City Selector
          GestureDetector(
            onTap: onCityTap,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  if (shrinkOffset > 0)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 20,
                    color: Color(0xFFD4AF37),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    selectedCity,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: secTextColor,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Search Bar
          Expanded(
            child: GestureDetector(
              onTap: onSearchTap,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    if (shrinkOffset > 0)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Search venues...',
                        style: TextStyle(
                          fontSize: 14,
                          color: secTextColor,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onFilterTap,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Icon(
                          Icons.tune,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 64;

  @override
  double get minExtent => 64;

  @override
  bool shouldRebuild(covariant _StickySearchDelegate oldDelegate) {
    return oldDelegate.selectedCity != selectedCity ||
        oldDelegate.selectedSport != selectedSport ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.cardColor != cardColor ||
        oldDelegate.textColor != textColor ||
        oldDelegate.secTextColor != secTextColor;
  }
}
