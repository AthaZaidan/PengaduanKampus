import 'package:flutter/material.dart';

/// Identitas layanan kampus dipakai bersama oleh seluruh peran.
class TemaKampus {
  static const biru = Color(0xFF203B5C);
  static const tinta = Color(0xFF1E293B);
  static const latar = Color(0xFFF5F7FA);
  static const garis = Color(0xFFDCE3EB);
  static const emas = Color(0xFFBEA271);

  static ThemeData bangun() {
    final scheme = ColorScheme.fromSeed(seedColor: biru).copyWith(
      primary: biru,
      onPrimary: Colors.white,
      secondary: const Color(0xFF526B80),
      surface: Colors.white,
      onSurface: tinta,
      onSurfaceVariant: const Color(0xFF5B6B7D),
      outline: const Color(0xFF8B99AA),
      outlineVariant: garis,
      error: const Color(0xFFAC3838),
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
          color: Color(0xFF718096),
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
          borderSide: const BorderSide(color: biru, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: biru,
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
        backgroundColor: biru,
        foregroundColor: Colors.white,
        elevation: 1,
        shape: bentuk,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        indicatorColor: const Color(0xFFE7EEF5),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
            color: states.contains(WidgetState.selected)
                ? biru
                : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 23,
            color: states.contains(WidgetState.selected)
                ? biru
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: biru,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: biru,
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
        shape: bentuk,
      ),
    );
  }
}
