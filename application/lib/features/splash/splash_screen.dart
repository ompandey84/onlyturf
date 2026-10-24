import 'package:application/features/home/home_screen.dart';
import 'package:application/features/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleInAnimation;
  late Animation<double> _sweepAnimation;
  late Animation<double> _scaleOutAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // The whole sequence takes 2.5 seconds
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    // Phase 1: Elastic Pop-In (0.0 to 0.3)
    _scaleInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
      ),
    );

    // Phase 2: The Metallic Light Sweep (0.3 to 0.7) passes across the logo
    _sweepAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeInOutSine),
      ),
    );

    // Phase 3: Dramatic Scale Out / Zoom In (0.7 to 1.0)
    _scaleOutAnimation = Tween<double>(begin: 1.0, end: 30.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeInExpo),
      ),
    );

    // Fade out as it zooms out
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start the animation and listen for completion
    _controller.forward().then((_) async {
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;
        final currentUser = Supabase.instance.client.auth.currentUser;

        final Widget nextScreen;
        if (currentUser != null) {
          nextScreen = const HomeScreen(); // Logged in
        } else if (!isFirstLaunch) {
          nextScreen = const HomeScreen(); // Returning guest
        } else {
          nextScreen = const LoginScreen(showGuestOption: true); // New user
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  nextScreen,
              transitionDuration: const Duration(milliseconds: 600),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.white, // Match native launch_background.xml for seamless entry
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Apply scale-out, scale-in, and fading
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Transform.scale(
                scale: _scaleInAnimation.value * _scaleOutAnimation.value,
                child: ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (Rect bounds) {
                    // Create a moving gradient that acts as a "light sweep"
                    return LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.8), // The bright flare
                        Colors.transparent,
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
                      // Move the stops across the gradient based on _sweepAnimation
                      transform: GradientRotation(_sweepAnimation.value * 3.14),
                    ).createShader(bounds);
                  },
                  child: Image.asset(
                    'assets/logo_transparent.png', // Transparent logo so ShaderMask only hits the shield
                    width: 280,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
