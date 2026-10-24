import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:lottie/lottie.dart';
import 'package:application/core/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:application/features/home/home_screen.dart';
import 'package:application/core/widgets/shimmer_loading.dart';
import 'package:application/features/profile/terms_service_screen.dart';
import 'package:application/features/profile/privacy_policy_screen.dart';
import 'package:application/core/utils/indian_cities.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  final bool showGuestOption;
  const LoginScreen({super.key, this.showGuestOption = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late TabController _tabController;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberDevice = false;
  bool _obscureConfirmPassword = true;
  bool _isInitializing = true;
  String? _selectedCity;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    // Simulate initial loading shimmer
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _isInitializing = false);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final mobile = _mobileController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedCity == null || _selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select City and Gender'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final city = _selectedCity!;
    final gender = _selectedGender!;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
          'mobile': mobile,
          'city': city,
          'gender': gender,
        },
      );

      if (response.user != null) {
        await supabase.from('profiles').upsert({
          'id': response.user!.id,
          'email': email,
          'full_name': name,
          'mobile': mobile,
          'city': city,
          'gender': gender,
        });
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.card(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Welcome to the Court! 🎉',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppColors.textMain(context),
              ),
            ),
            content: Text(
              'Your account has been created successfully.\n\nPlease sign in with your access key to enter.',
              style: GoogleFonts.montserrat(
                color: AppColors.textSec(context),
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _emailController.clear();
                  _passwordController.clear();
                  _nameController.clear();
                  _mobileController.clear();
                  _confirmPasswordController.clear();
                  setState(() {
                    _tabController.index = 0;
                  });
                },
                child: Text(
                  'GO TO LOGIN',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final supabase = Supabase.instance.client;

    setState(() => _isLoading = true);

    try {
      await supabase.auth.signInWithPassword(email: email, password: password);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        String errorMessage = e.message;
        if (e.message.toLowerCase().contains('invalid login credentials')) {
          errorMessage =
              'Incorrect access key or email not registered. Please sign up if you are a new member.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final emailController = TextEditingController();
    final otpController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool isLoading = false;
    int currentStep = 0; // 0: Email, 1: OTP, 2: New Password
    bool obscureNew = true;
    bool obscureConfirm = true;
    String errorMessage = '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.1),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    currentStep == 0
                        ? Icons.mail
                        : currentStep == 1
                        ? Icons.domain_verification
                        : Icons.lock_reset,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  currentStep == 0
                      ? 'Reset Access Key'
                      : currentStep == 1
                      ? 'Verify Email'
                      : 'New Access Key',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: AppColors.textMain(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currentStep == 0
                      ? 'Enter your membership email and we\'ll send\nyou an OTP to verify your identity.'
                      : currentStep == 1
                      ? 'Enter the 6-digit OTP sent to\n${emailController.text.trim()}'
                      : 'Create a new secure access key for\nyour account.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    color: AppColors.textSec(context),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                if (currentStep == 0) ...[
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.montserrat(
                      color: AppColors.textMain(context),
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'member@example.com',
                      hintStyle: TextStyle(color: AppColors.textSec(context)),
                      prefixIcon: const Icon(
                        Icons.mail,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ] else if (currentStep == 1) ...[
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      color: AppColors.textMain(context),
                      fontSize: 24,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      hintText: '000000',
                      hintStyle: TextStyle(
                        color: AppColors.textSec(
                          context,
                        ).withValues(alpha: 0.3),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  TextField(
                    controller: newPasswordController,
                    obscureText: obscureNew,
                    style: GoogleFonts.montserrat(
                      color: AppColors.textMain(context),
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'New Access Key',
                      hintStyle: TextStyle(color: AppColors.textSec(context)),
                      prefixIcon: const Icon(
                        Icons.lock,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      suffixIcon: GestureDetector(
                        onTap: () =>
                            setModalState(() => obscureNew = !obscureNew),
                        child: Icon(
                          obscureNew
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.textSec(context),
                          size: 20,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirm,
                    style: GoogleFonts.montserrat(
                      color: AppColors.textMain(context),
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Confirm Access Key',
                      hintStyle: TextStyle(color: AppColors.textSec(context)),
                      prefixIcon: const Icon(
                        Icons.lock,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      suffixIcon: GestureDetector(
                        onTap: () => setModalState(
                          () => obscureConfirm = !obscureConfirm,
                        ),
                        child: Icon(
                          obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.textSec(context),
                          size: 20,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],

                if (errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage,
                            style: GoogleFonts.montserrat(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (currentStep == 0) {
                            // Step 1: Send OTP
                            final email = emailController.text.trim();
                            if (email.isEmpty || !email.contains('@')) {
                              setModalState(
                                () => errorMessage =
                                    'Please enter a valid email address.',
                              );
                              return;
                            }
                            setModalState(() {
                              isLoading = true;
                              errorMessage = '';
                            });
                            try {
                              // Send OTP for password recovery
                              await Supabase.instance.client.auth
                                  .resetPasswordForEmail(email);
                              setModalState(() {
                                currentStep = 1;
                                isLoading = false;
                              });
                            } catch (e) {
                              setModalState(() {
                                isLoading = false;
                                errorMessage = e is AuthException
                                    ? e.message
                                    : 'Error sending OTP: $e';
                              });
                            }
                          } else if (currentStep == 1) {
                            // Step 2: Verify OTP
                            final email = emailController.text.trim();
                            final token = otpController.text.trim();
                            if (token.isEmpty || token.length < 6) {
                              setModalState(
                                () => errorMessage =
                                    'Please enter the 6-digit OTP.',
                              );
                              return;
                            }
                            setModalState(() {
                              isLoading = true;
                              errorMessage = '';
                            });
                            try {
                              await Supabase.instance.client.auth.verifyOTP(
                                type: OtpType.recovery,
                                token: token,
                                email: email,
                              );
                              setModalState(() {
                                currentStep = 2; // Move to password update
                                isLoading = false;
                              });
                            } catch (e) {
                              setModalState(() {
                                isLoading = false;
                                errorMessage = e is AuthException
                                    ? e.message
                                    : 'Invalid OTP: $e';
                              });
                            }
                          } else if (currentStep == 2) {
                            // Step 3: Set New Password
                            final newPw = newPasswordController.text.trim();
                            final confirmPw = confirmPasswordController.text
                                .trim();

                            if (newPw.length < 6) {
                              setModalState(
                                () => errorMessage =
                                    'Password must be at least 6 characters.',
                              );
                              return;
                            }
                            if (newPw != confirmPw) {
                              setModalState(
                                () => errorMessage = 'Passwords do not match!',
                              );
                              return;
                            }
                            setModalState(() {
                              isLoading = true;
                              errorMessage = '';
                            });
                            try {
                              await Supabase.instance.client.auth.updateUser(
                                UserAttributes(password: newPw),
                              );
                              // User is logged in after recovery, so log them out to force re-login
                              await Supabase.instance.client.auth.signOut();

                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Access Key updated! Please sign in with your new key.',
                                    ),
                                    backgroundColor: AppColors.statusConfirmed,
                                    duration: Duration(seconds: 4),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } catch (e) {
                              setModalState(() {
                                isLoading = false;
                                errorMessage = e is AuthException
                                    ? e.message
                                    : 'Failed to update password: $e';
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withValues(
                      alpha: 0.6,
                    ),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: Lottie.asset(
                            'assets/animations/loader.json',
                            fit: BoxFit.contain,
                          ),
                        )
                      : Text(
                          currentStep == 0
                              ? 'SEND VERIFICATION OTP'
                              : currentStep == 1
                              ? 'VERIFY OTP'
                              : 'CONFIRM NEW ACCESS KEY',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    // Logic to step back if needed, or close
                    if (currentStep > 0 && currentStep < 2) {
                      setModalState(() => currentStep--);
                    } else {
                      Navigator.pop(ctx);
                    }
                  },
                  child: Text(
                    currentStep > 0 && currentStep < 2 ? 'Back' : 'Cancel',
                    style: TextStyle(
                      color: AppColors.textSec(context),
                      fontSize: 14,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isInitializing)
                          ShimmerEffect(
                            child: Column(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Container(
                                  width: 150,
                                  height: 20,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: 250,
                                  height: 40,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 36),
                                Container(
                                  width: double.infinity,
                                  height: 400,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          )
                        else ...[
                          // ── Crown Icon ──
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.white.withValues(alpha: 0.5),
                              ),
                              child: const Icon(
                                Icons.diamond,
                                size: 36,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── "Authentication" Label ──
                          Text(
                            'AUTHENTICATION',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 4,
                              color: AppColors.textSec(context),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ── "Welcome to the Court" ──
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryDark,
                              ],
                            ).createShader(bounds),
                            child: Text(
                              'Welcome to\nthe Court',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.15,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ── Tagline ──
                          Text(
                            '"Where legacy meets luxury."',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: AppColors.textSec(context),
                            ),
                          ),

                          const SizedBox(height: 36),

                          // ── Form Card ──
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.white.withValues(alpha: 0.2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Glassmorphic Card Background and Shadow applied below in outer Container, so we can focus on content

                                // ── Tab Bar (Email vs Phone) ──
                                Container(
                                  height: 44,
                                  margin: const EdgeInsets.only(bottom: 24),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.black.withValues(alpha: 0.2)
                                        : Colors.white.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.divider(context),
                                    ),
                                  ),
                                  child: TabBar(
                                    controller: _tabController,
                                    indicatorSize: TabBarIndicatorSize.tab,
                                    indicator: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    labelColor: Colors.white,
                                    labelStyle: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                    unselectedLabelColor: AppColors.textSec(
                                      context,
                                    ),
                                    dividerColor: Colors.transparent,
                                    onTap: (index) {
                                      setState(() {});
                                    },
                                    tabs: const [
                                      Tab(text: 'SIGN IN'),
                                      Tab(text: 'REGISTER'),
                                    ],
                                  ),
                                ),

                                // Form Input Logic based on Tab
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 300),
                                  child: _tabController.index == 0
                                      ? _buildEmailForm()
                                      : _buildSignupForm(),
                                ),
                              ],
                            ),
                          ),

                          // End Form Card
                          const SizedBox(height: 28),

                          // ── Terms ──
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                color: AppColors.textSec(context),
                              ),
                              children: [
                                const TextSpan(
                                  text:
                                      'By accessing The Court, you agree to our\n',
                                ),
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: const TextStyle(
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.primary,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const TermsServiceScreen(),
                                        ),
                                      );
                                    },
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: const TextStyle(
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.primary,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const PrivacyPolicyScreen(),
                                        ),
                                      );
                                    },
                                ),
                                const TextSpan(text: '.'),
                              ],
                            ),
                          ),

                          SizedBox(
                            height: max(
                              48.0,
                              MediaQuery.of(context).viewInsets.bottom + 24.0,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Column(
      children: [
        // Gold accent line at top
        Container(
          height: 1.5,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppColors.primary,
                Colors.transparent,
              ],
            ),
          ),
        ),

        // ── Email Field ──
        _buildUnderlineField(
          controller: _emailController,
          label: 'MEMBERSHIP ID / EMAIL',
          hint: 'Enter your credentials',
          icon: Icons.person,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            if (!v.contains('@')) return 'Enter valid email';
            return null;
          },
        ),

        const SizedBox(height: 20),

        // ── Password Field ──
        _buildUnderlineField(
          controller: _passwordController,
          label: 'ACCESS KEY',
          hint: '••••••••',
          icon: Icons.lock,
          obscureText: _obscurePassword,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            if (v.length < 6) return 'Min 6 characters';
            return null;
          },
          suffix: GestureDetector(
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            child: Icon(
              _obscurePassword
                  ? Icons.visibility_off
                  : Icons.visibility,
              color: AppColors.textSec(context),
              size: 20,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Remember + Forgot ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: Checkbox(
                    value: _rememberDevice,
                    onChanged: (v) =>
                        setState(() => _rememberDevice = v ?? false),
                    activeColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Remember device',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: AppColors.textSec(context),
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: _handleForgotPassword,
              child: Text(
                'Forgot Key?',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // ── Grant Access Button ──
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleAuth,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: Lottie.asset(
                      'assets/animations/loader.json',
                      fit: BoxFit.contain,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'GRANT ACCESS',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
          ),
        ),

        if (widget.showGuestOption) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR CONTINUE AS',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: AppColors.textSec(context).withValues(alpha: 0.5),
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.center,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('is_first_launch', false);
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'GUEST',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUnderlineField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffix,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: AppColors.textSec(context),
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            color: AppColors.textMain(context),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.montserrat(
              color: AppColors.textSec(context).withValues(alpha: 0.5),
              fontSize: 14,
            ),
            suffixIcon: suffix != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: suffix,
                  )
                : Icon(icon, color: AppColors.textSec(context), size: 20),
            filled: false,
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.divider(context)),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.divider(context)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            errorStyle: const TextStyle(fontSize: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupForm() {
    return Column(
      children: [
        // Gold accent line
        Container(
          height: 1.5,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppColors.primary,
                Colors.transparent,
              ],
            ),
          ),
        ),

        // ── Full Name ──
        _buildUnderlineField(
          controller: _nameController,
          label: 'FULL NAME',
          hint: 'Enter your full name',
          icon: Icons.person,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            return null;
          },
        ),
        const SizedBox(height: 20),

        // ── Phone ──
        _buildUnderlineField(
          controller: _mobileController,
          label: 'PHONE NUMBER',
          hint: 'Enter mobile number',
          icon: Icons.phone_iphone,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            if (v.length != 10) {
              return 'Enter valid 10-digit number';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // ── City ──
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'YOUR CITY',
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppColors.textSec(context),
              ),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: _selectedCity,
              hint: Text(
                'Indore',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: AppColors.textSec(context).withValues(alpha: 0.5),
                ),
              ),
              validator: (value) => value == null ? 'Required' : null,
              items: indianCities
                  .map(
                    (city) => DropdownMenuItem(
                      value: city,
                      child: Text(
                        city,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          color: AppColors.textMain(context),
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedCity = val!),
              decoration: InputDecoration(
                suffixIcon: Icon(
                  Icons.location_city,
                  color: AppColors.textSec(context),
                  size: 20,
                ),
                filled: false,
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.divider(context)),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.divider(context)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              dropdownColor: AppColors.card(context),
              isExpanded: true,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Gender ──
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GENDER',
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppColors.textSec(context),
              ),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: _selectedGender,
              hint: Text(
                'Select Gender',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: AppColors.textSec(context).withValues(alpha: 0.5),
                ),
              ),
              validator: (value) => value == null ? 'Required' : null,
              items: ['Male', 'Female', 'Other']
                  .map(
                    (gender) => DropdownMenuItem(
                      value: gender,
                      child: Text(
                        gender,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          color: AppColors.textMain(context),
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedGender = val!),
              decoration: InputDecoration(
                suffixIcon: Icon(
                  Icons.person_pin_circle,
                  color: AppColors.textSec(context),
                  size: 20,
                ),
                filled: false,
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.divider(context)),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.divider(context)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              dropdownColor: AppColors.card(context),
              isExpanded: true,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Email ──
        _buildUnderlineField(
          controller: _emailController,
          label: 'EMAIL ADDRESS',
          hint: 'Enter your email',
          icon: Icons.mail,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            if (!v.contains('@')) {
              return 'Enter valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // ── Password ──
        _buildUnderlineField(
          controller: _passwordController,
          label: 'ACCESS KEY',
          hint: '••••••••',
          icon: Icons.lock,
          obscureText: _obscurePassword,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            if (v.length < 6) return 'Min 6 characters';
            return null;
          },
          suffix: GestureDetector(
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            child: Icon(
              _obscurePassword
                  ? Icons.visibility_off
                  : Icons.visibility,
              color: AppColors.textSec(context),
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── Confirm Password ──
        _buildUnderlineField(
          controller: _confirmPasswordController,
          label: 'CONFIRM ACCESS KEY',
          hint: '••••••••',
          icon: Icons.lock,
          obscureText: _obscureConfirmPassword,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            if (v != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
          suffix: GestureDetector(
            onTap: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            ),
            child: Icon(
              _obscureConfirmPassword
                  ? Icons.visibility_off
                  : Icons.visibility,
              color: AppColors.textSec(context),
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 28),

        // ── Register Button ──
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSignup,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: Lottie.asset(
                      'assets/animations/loader.json',
                      fit: BoxFit.contain,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'REQUEST MEMBERSHIP',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
          ),
        ),

        if (widget.showGuestOption) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR CONTINUE AS',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: AppColors.textSec(context).withValues(alpha: 0.5),
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.center,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('is_first_launch', false);
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'GUEST',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
