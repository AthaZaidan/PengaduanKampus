import 'package:flutter/material.dart';

import 'palet_kampus.dart';

/// Identitas layanan kampus dipakai bersama oleh seluruh peran.
class TemaKampus {
  static const utama = AppColors.forestGreen;
  static const tinta = AppColors.deepForest;
  static const latar = AppColors.background;
  static const garis = AppColors.borderSubtle;
  static const aksen = AppColors.softSage;

  static ThemeData bangun() {
    final scheme = ColorScheme.fromSeed(seedColor: utama).copyWith(
      primary: utama,
      onPrimary: Colors.white,
      secondary: AppColors.sageGreen,
      onSecondary: AppColors.deepForest,
      primaryContainer: AppColors.softSage,
      onPrimaryContainer: AppColors.deepForest,
      secondaryContainer: AppColors.surfaceContainerHigh,
      onSecondaryContainer: AppColors.deepForest,
      tertiary: AppColors.mutedTeal,
      surface: Colors.white,
      onSurface: tinta,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.borderMedium,
      outlineVariant: garis,
      error: AppColors.error,
    );
    final bentuk = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    );
    final dasar = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Roboto',
    );
    return dasar.copyWith(
      scaffoldBackgroundColor: latar,
      textTheme: dasar.textTheme
          .apply(bodyColor: tinta, displayColor: tinta)
          .copyWith(
            headlineSmall: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 24,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: tinta,
            ),
            titleLarge: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 20,
              height: 1.3,
              fontWeight: FontWeight.w600,
              color: tinta,
            ),
            titleMedium: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 16,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: tinta,
            ),
            bodyMedium: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              height: 1.5,
              color: tinta,
            ),
          )
          .apply(fontFamily: 'Roboto'),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: tinta,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: tinta,
        ),
        shape: Border(bottom: BorderSide(color: garis)),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: garis),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 14),
        hintStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          color: AppColors.textMuted,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: garis),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: garis),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: utama, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: utama,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 48),
          shape: bentuk,
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: bentuk,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: bentuk,
          side: const BorderSide(color: garis),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: utama,
        foregroundColor: Colors.white,
        elevation: 1,
        shape: bentuk,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        indicatorColor: AppColors.softSage,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
            color: states.contains(WidgetState.selected)
                ? utama
                : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 23,
            color: states.contains(WidgetState.selected)
                ? utama
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: utama,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: utama,
        dividerColor: garis,
        labelStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerTheme: const DividerThemeData(color: garis, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: tinta,
        contentTextStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 13,
          color: Colors.white,
        ),
        shape: bentuk,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: utama),
    );
  }
}
