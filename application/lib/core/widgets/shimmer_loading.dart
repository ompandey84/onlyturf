import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:application/core/theme/app_colors.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine base and highlight colors based on theme mode
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[600]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ShimmerFacilityCard extends StatelessWidget {
  const ShimmerFacilityCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          const ShimmerLoading(
            width: double.infinity,
            height: 180,
            borderRadius: 24,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title skeleton
                const ShimmerLoading(width: 140, height: 20),
                const SizedBox(height: 12),

                // Location & Rating row skeleton
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    ShimmerLoading(width: 100, height: 14),
                    ShimmerLoading(width: 40, height: 14),
                  ],
                ),
                const SizedBox(height: 16),

                // Price & Button row skeleton
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    ShimmerLoading(width: 60, height: 18),
                    ShimmerLoading(width: 80, height: 32, borderRadius: 16),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ShimmerBookingCard extends StatelessWidget {
  const ShimmerBookingCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              ShimmerLoading(width: 150, height: 20),
              ShimmerLoading(width: 60, height: 20),
            ],
          ),
          const SizedBox(height: 12),
          const ShimmerLoading(width: 100, height: 14),
          const SizedBox(height: 8),
          const ShimmerLoading(width: 80, height: 14),
        ],
      ),
    );
  }
}

class ShimmerList extends StatelessWidget {
  final int itemCount;
  final Widget child;

  const ShimmerList({Key? key, this.itemCount = 5, required this.child})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: child,
        );
      },
    );
  }
}

// Additional shimmers referenced by the codebase
class ShimmerEffect extends StatelessWidget {
  final Widget child;
  const ShimmerEffect({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[600]! : Colors.grey[100]!;
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: child,
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double height;
  final double borderRadius;
  const ShimmerBox({Key? key, required this.height, this.borderRadius = 8})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class ProfileShimmer extends StatelessWidget {
  const ProfileShimmer({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const ShimmerLoading(width: 100, height: 100, borderRadius: 50),
          const SizedBox(height: 20),
          const ShimmerLoading(width: 150, height: 20),
          const SizedBox(height: 40),
          Expanded(
            child: ShimmerList(
              itemCount: 4,
              child: const ShimmerLoading(width: double.infinity, height: 60),
            ),
          ),
        ],
      ),
    );
  }
}

class SavedShimmer extends StatelessWidget {
  const SavedShimmer({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ShimmerList(child: const ShimmerFacilityCard());
  }
}

class BookingSlotShimmer extends StatelessWidget {
  const BookingSlotShimmer({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      itemCount: 8,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemBuilder: (context, _) => const ShimmerLoading(width: 100, height: 40),
    );
  }
}

class HomeShimmer extends StatelessWidget {
  const HomeShimmer({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerLoading(width: 200, height: 24),
          const SizedBox(height: 20),
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (_, __) => const ShimmerFacilityCard(),
            ),
          ),
        ],
      ),
    );
  }
}
