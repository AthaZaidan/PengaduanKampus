import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../providers/laporan_provider.dart';
import '../theme/tema_aksen.dart';
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
  late final Future<AppUser?> _muatUser = _ambilUser();

  Future<AppUser?> _ambilUser() async {
    final auth = FirebaseAuth.instance.currentUser;
    if (auth == null) return null;

    Map<String, dynamic> data = {};
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(auth.uid)
          .get();
      data = doc.data() ?? {};
    } catch (_) {
      // Gagal membaca profil: pakai data dari Firebase Auth (peran pelapor).
    }
    return AppUser.dariData(
      uid: auth.uid,
      data: data,
      namaAuth: auth.displayName,
      emailAuth: auth.email,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: _muatUser,
      builder: (context, snap) {
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
          return AdminShell(
            key: const ValueKey('admin'),
            provider: widget.provider,
            user: aktif,
          );
        }
        if (aktif.peran.isTeknisi) {
          return TeknisiShell(
            key: const ValueKey('teknisi'),
            provider: widget.provider,
            user: aktif,
          );
        }
        return UserShell(
          key: const ValueKey('pelapor'),
          provider: widget.provider,
          user: aktif,
        );
      },
    );
  }
}
