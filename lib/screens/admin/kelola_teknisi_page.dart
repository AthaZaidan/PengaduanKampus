import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/laporan.dart';
import '../../providers/laporan_provider.dart';
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Kelola Teknisi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _tambah(context),
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        icon: const Icon(Icons.person_add_alt),
        label: const Text(
          'Tambah Teknisi',
          style: TextStyle(fontWeight: FontWeight.bold),
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
                    ikon: Icons.error_outline,
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
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        '${daftar.length} teknisi terdaftar',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
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
            Icon(ikon, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              teks,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.4),
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
          backgroundColor: const Color(0xFF257054),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim tautan reset: $e'),
          backgroundColor: const Color(0xFFAC3838),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: scheme.primary.withValues(alpha: 0.12),
              child: Text(
                _inisial(teknisi.nama),
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.bold,
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
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    teknisi.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  if (teknisi.telepon != null)
                    Text(
                      teknisi.telepon!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _Lencana(
                        teks: '$tugasAktif tugas aktif',
                        warna: const Color(0xFF94620E),
                      ),
                      _Lencana(
                        teks: '$tugasSelesai selesai',
                        warna: const Color(0xFF257054),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Aksi',
              onSelected: (v) {
                if (v == 'reset') _kirimReset(context);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'reset',
                  child: Text('Kirim reset password'),
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

  const _Lencana({required this.teks, required this.warna});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        teks,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: warna,
        ),
      ),
    );
  }
}
