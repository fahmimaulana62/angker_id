import 'package:flutter/material.dart';

/// Palet warna Angker.id.
/// Empat warna dasar diambil dari Color Hunt (#F9B2D7 #CFECF3 #DAF9DE #F6FFDC),
/// warna turunan diambil dari design system Stitch "Pastel Playful Retail".
class AppColors {
  AppColors._();

  // Palet dasar (Color Hunt)
  static const Color pink = Color(0xFFF9B2D7);
  static const Color blue = Color(0xFFCFECF3);
  static const Color mint = Color(0xFFDAF9DE);
  static const Color cream = Color(0xFFF6FFDC);

  // Aksen kontras tinggi
  static const Color primary = Color(0xFF993D71);
  static const Color pinkDeep = Color(0xFFE37AB2);
  static const Color blueDeep = Color(0xFF6FAFC2);
  static const Color mintDeep = Color(0xFF5DAA6E);
  static const Color onMint = Color(0xFF2F5B3A);
  static const Color onBlue = Color(0xFF3B5A61);

  // Permukaan
  static const Color background = Color(0xFFFFF7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color pinkTint = Color(0xFFFFEFFB);
  static const Color pinkSoft = Color(0xFFFBE0F8);
  static const Color creamSoft = Color(0xFFFAFDE8);

  // Teks
  static const Color plum = Color(0xFF3D2C3E);
  static const Color plumMuted = Color(0xFF8A7A8C);
  static const Color outline = Color(0xFFD8C0C9);

  // Status
  static const Color danger = Color(0xFFBA1A1A);
  static const Color dangerSoft = Color(0xFFFFDAD6);
  static const Color warning = Color(0xFFB7791F);
  static const Color warningSoft = Color(0xFFFFF1D6);

  /// Warna kartu pastel yang dipakai bergiliran (kategori, spesifikasi, avatar).
  static const List<Color> pastelCycle = [pinkTint, blue, mint, cream];

  /// Bayangan lembut bernuansa pink (bukan hitam) sesuai design system.
  static final List<BoxShadow> softShadow = [
    BoxShadow(
      color: pinkDeep.withValues(alpha: 0.12),
      blurRadius: 18,
      offset: const Offset(0, 6),
      spreadRadius: -2,
    ),
  ];

  static final List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: pinkDeep.withValues(alpha: 0.35),
      blurRadius: 18,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
  ];
}
