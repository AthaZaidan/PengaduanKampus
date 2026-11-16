import 'package:flutter/material.dart';

/// Identitas visual dan palet warna utama Pengaduan Kampus.
///
/// Proporsi 60-30-10:
///   60%  → Scaffold background #F6F8F6 (off-white kehijauan)
///   30%  → Forest Green #406E49 (AppBar, tombol utama, indikator aktif)
///   10%  → Sage Green #769E77 (aksen sekunder)
///
/// Palet 5 Warna Pokok:
///   #D0D4C5 — Soft Sage   : highlight permukaan / pill navigasi aktif
///   #769E77 — Sage Green  : aksen interaktif sekunder
///   #406E49 — Forest Green: primary brand, tombol utama, elemen aktif
///   #0D261B — Deep Forest : teks utama, dark surface, penekanan tinggi
///   #6D9492 — Muted Teal  : aksen pelengkap, Dikerjakan/Ditugaskan
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
  static const Color textMuted = Color(0xFF7B9082);
  static const Color textLight = Color(0xFFFFFFFF);

  // ── Semantic Status — Muted Tones ────────────────────────────────────────
  /// Menunggu / Dilaporkan / Baru / Perlu Verifikasi → Muted Amber
  static const Color statusMenunggu = Color(0xFFB58938);
  static const Color statusMenungguBg = Color(0xFFFBF6EC);

  /// Terverifikasi → ringan hijau sage, serasi dengan brand
  static const Color statusDiverifikasi = Color(0xFF406E49);
  static const Color statusDiverifikasiBg = Color(0xFFEAF0EC);

  /// Ditugaskan / Dikerjakan → Muted Teal (Slate Teal)
  static const Color statusDitugaskan = Color(0xFF6D9492);
  static const Color statusDitugaskanBg = Color(0xFFEDF3F3);

  static const Color statusDiproses = Color(0xFF6D9492);
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
  static const Color warning = Color(0xFFB58938);
  static const Color info = Color(0xFF6D9492);
}

/// Konfigurasi Tema Terpusat (Material 3).
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: AppColors.forestGreen,
      onPrimary: Colors.white,
      primaryContainer: AppColors.softSage,
      onPrimaryContainer: AppColors.deepForest,
      secondary: AppColors.sageGreen,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFE2ECDC),
      onSecondaryContainer: AppColors.deepForest,
      tertiary: AppColors.mutedTeal,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFDFECEB),
      onTertiaryContainer: AppColors.deepForest,
      surface: AppColors.surface,
      onSurface: AppColors.deepForest,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: AppColors.surfaceContainerLow,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceContainerHigh,
      surfaceContainerHighest: AppColors.softSage,
      outline: AppColors.borderMedium,
      outlineVariant: AppColors.borderSubtle,
      error: AppColors.error,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,

      // App Bar
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.forestGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.borderMedium,
          disabledForegroundColor: Colors.white70,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // Filled Button
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.forestGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.forestGreen,
          side: const BorderSide(color: AppColors.sageGreen, width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.forestGreen,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13.5),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.forestGreen,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.8),
        ),
      ),

      // Navigation Bar
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.softSage.withValues(alpha: 0.65),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.forestGreen, size: 24);
          }
          return const IconThemeData(color: AppColors.textMuted, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.forestGreen,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          );
        }),
      ),

      // FAB
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        elevation: 3,
        focusElevation: 4,
        hoverElevation: 4,
        highlightElevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(
          color: AppColors.deepForest,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.4,
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainerLow,
        disabledColor: AppColors.borderSubtle,
        selectedColor: AppColors.softSage,
        secondarySelectedColor: AppColors.sageGreen,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        labelStyle: const TextStyle(
          fontSize: 12,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.borderSubtle, width: 0.8),
        ),
      ),

      // Tab Bar
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13.5,
        ),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.deepForest,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
