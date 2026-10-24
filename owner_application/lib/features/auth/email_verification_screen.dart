import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:owner_application/features/dashboard/dashboard_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String password; // Kept to auto-login if needed

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with WidgetsBindingObserver {
  bool _isChecking = false;
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Listen for Auth State Changes (e.g. if user clicks link and app opens)
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      if (data.session != null) {
        _navigateToDashboard();
      }
    });

    // Initial check (give a few seconds for delayed server response if any)
    Future.delayed(const Duration(seconds: 2), _checkVerificationStatus);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app comes back to foreground (e.g. after user checked email), check status
    if (state == AppLifecycleState.resumed) {
      _checkVerificationStatus();
    }
  }

  Future<void> _checkVerificationStatus() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    try {
      // Try to sign in.
      // If email is confirmed, it will succeed.
      // If not, it will fail with 'Email not confirmed' error.
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: widget.email,
        password: widget.password,
      );

      if (response.session != null) {
        _navigateToDashboard();
      }
    } catch (e) {
      // Ignore login errors (likely "Email not confirmed")
      // Just stay on screen
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _navigateToDashboard() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mark_email_unread_outlined,
                size: 50,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Check Your Email',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'We have sent a verification link to:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.email,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            const Text(
              'Tap the link in the email to activate your account.\nOnce verified, click the button below.',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),

            const Spacer(),

            if (_isChecking)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _checkVerificationStatus,
                child: const Text('I have Verified via Email'),
              ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
