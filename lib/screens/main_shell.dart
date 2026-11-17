import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../providers/laporan_provider.dart';
import '../theme/tema_aksen.dart';
import '../widgets/status_sinkronisasi.dart';
import 'admin/admin_shell.dart';
import 'teknisi/teknisi_shell.dart';
import 'user/user_shell.dart';

/// Pintu masuk setelah login: membaca peran pengguna dari Firestore lalu
/// mengarahkan ke shell yang sesuai:
///  - admin fasilitas -> `screens/admin/`
///  - teknisi         -> `screens/teknisi/`
///  - pelapor         -> `screens/user/` (mahasiswa, dosen, staf)
class MainShell extends StatefulWidget {
  final LaporanProvider provider;
  const MainShell({super.key, required this.provider});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late Future<AppUser?> _muatUser = _ambilUser();

  Future<AppUser?> _ambilUser() async {
    final auth = FirebaseAuth.instance.currentUser;
    if (auth == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(auth.uid)
        .get();
    if (!doc.exists) {
      throw StateError('Profil belum tersedia. Hubungi admin kampus.');
    }
    final data = doc.data()!;
    final user = AppUser.dariData(
      uid: auth.uid,
      data: data,
      namaAuth: auth.displayName,
      emailAuth: auth.email,
    );
    if (mounted) widget.provider.hubungkan(user);
    return user;
  }

  @override
  void dispose() {
    widget.provider.putuskan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: _muatUser,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profil belum termuat')),
            body: Center(
              child: FilledButton(
                onPressed: () => setState(() => _muatUser = _ambilUser()),
                child: const Text('Coba lagi'),
              ),
            ),
          );
        }
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final asli = snap.data;
        if (asli == null) {
          return const Scaffold(
            body: Center(child: Text('Sesi berakhir. Silakan masuk lagi.')),
          );
        }

        final aktif = asli;

        // Tema aksen berbeda untuk tiap peran (diterapkan di MaterialApp).
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (TemaAksen.warna.value != aktif.peran.warna) {
            TemaAksen.warna.value = aktif.peran.warna;
          }
        });

        if (aktif.peran.isAdmin) {
          return _denganStatus(
            AdminShell(
              key: const ValueKey('admin'),
              provider: widget.provider,
              user: aktif,
            ),
          );
        }
        if (aktif.peran.isTeknisi) {
          return _denganStatus(
            TeknisiShell(
              key: const ValueKey('teknisi'),
              provider: widget.provider,
              user: aktif,
            ),
          );
        }
        return _denganStatus(
          UserShell(
            key: const ValueKey('pelapor'),
            provider: widget.provider,
            user: aktif,
          ),
        );
      },
    );
  }

  Widget _denganStatus(Widget halaman) => Column(
    children: [
      StatusSinkronisasi(provider: widget.provider),
      Expanded(child: halaman),
    ],
  );
}
