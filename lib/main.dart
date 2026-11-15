import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/authentication/login_page.dart';
import 'theme/app_theme.dart';
import 'theme/tema_aksen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const PengaduanKampusApp());
}

class PengaduanKampusApp extends StatelessWidget {
  const PengaduanKampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pengaduan Kampus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Warna aksen mengikuti peran jika diset; jika null memakai tema default (Forest Green)
      builder: (context, child) => ValueListenableBuilder<Color?>(
        valueListenable: TemaAksen.warna,
        builder: (context, warna, _) {
          if (warna == null || child == null) return child ?? const SizedBox();
          final tema = Theme.of(context);
          return Theme(
            data: tema.copyWith(
              colorScheme: tema.colorScheme.copyWith(primary: warna),
              appBarTheme: tema.appBarTheme.copyWith(backgroundColor: warna),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: warna,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 22,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
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
