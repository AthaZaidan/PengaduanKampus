import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 
import 'screens/authentication/login_page.dart';
import 'theme/tema_aksen.dart';

void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();

  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const PengaduanKampusApp());
}

class PengaduanKampusApp extends StatelessWidget {
  const PengaduanKampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pengaduan Kampus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      // Warna aksen mengikuti peran; dipasang di atas Navigator supaya halaman
      // yang di-push dan dialog ikut berwarna sama.
      builder: (context, child) => ValueListenableBuilder<Color?>(
        valueListenable: TemaAksen.warna,
        builder: (context, warna, _) {
          if (warna == null || child == null) return child ?? const SizedBox();
          final tema = Theme.of(context);
          return Theme(
            data: tema.copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: warna,
                brightness: Brightness.light,
              ),
            ),
            child: child,
          );
        },
      ),
      home: const LoginPage(),
    );
  }
}