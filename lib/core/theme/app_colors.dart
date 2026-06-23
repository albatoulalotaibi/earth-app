import 'package:flutter/material.dart';

/// Centralised color palette for the Erth app.
///
/// Every color used anywhere in the app should be defined here so that
/// the design stays consistent and future theming / dark-mode is easy.
class AppColors {
  AppColors._();

  // ── Primary brand colours ──────────────────────────────────────────
  static const Color primaryBlue = Color(0xFF27548A);
  static const Color primaryBlueDark = Color(0xFF163A5A);

  // ── Greens (gradient & intro) ──────────────────────────────────────
  static const Color greenDark = Color(0xFF1D3027);
  static const Color greenMid = Color(0xFF446856);
  static const Color greenLight = Color(0xFF628A76);
  static const Color greenMuted = Color(0xFF7A9F8C);

  // ── Backgrounds ────────────────────────────────────────────────────
  static const Color scaffoldBackground = Color(0xFFEBEBEB);
  static const Color cardBackground = Colors.white;
  static const Color inputBackground = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color.fromARGB(255, 222, 220, 220);

  // ── Text ───────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF555555);
  static const Color textHint = Color(0xFF999999);
  static const Color textOnPrimary = Colors.white;

  // ── Misc ───────────────────────────────────────────────────────────
  static const Color divider = Color(0xFFE0E0E0);
  static const Color error = Color(0xFFD32F2F);

  // ── Gradients ──────────────────────────────────────────────────────
  static const LinearGradient appBarGradient = LinearGradient(
    begin: Alignment(-0.1, -0.5),
    end: Alignment(1.0, 0.5),
    colors: [greenDark, greenLight, greenMid],
    stops: [0.0, 0.8, 1.0],
  );

  static const LinearGradient introGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [greenDark, greenMid, greenLight],
  );

  static const LinearGradient authHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [greenDark, greenMid, greenLight],
  );
}
