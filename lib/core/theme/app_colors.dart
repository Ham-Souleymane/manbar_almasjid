import 'package:flutter/material.dart';

/// App color palette – Emerald / Cream / Gold
class AppColors {
  AppColors._();

  // ── Primary: Deep Emerald Green ──────────────────────────────
  static const Color emeraldDark = Color(0xFF064E3B);    // shade-900
  static const Color emerald = Color(0xFF065F46);        // primary
  static const Color emeraldMedium = Color(0xFF047857);  // shade-700
  static const Color emeraldLight = Color(0xFF059669);   // shade-600
  static const Color emeraldPale = Color(0xFFD1FAE5);    // shade-100

  // ── Accent: Gold ─────────────────────────────────────────────
  static const Color gold = Color(0xFFB7922E);
  static const Color goldLight = Color(0xFFD4A843);
  static const Color goldPale = Color(0xFFFEF3C7);

  // ── Background: Cream ────────────────────────────────────────
  static const Color cream = Color(0xFFFAF7F2);
  static const Color creamDark = Color(0xFFF0EBE1);
  static const Color white = Color(0xFFFFFFFF);

  // ── Neutral ──────────────────────────────────────────────────
  static const Color charcoal = Color(0xFF1C1C1E);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey100 = Color(0xFFF3F4F6);

  // ── Semantic ─────────────────────────────────────────────────
  static const Color error = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);

  // ── Surface/Card ─────────────────────────────────────────────
  static const Color surface = Color(0xFFFFFEFB);
  static const Color surfaceVariant = Color(0xFFF5F0E8);
  static const Color divider = Color(0xFFE5DDD0);
}
