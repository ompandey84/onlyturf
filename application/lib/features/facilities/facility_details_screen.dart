import 'dart:ui';
import 'dart:async';
import 'package:application/core/theme/app_colors.dart';
import 'package:application/features/booking/booking_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FacilityDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> facility;

  const FacilityDetailsScreen({super.key, required this.facility});

  @override
  State<FacilityDetailsScreen> createState() => _FacilityDetailsScreenState();
}

class _FacilityDetailsScreenState extends State<FacilityDetailsScreen> {
  int _currentPage = 0;
  bool _isFavorited = false;
  final _supabase = Supabase.instance.client;

  Timer? _timer;
  late PageController _pageController;

  List<Map<String, dynamic>> _reviews = [];
  bool _isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _checkFavoriteStatus();
    _startTimer();
    _fetchReviews();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  List<String> _getImages() {
    final imageUrl =
        widget.facility['image_url'] ?? 'https://via.placeholder.com/300';
    List<String> images = [];
    if (widget.facility['images'] != null) {
      images = List<String>.from(widget.facility['images']);
    }
    if (images.isEmpty) images = [imageUrl];
    return images;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_pageController.hasClients) {
        int nextPage = _pageController.page!.round() + 1;
        List<String> images = _getImages();
        if (images.isNotEmpty && nextPage >= images.length) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  Future<void> _checkFavoriteStatus() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    final facilityId = widget.facility['id'];
    if (facilityId == null) return;
    try {
      final data = await _supabase
          .from('user_favorites')
          .select('id')
          .eq('user_id', user.id)
          .eq('facility_id', facilityId)
          .maybeSingle();
      if (mounted) {
        setState(() => _isFavorited = data != null);
      }
    } catch (_) {}
  }

  Future<void> _fetchReviews() async {
    final facilityId = widget.facility['id'];
    if (facilityId == null) {
      if (mounted) setState(() => _isLoadingReviews = false);
      return;
    }
    try {
      final response = await _supabase
          .from('reviews')
          .select('id, rating, comment, created_at, profiles(full_name)')
          .eq('facility_id', facilityId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _reviews = List<Map<String, dynamic>>.from(response);
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingReviews = false);
      }
    }
  }

  Future<void> _showReviewDialog() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to write a review.')),
      );
      return;
    }

    final facilityId = widget.facility['id'];
    if (facilityId == null) return;

    // Check if user has a confirmed booking for this facility
    try {
      final bookings = await _supabase
          .from('bookings')
          .select('id')
          .eq('user_id', user.id)
          .eq('facility_id', facilityId)
          .eq('status', 'confirmed')
          .limit(1);

      if (bookings.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'You must book and visit this venue before reviewing.',
              ),
            ),
          );
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error checking booking status. Please try again later.',
            ),
          ),
        );
      }
      return;
    }

    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.background(context),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => _ReviewBottomSheet(
          userId: user.id,
          facilityId: facilityId,
          onSubmit: (newReview) {
            if (mounted) {
              setState(() {
                // Format it instantly
                final profileMap = <String, dynamic>{
                  'full_name': user.userMetadata?['full_name'] ?? 'You',
                };
                newReview['profiles'] = profileMap;

                // Prepend immediately to show instantly
                _reviews.insert(0, newReview);
              });
            }
            // Also do a quiet background refresh to stay in sync
            _fetchReviews();
          },
        ),
      );
    }
  }

  Future<void> _toggleFavorite() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to save venues')),
      );
      return;
    }
    final facilityId = widget.facility['id'];
    if (facilityId == null) return;
    try {
      if (_isFavorited) {
        await _supabase
            .from('user_favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('facility_id', facilityId);
      } else {
        await _supabase.from('user_favorites').insert({
          'user_id': user.id,
          'facility_id': facilityId,
        });
      }
      if (mounted) {
        setState(() => _isFavorited = !_isFavorited);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.facility['name'] ?? 'Unknown Venue';
    final imageUrl =
        widget.facility['image_url'] ?? 'https://via.placeholder.com/300';

    List<String> images = [];
    if (widget.facility['images'] != null) {
      images = List<String>.from(widget.facility['images']);
    }
    if (images.isEmpty) images = [imageUrl];

    final price = (widget.facility['price_per_hour'] ?? 0) as num;
    final location = widget.facility['location'] ?? 'Unknown Location';
    final description =
        widget.facility['description'] ?? 'No description available.';
    final amenities = List<String>.from(widget.facility['amenities'] ?? []);
    final double rating = (widget.facility['rating'] ?? 4.5).toDouble();

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Full-bleed hero image
              SliverToBoxAdapter(child: _buildHeroImage(context, images)),

              // Pull-up white panel with rounded top
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Venue header
                          _buildVenueHeader(name, location, rating),
                          const SizedBox(height: 20),

                          // Price badge
                          _buildPriceBadge(price),
                          const SizedBox(height: 20),

                          // About
                          const Text(
                            'About',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSec(context),
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Amenities
                          if (amenities.isNotEmpty) _buildAmenities(amenities),
                          const SizedBox(height: 20),

                          // Reviews
                          _buildReviewsSection(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Back, Share, Favorite action buttons
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionCircle(
                  Icons.arrow_back,
                  () => Navigator.pop(context),
                ),
                _buildActionCircle(
                  _isFavorited ? Icons.favorite : Icons.favorite,
                  _toggleFavorite,
                  color: _isFavorited ? Colors.red : null,
                ),
              ],
            ),
          ),

          // Sticky bottom bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildStickyBottomBar(context, price),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage(BuildContext context, List<String> images) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.38,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Listener(
            onPointerDown: (_) => _stopTimer(),
            onPointerUp: (_) => _startTimer(),
            onPointerCancel: (_) => _startTimer(),
            child: PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _openFullScreenImage(index, images),
                  child: Image.network(
                    images[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: AppColors.subtleBg(context)),
                  ),
                );
              },
            ),
          ),
          // Gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                  ],
                  stops: const [0, 0.5, 1],
                ),
              ),
            ),
          ),
          // Page indicator
          if (images.length > 1)
            Positioned(
              bottom: 36,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentPage == index ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          // Gallery button
          Positioned(
            bottom: 36,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.grid_view,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Gallery (${images.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCircle(IconData icon, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color ?? Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildVenueHeader(String name, String location, double rating) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            // Rating badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.statusConfirmed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star,
                    color: AppColors.statusConfirmed,
                    size: 14,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: AppColors.statusConfirmed,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.place, size: 16, color: AppColors.textSec(context)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                location,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSec(context),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceBadge(num price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '₹${price.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          Text(
            ' /hour',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textSec(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenities(List<String> amenities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amenities',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: amenities.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, index) => _buildAmenityIcon(amenities[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildAmenityIcon(String label) {
    IconData icon;
    switch (label.toLowerCase()) {
      case 'parking':
        icon = Icons.local_parking;
        break;
      case 'wifi':
        icon = Icons.wifi;
        break;
      case 'showers':
        icon = Icons.shower;
        break;
      case 'changing room':
        icon = Icons.checkroom;
        break;
      case 'water':
        icon = Icons.water_drop;
        break;
      case 'cafe':
        icon = Icons.local_cafe;
        break;
      case 'lockers':
        icon = Icons.lock;
        break;
      default:
        icon = Icons.check_circle;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.subtleBg(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: AppColors.textSec(context)),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.textSec(context),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Reviews',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: _showReviewDialog,
              child: const Text(
                'Write a Review',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoadingReviews)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_reviews.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Center(
              child: Text(
                'No reviews yet. Be the first to review!',
                style: TextStyle(
                  color: AppColors.textSec(context),
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ..._reviews.map((review) {
            final profile = review['profiles'] as Map<String, dynamic>?;
            final fullName = profile?['full_name'] ?? 'Anonymous user';
            final rating = (review['rating'] as num?)?.toInt() ?? 5;
            final comment = review['comment'] ?? '';
            final createdAtStr = review['created_at'] as String?;
            final timeAgo = _getTimeAgo(createdAtStr);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildReviewCard(fullName, rating, comment, timeAgo),
            );
          }),
      ],
    );
  }

  String _getTimeAgo(String? dateTimeStr) {
    if (dateTimeStr == null) return '';
    try {
      final date = DateTime.parse(dateTimeStr).toLocal();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 1) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays == 1) {
        return '1 day ago';
      } else if (difference.inHours > 1) {
        return '${difference.inHours} hours ago';
      } else if (difference.inHours == 1) {
        return '1 hour ago';
      } else if (difference.inMinutes > 1) {
        return '${difference.inMinutes} minutes ago';
      } else if (difference.inMinutes == 1) {
        return '1 minute ago';
      } else {
        return 'just now';
      }
    } catch (e) {
      return '';
    }
  }

  Widget _buildReviewCard(
    String user,
    int stars,
    String comment,
    String timeAgo,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.subtleBg(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  user[0],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                user,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              if (timeAgo.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSec(context).withValues(alpha: 0.6),
                  ),
                ),
              ],
              const Spacer(),
              ...List.generate(
                5,
                (index) => Icon(
                  index < stars ? Icons.star : Icons.star_border,
                  size: 14,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment,
            style: TextStyle(
              color: AppColors.textSec(context),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomBar(BuildContext context, num price) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          decoration: BoxDecoration(
            color: AppColors.card(context).withValues(alpha: 0.85),
            border: Border(top: BorderSide(color: AppColors.divider(context))),
          ),
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: TextStyle(color: AppColors.textMain(context)),
                          children: [
                            TextSpan(
                              text: '₹${price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: ' / 1 hr',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSec(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Select slots to proceed',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSec(context),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BookingScreen(facility: widget.facility),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                      shadowColor: AppColors.primary.withValues(alpha: 0.3),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Book Now',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openFullScreenImage(int initialIndex, List<String> images) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: PageView.builder(
            itemCount: images.length,
            controller: PageController(initialPage: initialIndex),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                child: Center(
                  child: Image.network(images[index], fit: BoxFit.contain),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ReviewBottomSheet extends StatefulWidget {
  final String userId;
  final String facilityId;
  final Function(Map<String, dynamic>) onSubmit;

  const _ReviewBottomSheet({
    required this.userId,
    required this.facilityId,
    required this.onSubmit,
  });

  @override
  State<_ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<_ReviewBottomSheet> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a rating.')));
      return;
    }
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please write a comment.')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final newReview = await Supabase.instance.client
          .from('reviews')
          .insert({
            'facility_id': widget.facilityId,
            'user_id': widget.userId,
            'rating': _rating,
            'comment': _commentController.text.trim(),
          })
          .select()
          .single();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Thank you for review',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.primary,
          ),
        );
        widget.onSubmit(newReview);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error posting review: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Write a Review',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain(context),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 36,
                ),
                onPressed: () => setState(() => _rating = index + 1),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Share your experience...',
              filled: true,
              fillColor: AppColors.subtleBg(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Submit Review',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
