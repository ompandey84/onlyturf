import 'package:application/core/services/connectivity_service.dart';
import 'package:application/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

/// A full-screen overlay shown when there is no internet connection.
/// Automatically dismisses when connection is restored.
class ConnectivityWrapper extends StatelessWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, _) {
        return Stack(
          children: [child, if (!connectivity.isOnline) _NoInternetOverlay()],
        );
      },
    );
  }
}

class _NoInternetOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark
          ? Colors.black.withValues(alpha: 0.92)
          : Colors.white.withValues(alpha: 0.95),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.08),
                  ),
                  child: const Icon(
                    Icons.wifi_off,
                    size: 56,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'No Internet Connection',
                  style: GoogleFonts.oswald(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'Please check your Wi-Fi or mobile data\nconnection and try again.',
                  style: GoogleFonts.rajdhani(
                    fontSize: 14,
                    color: AppColors.textSec(context),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Lottie loader showing "waiting"
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Lottie.asset(
                    'assets/animations/loader.json',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  'Waiting for connection...',
                  style: GoogleFonts.rajdhani(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSec(context),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A slim animated banner that slides in from the top when offline.
/// Use this for screens where you want a non-blocking warning.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, _) {
        return AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          offset: connectivity.isOnline ? const Offset(0, -1) : Offset.zero,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: connectivity.isOnline ? 0.0 : 1.0,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade700, Colors.red.shade500],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.wifi_off,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No Internet Connection',
                    style: GoogleFonts.rajdhani(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
