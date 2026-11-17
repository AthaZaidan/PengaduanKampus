import 'package:flutter/material.dart';

import 'tema_kampus.dart';

/// API warna dari main dipertahankan untuk komponen yang digabungkan.
/// Palet mengikuti biru tua formal yang dipilih untuk hasil merge ini.
class AppColors {
  AppColors._();

  // Nama lama dipertahankan agar komponen main tetap kompatibel.
  static const softSage = Color(0xFFE7EEF5);
  static const sageGreen = Color(0xFF526B80);
  static const forestGreen = TemaKampus.biru;
  static const deepForest = TemaKampus.tinta;
  static const mutedTeal = Color(0xFF267583);

  static const background = TemaKampus.latar;
  static const surface = Colors.white;
  static const surfaceContainer = Color(0xFFEBF0F5);
  static const surfaceContainerLow = Color(0xFFF0F4F8);
  static const surfaceContainerHigh = Color(0xFFE2EAF2);
  static const borderSubtle = TemaKampus.garis;
  static const borderMedium = Color(0xFF8B99AA);
  static const divider = TemaKampus.garis;

  static const textPrimary = TemaKampus.tinta;
  static const textSecondary = Color(0xFF5B6B7D);
  static const textMuted = Color(0xFF64748B);
  static const textLight = Colors.white;

  static const statusMenunggu = Color(0xFF94620E);
  static const statusMenungguBg = Color(0xFFFBF6EC);
  static const statusDiverifikasi = Color(0xFF66588A);
  static const statusDiverifikasiBg = Color(0xFFF1EEF6);
  static const statusDitugaskan = Color(0xFF267583);
  static const statusDitugaskanBg = Color(0xFFEDF4F5);
  static const statusDiproses = Color(0xFF315F96);
  static const statusDiprosesBg = Color(0xFFEDF2F8);
  static const statusSelesai = Color(0xFF257054);
  static const statusSelesaiBg = Color(0xFFEDF5F1);
  static const statusDitolak = Color(0xFFAC3838);
  static const statusDitolakBg = Color(0xFFFBEEEE);

  static const error = statusDitolak;
  static const success = statusSelesai;
  static const warning = statusMenunggu;
  static const info = statusDiproses;
}

/// Kedua nama tema memakai satu konfigurasi, sehingga tidak ada dua tema aktif.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => TemaKampus.bangun();
}
