import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFD45C11);
  static const Color primaryDark = Color(0xFFB04A0B);

  static const Color backgroundLight = Color(0xFFF8F7F6);
  static const Color backgroundDark = Color(0xFF121212);

  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E1E1E);

  static const Color textMainLight = Color(0xFF111418);
  static const Color textMainDark = Color(0xFFF0F2F4);

  static const Color textSecLight = Color(0xFF617589);
  static const Color textSecDark = Color(0xFF9CA3AF);

  static const Color surfaceDark = Color(0xFF1A2632);

  static const Color dividerLight = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF2C2C2E);

  static const Color statusConfirmed = Color(0xFF34C759);
  static const Color statusCancelled = Color(0xFFFF3B30);
  static const Color statusPending = Color(0xFFFF9500);
  static const Color statusCompleted = Color(0xFF8E8E93);

  // ── Context-aware helpers ──────────────────────────────────
  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color card(BuildContext context) =>
      _isDark(context) ? cardDark : cardLight;

  static Color background(BuildContext context) =>
      _isDark(context) ? backgroundDark : backgroundLight;

  static Color textMain(BuildContext context) =>
      _isDark(context) ? textMainDark : textMainLight;

  static Color textSec(BuildContext context) =>
      _isDark(context) ? textSecDark : textSecLight;

  static Color divider(BuildContext context) =>
      _isDark(context) ? dividerDark : dividerLight;

  static Color iconDefault(BuildContext context) =>
      _isDark(context) ? const Color(0xFFB0B0B0) : const Color(0xFF6B6B6B);

  /// Subtle tinted background for icon containers, menu items, etc.
  static Color subtleBg(BuildContext context) =>
      _isDark(context) ? const Color(0xFF2A2A2A) : const Color(0xFFF3F3F3);
}
