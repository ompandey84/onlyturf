import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:application/core/theme/app_colors.dart';

/// A reusable Lottie animation loader widget.
/// Displays the cricket bat & ball bouncing animation.
///
/// Use [LottieLoader()] for a centered loader overlay.
/// Use [LottieLoader.inline()] for a small inline loader (e.g. inside buttons).
class LottieLoader extends StatelessWidget {
  final double size;
  final bool showBackground;
  final String? message;

  /// Full-page centered loader with optional background overlay.
  const LottieLoader({
    super.key,
    this.size = 120,
    this.showBackground = false,
    this.message,
  });

  /// Small inline loader for buttons or compact spaces.
  const LottieLoader.inline({
    super.key,
    this.size = 40,
    this.showBackground = false,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final loader = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Lottie.asset(
            'assets/animations/loader.json',
            fit: BoxFit.contain,
            repeat: true,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 12),
          Text(
            message!,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSec(context),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (showBackground) {
      return Container(
        color: AppColors.background(context),
        child: Center(child: loader),
      );
    }

    return Center(child: loader);
  }
}
