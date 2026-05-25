import 'package:flutter/material.dart';

// ── Brand colors (stejné v obou tématech) ────────────────────────────────────

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFE84000);
  static const Color primaryLight = Color(0xFFFF6B35);
  static const Color primaryDark = Color(0xFFB33000);

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ── Palette interface ─────────────────────────────────────────────────────────

abstract class AppColorPalette {
  const AppColorPalette();

  Color get background;
  Color get surface;
  Color get surfaceVariant;
  Color get card;

  Color get textPrimary;
  Color get textSecondary;
  Color get textMuted;

  Color get divider;
  Color get border;

  LinearGradient get cardOverlay;
  Brightness get brightness;
}

// ── Dark palette ──────────────────────────────────────────────────────────────

class DarkPalette extends AppColorPalette {
  const DarkPalette();

  @override Color get background => const Color(0xFF0E1219);
  @override Color get surface => const Color(0xFF1A2030);
  @override Color get surfaceVariant => const Color(0xFF1E2535);
  @override Color get card => const Color(0xFF222B3D);

  @override Color get textPrimary => const Color(0xFFFFFFFF);
  @override Color get textSecondary => const Color(0xFF94A3B8);
  @override Color get textMuted => const Color(0xFF64748B);

  @override Color get divider => const Color(0xFF2D3748);
  @override Color get border => const Color(0xFF2D3748);

  @override LinearGradient get cardOverlay => const LinearGradient(
    colors: [Colors.transparent, Color(0xCC0E1219)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override Brightness get brightness => Brightness.dark;
}

// ── Light palette ─────────────────────────────────────────────────────────────

class LightPalette extends AppColorPalette {
  const LightPalette();

  @override Color get background => const Color(0xFFF4F6FB);
  @override Color get surface => const Color(0xFFFFFFFF);
  @override Color get surfaceVariant => const Color(0xFFEEF2F7);
  @override Color get card => const Color(0xFFFFFFFF);

  @override Color get textPrimary => const Color(0xFF0F172A);
  @override Color get textSecondary => const Color(0xFF475569);
  @override Color get textMuted => const Color(0xFF94A3B8);

  @override Color get divider => const Color(0xFFE2E8F0);
  @override Color get border => const Color(0xFFCBD5E1);

  @override LinearGradient get cardOverlay => const LinearGradient(
    colors: [Colors.transparent, Color(0xCC1A202E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override Brightness get brightness => Brightness.light;
}

// ── BuildContext extension ────────────────────────────────────────────────────

extension BuildContextColors on BuildContext {
  AppColorPalette get colors {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark ? const DarkPalette() : const LightPalette();
  }
}
