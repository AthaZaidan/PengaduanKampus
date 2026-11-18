import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../providers/laporan_provider.dart';
import '../theme/palet_kampus.dart';
import '../theme/tema_kampus.dart';
import 'authentication/login_page.dart';
import 'main_shell.dart';

/// Layar pembuka berlatar hijau solid (tanpa gradasi). Setelah jeda singkat,
/// pengguna yang masih punya sesi diteruskan ke beranda, selain itu ke login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _durasiMinimal = Duration(milliseconds: 2200);
  Timer? _timer;
  Completer<void>? _jeda;

  @override
  void initState() {
    super.initState();
    _lanjut();
  }

  @override
  void dispose() {
    _timer?.cancel();
    final jeda = _jeda;
    if (jeda != null && !jeda.isCompleted) {
      jeda.complete();
    }
    super.dispose();
  }

  Future<void> _tungguMinimal() {
    final completer = Completer<void>();
    _jeda = completer;
    _timer = Timer(_durasiMinimal, () {
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }

  Future<void> _lanjut() async {
    final jeda = _tungguMinimal();
    User? user;
    if (Firebase.apps.isNotEmpty) {
      try {
        // Pada web, sesi tersimpan baru tersedia setelah event autentikasi pertama.
        user = await FirebaseAuth.instance
            .authStateChanges()
            .first
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        try {
          user = FirebaseAuth.instance.currentUser;
        } catch (_) {
          user = null;
        }
      }
    }
    await jeda;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, _, _) => user == null
            ? const LoginPage()
            : MainShell(provider: LaporanProvider.shared),
        transitionsBuilder: (_, animasi, _, anak) =>
            FadeTransition(opacity: animasi, child: anak),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaKampus.utama,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOut,
                  builder: (context, nilai, anak) => Opacity(
                    opacity: nilai,
                    child: Transform.translate(
                      offset: Offset(0, 12 * (1 - nilai)),
                      child: anak,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/branding/logo_glyph_white.png',
                        width: 120,
                        height: 120,
                        filterQuality: FilterQuality.medium,
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Pengaduan Kampus',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'LAYANAN FASILITAS KAMPUS',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
                backgroundColor: AppColors.sageGreen,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
