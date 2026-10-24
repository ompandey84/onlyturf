import 'package:application/core/theme/app_colors.dart';
import 'package:application/core/widgets/shimmer_loading.dart';
import 'package:application/features/auth/login_screen.dart';
import 'package:application/features/profile/edit_profile_screen.dart';
import 'package:application/features/profile/help_support_screen.dart';
import 'package:application/features/home/saved_screen.dart';
import 'package:application/features/profile/settings_screen.dart';
import 'package:application/features/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Member Access Required',
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to view your profile',
                style: GoogleFonts.montserrat(color: AppColors.textSec(context)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: Text(
                  'GRANT ACCESS',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchProfile(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ProfileShimmer();
          }

          final profile = snapshot.data ?? {};
          final name = profile['full_name'] ?? 'Member';
          final city = profile['city'] ?? 'India';
          final gender = profile['gender'] ?? 'Male';

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildProfileHeader(
                  context,
                  name,
                  gender,
                  user.email ?? '',
                  city,
                  profile,
                ),
              ),
              SliverToBoxAdapter(
                child: _buildMembershipCard(context, name, user.email ?? ''),
              ),
              SliverToBoxAdapter(child: _buildMenuSection(context, profile)),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  // ── Helper ──
  String _getAvatarUrl(String gender) {
    final seed = gender.toLowerCase() == 'female' ? 'Lily' : 'Felix';
    return 'https://api.dicebear.com/7.x/micah/png?seed=$seed&backgroundColor=b6e3f4,c0aede,d1d4f9';
  }

  // ── Profile Header ──
  Widget _buildProfileHeader(
    BuildContext context,
    String name,
    String gender,
    String email,
    String city,
    Map<String, dynamic> profile,
  ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Column(
          children: [
            // Top bar — title and settings icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Profile',
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain(context),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings, color: AppColors.primary),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Avatar
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.08),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      _getAvatarUrl(gender),
                      fit: BoxFit.cover,
                      width: 88,
                      height: 88,
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'VERIFIED',
                      style: GoogleFonts.montserrat(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Name
            Text(
              name.isNotEmpty ? name : 'Loading...',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: GoogleFonts.montserrat(
                color: AppColors.textSec(context),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),

            // Edit Profile button
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(initialData: profile),
                  ),
                );
                if (result == true && context.mounted) {
                  (context as Element).markNeedsBuild();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  'EDIT PROFILE',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Helper to fetch bookings count for tier logic ──
  Future<int> _fetchBookingCount(String userId) async {
    // Count only confirmed or booked
    final response = await Supabase.instance.client
        .from('bookings')
        .count(CountOption.exact)
        .eq('user_id', userId)
        .or('status.eq.confirmed,status.eq.booked');
    return response;
  }

  Future<Map<String, dynamic>> _fetchProfile(String userId) async {
    var profile = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    // Auto-create profile for users who registered before the fix
    if (profile == null) {
      final user = Supabase.instance.client.auth.currentUser;
      final meta = user?.userMetadata ?? {};
      final newProfile = {
        'id': userId,
        'email': user?.email,
        'full_name': meta['full_name'] ?? 'Member',
        'mobile': meta['mobile'],
        'city': meta['city'],
      };
      try {
        await Supabase.instance.client.from('profiles').upsert(newProfile);
        profile = newProfile;
      } catch (e) {
        debugPrint('Error auto-creating profile: $e');
        profile = newProfile; // Use in-memory data as fallback
      }
    }

    // Fetch booking count for membership tier
    final bookingCount = await _fetchBookingCount(userId);
    final mutableProfile = Map<String, dynamic>.from(profile);
    mutableProfile['booking_count'] = bookingCount;

    // Lazy generate member_id if missing (and update DB)
    if (profile['member_id'] == null) {
      final now = DateTime.now();
      final year = now.year;
      final random = (1000 + (now.microsecond % 9000)).toString();
      final newMemberId = 'CT-PRO-$year-$random';

      try {
        await Supabase.instance.client
            .from('profiles')
            .update({'member_id': newMemberId})
            .eq('id', userId);
        mutableProfile['member_id'] = newMemberId;
      } catch (e) {
        debugPrint('Error updating member_id: $e');
        // Fallback if column doesn't exist yet
        mutableProfile['member_id'] = 'PENDING';
      }
    }

    return mutableProfile;
  }

  // ── Membership Card Wrapper ──
  Widget _buildMembershipCard(
    BuildContext context,
    String name,
    String email, [
    Map<String, dynamic>? profile,
  ]) {
    return MembershipCard(name: name, email: email, profile: profile);
  }

  // ── Menu Section ──
  Widget _buildMenuSection(BuildContext context, Map<String, dynamic> profile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── ACCOUNT ──
          _buildSectionLabel('ACCOUNT'),
          const SizedBox(height: 12),
          _buildMenuItem(
            context,
            Icons.email,
            'Email Address',
            Supabase.instance.client.auth.currentUser?.email ?? '',
            null,
          ),
          _buildMenuItem(
            context,
            Icons.favorite,
            'Saved Venues',
            'Your favorite courts',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SavedScreen()),
              );
            },
          ),
          const SizedBox(height: 20),

          // ── SUPPORT ──
          _buildSectionLabel('SUPPORT'),
          const SizedBox(height: 12),
          _buildMenuItem(
            context,
            Icons.headset_mic,
            'Help & Support',
            'Get assistance from our team',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
              );
            },
          ),
          const SizedBox(height: 20),

          // ── ABOUT ──
          _buildSectionLabel('ABOUT'),
          const SizedBox(height: 12),

          _buildMenuItem(
            context,
            Icons.flag,
            'Language',
            'English (Default)',
            null,
          ),
          const SizedBox(height: 24),

          // ── SIGN OUT ──
          GestureDetector(
            onTap: () => _showSignOutDialog(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.statusCancelled.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.logout,
                    size: 18,
                    color: AppColors.statusCancelled,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sign Out',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.statusCancelled,
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

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.montserrat(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        color: AppColors.textSec(context),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback? onTap, {
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.divider(context).withValues(alpha: 0.5),
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDestructive
                          ? Colors.red
                          : AppColors.textMain(context),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: AppColors.textSec(context),
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.textSec(context),
              ),
          ],
        ),
      ),
    );
  }

  // ── Sign Out Dialog ──
  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign Out',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain(context),
          ),
        ),
        content: Text(
          'Are you sure you want to sign out of your account?',
          style: GoogleFonts.montserrat(
            color: AppColors.textSec(context),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'CANCEL',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                color: AppColors.textSec(context),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                // Show success dialog then restart app
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (dialogCtx) {
                    Future.delayed(const Duration(seconds: 2), () {
                      if (dialogCtx.mounted) {
                        Navigator.of(dialogCtx).pop();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const SplashScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    });
                    return AlertDialog(
                      backgroundColor: AppColors.card(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green.withValues(alpha: 0.1),
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              size: 36,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Logged Out',
                            style: GoogleFonts.montserrat(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMain(context),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'You have been signed out successfully.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              color: AppColors.textSec(context),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusCancelled,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'SIGN OUT',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MembershipCard extends StatefulWidget {
  final String name;
  final String email;
  final Map<String, dynamic>? profile;

  const MembershipCard({
    super.key,
    required this.name,
    required this.email,
    this.profile,
  });

  @override
  State<MembershipCard> createState() => _MembershipCardState();
}

class _MembershipCardState extends State<MembershipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() => _isFront = !_isFront);
  }

  @override
  Widget build(BuildContext context) {
    // Data Preparation
    final bookingCount = widget.profile?['booking_count'] ?? 0;
    final memberId = widget.profile?['member_id'] ?? 'PENDING';
    final createdAt =
        DateTime.tryParse(widget.profile?['created_at'] ?? '') ??
        DateTime.now();
    final memberSince = createdAt.year.toString();

    // Tier Logic
    List<Color> gradientColors;
    Color textColor;
    Color labelColor;
    String tierLabel;

    // Adjusted logic: > 10 for Prestige (as per user complaint)
    if (bookingCount > 10) {
      // PRESTIGE (Black)
      gradientColors = [
        const Color(0xFF1C1C1C),
        const Color(0xFF2C2C2C),
        const Color(0xFF000000),
      ];
      textColor = Colors.white;
      labelColor = const Color(0xFFD4AF37);
      tierLabel = 'PRESTIGE';
    } else if (bookingCount >= 5) {
      // GOLD
      gradientColors = [const Color(0xFFFFD700), const Color(0xFFFDB931)];
      textColor = Colors.black87;
      labelColor = Colors.black54;
      tierLabel = 'GOLD MEMBER';
    } else {
      // SILVER / PLATINUM (Base Tier)
      gradientColors = [
        const Color(0xFFE0E0E0),
        const Color(0xFFF5F5F5),
        const Color(0xFFBDBDBD),
      ];
      textColor = Colors.black87;
      labelColor = Colors.black54;
      tierLabel = 'PLATINUM';
    }

    return GestureDetector(
      onTap: _flipCard,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            // 3D Transform
            final angle = _animation.value * pi;
            final isBack = angle >= (pi / 2);
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateY(angle);

            return Transform(
              transform: transform,
              alignment: Alignment.center,
              child: isBack
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(pi), // mirror back
                      child: _buildBack(
                        gradientColors,
                        textColor,
                        labelColor,
                        bookingCount,
                      ),
                    )
                  : _buildFront(
                      gradientColors,
                      textColor,
                      labelColor,
                      tierLabel,
                      widget.name,
                      widget.email,
                      memberId,
                      memberSince,
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFront(
    List<Color> gradientColors,
    Color textColor,
    Color labelColor,
    String tierLabel,
    String name,
    String email,
    String memberId,
    String memberSince,
  ) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Pattern
          Positioned(
            right: -40,
            top: -40,
            child: Icon(
              Icons.sports_soccer,
              size: 240,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.diamond,
                          color: labelColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'COURTSIDE',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: labelColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: labelColor.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tierLabel,
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: labelColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  name.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MEMBER SINCE',
                          style: GoogleFonts.montserrat(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: textColor.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          memberSince,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'MEMBER ID',
                          style: GoogleFonts.montserrat(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: textColor.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          memberId.toUpperCase(),
                          style: GoogleFonts.shareTechMono(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBack(
    List<Color> gradientColors,
    Color textColor,
    Color labelColor,
    int bookingCount,
  ) {
    final points = bookingCount * 3;
    final nextTier = bookingCount > 10
        ? 'MAX LEVEL'
        : bookingCount >= 5
        ? '${11 - bookingCount} to Prestige'
        : '${5 - bookingCount} to Gold';

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Magstripe
          Positioned(
            top: 24,
            left: 0,
            right: 0,
            child: Container(height: 40, color: Colors.black87),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LOYALTY POINTS',
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: labelColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$points',
                          style: GoogleFonts.montserrat(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.qr_code, color: textColor, size: 32),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'NEXT GOAL: $nextTier',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.shareTechMono(
                      fontSize: 12,
                      color: labelColor,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
