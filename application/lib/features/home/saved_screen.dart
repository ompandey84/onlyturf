import 'package:application/core/theme/app_colors.dart';
import 'package:application/core/widgets/shimmer_loading.dart';
import 'package:application/features/facilities/facility_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => SavedScreenState();
}

class SavedScreenState extends State<SavedScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  void refresh() {
    _fetchFavorites();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final data = await _supabase
          .from('user_favorites')
          .select('facility_id, created_at, facilities(*)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> venues = [];
      for (final item in data) {
        if (item['facilities'] != null) {
          final facility = Map<String, dynamic>.from(item['facilities']);
          facility['favorite_id'] = item['facility_id'];
          venues.add(facility);
        }
      }
      if (mounted) {
        setState(() {
          _favorites = venues;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeFavorite(String facilityId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      await _supabase
          .from('user_favorites')
          .delete()
          .eq('user_id', user.id)
          .eq('facility_id', facilityId);
      _fetchFavorites();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error removing: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: user == null
          ? _buildLoginPrompt()
          : _isLoading
          ? const SavedShimmer()
          : _favorites.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _fetchFavorites,
              child: CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(child: _buildHeader()),
                  // Counter
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Text(
                        '${_favorites.length} VENUE${_favorites.length == 1 ? '' : 'S'} SAVED',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          color: AppColors.textSec(context),
                        ),
                      ),
                    ),
                  ),
                  // Cards
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildCollectionCard(_favorites[index]),
                        ),
                        childCount: _favorites.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Header ──
  Widget _buildHeader() {
    // Sort icon removed per user request
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Collection',
              style: GoogleFonts.montserrat(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your curated selection of venues',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: AppColors.textSec(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Collection Card (Stitch Design 3 style) ──
  Widget _buildCollectionCard(Map<String, dynamic> facility) {
    final name = facility['name'] ?? 'Unknown';
    final location = facility['location'] ?? '';
    final imageUrl = facility['image_url'] ?? '';
    final price = (facility['price_per_hour'] ?? 0) as num;
    final rating = (facility['rating'] ?? 4.5).toDouble();
    final sportType = facility['sport_type'] ?? 'Sports';
    final facilityId = facility['id']?.toString() ?? '';

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FacilityDetailsScreen(facility: facility),
          ),
        );
        _fetchFavorites();
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image + Overlays ──
            Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 160,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.subtleBg(context),
                      child: Center(
                        child: Icon(
                          Icons.sports_soccer,
                          size: 40,
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ),
                // Gradient overlay at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                  ),
                ),
                // Sport tag top-left
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      sportType.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                // Favorite heart top-right
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => _removeFavorite(facilityId),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.4),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                // Rating bottom-left
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Info Section ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.montserrat(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 13,
                        color: AppColors.textSec(context),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: AppColors.textSec(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Dashed divider ──
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final dashWidth = 5.0;
                      final dashCount = (constraints.maxWidth / (dashWidth * 2))
                          .floor();
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
                  const SizedBox(height: 12),

                  // ── Price + "View Details" ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FROM',
                            style: GoogleFonts.montserrat(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                              color: AppColors.textSec(context),
                            ),
                          ),
                          Text(
                            '₹${price.toStringAsFixed(0)}/hr',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View Details',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.bookmark_border,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your Collection Awaits',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to curate your\nfavorite venues.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: AppColors.textSec(context),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 48,
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Saved Venues',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap the heart on any venue\nto add it to your collection.',
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
}
