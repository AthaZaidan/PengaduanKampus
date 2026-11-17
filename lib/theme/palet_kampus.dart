import 'package:flutter/material.dart';

/// Palet dari AlhamSaragih, feature/pembaruan-ui (454065a).
/// Warna teks status digelapkan untuk keterbacaan pada latar terang.
class AppColors {
  AppColors._();

  // ── 5 Warna Pokok (Brand Identity) ───────────────────────────────────────
  static const Color softSage = Color(0xFFD0D4C5);
  static const Color sageGreen = Color(0xFF769E77);
  static const Color forestGreen = Color(0xFF406E49);
  static const Color deepForest = Color(0xFF0D261B);
  static const Color mutedTeal = Color(0xFF6D9492);

  // ── Surface & Background ─────────────────────────────────────────────────
  /// Scaffold background — 60% dominan, off-white kehijauan sangat lembut.
  static const Color background = Color(0xFFF6F8F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFEBEEE9);
  static const Color surfaceContainerLow = Color(0xFFF0F3EF);
  static const Color surfaceContainerHigh = Color(0xFFE0E5DE);

  // ── Borders & Dividers ───────────────────────────────────────────────────
  static const Color borderSubtle = Color(0xFFE3E8E4);
  static const Color borderMedium = Color(0xFFC4CEBD);
  static const Color divider = Color(0xFFE5EBE1);

  // ── Typography ───────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0D261B); // Deep Forest
  static const Color textSecondary = Color(0xFF3F5448);
  static const Color textMuted = Color(0xFF546B5B);
  static const Color textLight = Color(0xFFFFFFFF);

  // ── Semantic Status — Muted Tones ────────────────────────────────────────
  /// Menunggu / Dilaporkan / Baru / Perlu Verifikasi → Muted Amber
  static const Color statusMenunggu = Color(0xFF8A641E);
  static const Color statusMenungguBg = Color(0xFFFBF6EC);

  /// Terverifikasi → ringan hijau sage, serasi dengan brand
  static const Color statusDiverifikasi = Color(0xFF406E49);
  static const Color statusDiverifikasiBg = Color(0xFFEAF0EC);

  /// Ditugaskan / Dikerjakan → Muted Teal (Slate Teal)
  static const Color statusDitugaskan = Color(0xFF3F706D);
  static const Color statusDitugaskanBg = Color(0xFFEDF3F3);

  static const Color statusDiproses = Color(0xFF3F706D);
  static const Color statusDiprosesBg = Color(0xFFEDF3F3);

  /// Selesai / Tepat Waktu → Forest Green
  static const Color statusSelesai = Color(0xFF406E49);
  static const Color statusSelesaiBg = Color(0xFFEAF0EC);

  /// Ditolak / Lewat SLA / Prioritas Tinggi → Muted Terracotta
  static const Color statusDitolak = Color(0xFFB84A4A);
  static const Color statusDitolakBg = Color(0xFFFDF2F2);

  // ── Semantic Alerts ──────────────────────────────────────────────────────
  static const Color error = Color(0xFFB84A4A);
  static const Color success = Color(0xFF406E49);
  static const Color warning = statusMenunggu;
  static const Color info = statusDiproses;
}
