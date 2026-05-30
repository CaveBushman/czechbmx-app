// Barevný systém aplikace.
//
// AppColors       — statické brand barvy (primary #E84000 = BMX oranžová)
// AppColorPalette — abstraktní paleta; DarkPalette / LightPalette jsou implementace
// context.colors  — extension pro přístup k paletě z BuildContext kdekoliv v widgetech
// avatarColor()   — deterministicky generuje barvu avatara z UCI ID jezdce
import 'package:flutter/material.dart';

// ── Brand colors (stejné v obou tématech) ────────────────────────────────────

class AppColors {
  AppColors._();

  // ── Primární brand barva — při změně stačí upravit tyto tři řádky ──
  static const Color primary      = Color(0xFF0EA5E9); // sky-500 — brand modrá z loga
  static const Color primaryLight = Color(0xFF38BDF8); // sky-400
  static const Color primaryDark  = Color(0xFF0284C7); // sky-600
  // CSS hex string pro flutter_widget_from_html (musí odpovídat primary výše)
  static const String primaryHex = '#0EA5E9';

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
// Odpovídá dark tématu czechbmx.cz: hluboká námořní slate paleta (slate-950/900/800).

class DarkPalette extends AppColorPalette {
  const DarkPalette();

  @override
  Color get background => const Color(0xFF0B1120); // slate-950 s indigo nádechem
  @override
  Color get surface => const Color(0xFF111827);    // slate-900 (bg-slate-900 na webu)
  @override
  Color get surfaceVariant => const Color(0xFF1E293B); // slate-800
  @override
  Color get card => const Color(0xFF1E293B);           // slate-800

  @override
  Color get textPrimary => const Color(0xFFF8FAFC);    // slate-50
  @override
  Color get textSecondary => const Color(0xFF94A3B8);  // slate-400
  @override
  Color get textMuted => const Color(0xFF64748B);      // slate-500

  @override
  Color get divider => const Color(0xFF1E293B);        // slate-800
  @override
  Color get border => const Color(0xFF334155);         // slate-700 (web používá #334155)

  @override
  LinearGradient get cardOverlay => const LinearGradient(
        colors: [Colors.transparent, Color(0xEE0B1120)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  @override
  Brightness get brightness => Brightness.dark;
}

// ── Light palette ─────────────────────────────────────────────────────────────
// Odpovídá light tématu czechbmx.cz: slate-50 pozadí s jemným indigo nádechem.

class LightPalette extends AppColorPalette {
  const LightPalette();

  @override
  Color get background => const Color(0xFFF0F4FF); // slate-50 s indigo tónem (jako #eef2ff na webu)
  @override
  Color get surface => const Color(0xFFFFFFFF);
  @override
  Color get surfaceVariant => const Color(0xFFF1F5F9); // slate-100
  @override
  Color get card => const Color(0xFFFFFFFF);

  @override
  Color get textPrimary => const Color(0xFF0F172A);    // slate-950
  @override
  Color get textSecondary => const Color(0xFF475569);  // slate-600
  @override
  Color get textMuted => const Color(0xFF94A3B8);      // slate-400

  @override
  Color get divider => const Color(0xFFE2E8F0);        // slate-200
  @override
  Color get border => const Color(0xFFCBD5E1);         // slate-300

  @override
  LinearGradient get cardOverlay => const LinearGradient(
        colors: [Colors.transparent, Color(0xCC0F172A)],
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
    Color(0xFF0EA5E9), // sky blue (primary)
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
