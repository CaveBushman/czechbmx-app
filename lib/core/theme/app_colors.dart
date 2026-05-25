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

  @override
  Color get background => const Color(0xFF080A0F); // Hlubší, prémiová temná
  @override
  Color get surface => const Color(0xFF111721);
  @override
  // Pro jemné oddělení sekcí
  Color get surfaceVariant => const Color(0xFF1A222F);
  @override
  Color get card => const Color(0xFF161E2C);

  @override
  Color get textPrimary => const Color(0xFFFFFFFF);
  @override
  Color get textSecondary => const Color(0xFF94A3B8);
  @override
  // Lightened from #64748B (2.9:1 on card) to #8498B5 (~4.2:1 on card, passes AA for large/bold text)
  Color get textMuted => const Color(0xFF8498B5);

  @override
  Color get divider => const Color(0xFF1A222F);
  @override
  // Velmi jemné ohraničení pro "skleněný" efekt
  Color get border => const Color(0xFF242F41);

  @override
  LinearGradient get cardOverlay => const LinearGradient(
        colors: [Colors.transparent, Color(0xEE080A0F)], // Tmavší přechod pro lepší čitelnost
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  @override
  Brightness get brightness => Brightness.dark;
}

// ── Light palette ─────────────────────────────────────────────────────────────

class LightPalette extends AppColorPalette {
  const LightPalette();

  @override
  Color get background => const Color(0xFFF4F6FB);
  @override
  Color get surface => const Color(0xFFFFFFFF);
  @override
  Color get surfaceVariant => const Color(0xFFEEF2F7);
  @override
  Color get card => const Color(0xFFFFFFFF);

  @override
  Color get textPrimary => const Color(0xFF0F172A);
  @override
  Color get textSecondary => const Color(0xFF475569);
  @override
  Color get textMuted => const Color(0xFF94A3B8);

  @override
  Color get divider => const Color(0xFFE2E8F0);
  @override
  Color get border => const Color(0xFFCBD5E1);

  @override
  LinearGradient get cardOverlay => const LinearGradient(
        colors: [Colors.transparent, Color(0xCC1A202E)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  @override
  Brightness get brightness => Brightness.light;
}

// ── BuildContext extension ────────────────────────────────────────────────────

extension BuildContextColors on BuildContext {
  AppColorPalette get colors {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark
        ? const DarkPalette()
        : const LightPalette();
  }
}

// ── Avatar color helper ───────────────────────────────────────────────────────

// Returns a deterministic, visually distinct color for an avatar placeholder
// based on any integer ID (rider UCI ID, etc.).
Color avatarColor(int id) {
  const palette = [
    Color(0xFFE84000), // orange (primary)
    Color(0xFF3B82F6), // blue
    Color(0xFF10B981), // emerald
    Color(0xFF8B5CF6), // violet
    Color(0xFFF59E0B), // amber
    Color(0xFFEC4899), // pink
    Color(0xFF06B6D4), // cyan
    Color(0xFF6366F1), // indigo
    Color(0xFF14B8A6), // teal
    Color(0xFFF97316), // deep orange
  ];
  return palette[id.abs() % palette.length];
}
