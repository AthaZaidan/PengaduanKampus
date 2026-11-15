import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/laporan.dart';
import '../../providers/laporan_provider.dart';
import '../../theme/app_theme.dart';
import 'tambah_teknisi_page.dart';

/// Admin: daftar akun teknisi + tombol untuk menambah akun baru.
class KelolaTeknisiPage extends StatelessWidget {
  final LaporanProvider provider;
  final AppUser user;

  const KelolaTeknisiPage({
    super.key,
    required this.provider,
    required this.user,
  });

  Stream<QuerySnapshot<Map<String, dynamic>>> get _stream => FirebaseFirestore
      .instance
      .collection('users')
      .where('role', isEqualTo: 'teknisi')
      .snapshots();

  void _tambah(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => TambahTeknisiPage(admin: user)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Kelola Teknisi',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _tambah(context),
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        elevation: 2.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          'Tambah Teknisi',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      // Jumlah tugas per teknisi ikut diperbarui saat provider berubah.
      body: ListenableBuilder(
        listenable: provider,
        builder: (context, _) =>
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return _Pesan(
                    ikon: Icons.error_outline_rounded,
                    teks: 'Gagal memuat daftar teknisi.\n${snap.error}',
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final daftar =
                    snap.data!.docs
                        .map((d) => AppUser.dariData(uid: d.id, data: d.data()))
                        .toList()
                      ..sort(
                        (a, b) => a.nama.toLowerCase().compareTo(
                          b.nama.toLowerCase(),
                        ),
                      );

                if (daftar.isEmpty) {
                  return const _Pesan(
                    ikon: Icons.engineering_outlined,
                    teks:
                        'Belum ada akun teknisi.\n'
                        'Ketuk "Tambah Teknisi" untuk membuat akun pertama.',
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        '${daftar.length} teknisi terdaftar',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepForest,
                        ),
                      ),
                    ),
                    for (final t in daftar)
                      _KartuTeknisi(
                        teknisi: t,
                        tugasAktif: provider.laporanList
                            .where((l) => l.teknisiId == t.uid && l.aktif)
                            .length,
                        tugasSelesai: provider.laporanList
                            .where(
                              (l) =>
                                  l.teknisiId == t.uid &&
                                  l.status == StatusLaporan.selesai,
                            )
                            .length,
                      ),
                  ],
                );
              },
            ),
      ),
    );
  }
}

class _Pesan extends StatelessWidget {
  final IconData ikon;
  final String teks;

  const _Pesan({required this.ikon, required this.teks});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.softSage.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(ikon, size: 40, color: AppColors.forestGreen),
            ),
            const SizedBox(height: 14),
            Text(
              teks,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KartuTeknisi extends StatelessWidget {
  final AppUser teknisi;
  final int tugasAktif;
  final int tugasSelesai;

  const _KartuTeknisi({
    required this.teknisi,
    required this.tugasAktif,
    required this.tugasSelesai,
  });

  static String _inisial(String nama) {
    final kata = nama
        .trim()
        .split(RegExp(r'\s+'))
        .where((k) => k.isNotEmpty)
        .toList();
    if (kata.isEmpty) return '?';
    if (kata.length == 1) return kata.first[0].toUpperCase();
    return (kata.first[0] + kata[1][0]).toUpperCase();
  }

  Future<void> _kirimReset(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: teknisi.email);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Tautan reset password dikirim ke ${teknisi.email}.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim tautan reset: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderSubtle, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.softSage.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.sageGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Center(
                child: Text(
                  _inisial(teknisi.nama),
                  style: const TextStyle(
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teknisi.nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: AppColors.deepForest,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    teknisi.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (teknisi.telepon != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      teknisi.telepon!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _Lencana(
                        teks: '$tugasAktif tugas aktif',
                        warna: AppColors.statusMenunggu,
                        latar: AppColors.statusMenungguBg,
                      ),
                      _Lencana(
                        teks: '$tugasSelesai selesai',
                        warna: AppColors.statusSelesai,
                        latar: AppColors.statusSelesaiBg,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Aksi',
              iconColor: AppColors.textMuted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onSelected: (v) {
                if (v == 'reset') _kirimReset(context);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'reset',
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_reset_rounded,
                        size: 18,
                        color: AppColors.forestGreen,
                      ),
                      SizedBox(width: 8),
                      Text('Kirim reset password'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Lencana extends StatelessWidget {
  final String teks;
  final Color warna;
  final Color latar;

  const _Lencana({
    required this.teks,
    required this.warna,
    required this.latar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: latar,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: warna.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Text(
        teks,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: warna,
        ),
      ),
    );
  }
}
