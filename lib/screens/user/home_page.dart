import 'package:flutter/material.dart';

import '../../models/laporan.dart';
import '../../models/app_user.dart';
import '../../providers/laporan_provider.dart';
import '../../widgets/identitas_kampus.dart';
import '../../widgets/komponen_kampus.dart';
import '../shared/detail_laporan_page.dart';
import '../shared/notifikasi_page.dart';
import 'buat_laporan_page.dart';

class HomePage extends StatelessWidget {
  final LaporanProvider provider;
  final AppUser user;
  final VoidCallback onLihatLaporan;
  const HomePage({
    super.key,
    required this.provider,
    required this.user,
    required this.onLihatLaporan,
  });

  void _buat(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => BuatLaporanPage(provider: provider, user: user),
    ),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: provider,
    builder: (context, _) {
      final scheme = Theme.of(context).colorScheme;
      final semua = provider.untuk(user);
      final aktif = semua.where((l) => l.aktif).length;
      final menunggu = semua
          .where((l) => l.aktif && l.status != StatusLaporan.diproses)
          .length;
      final proses = semua
          .where((l) => l.status == StatusLaporan.diproses)
          .length;
      final selesai = semua
          .where((l) => l.status == StatusLaporan.selesai)
          .length;
      return Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              LambangKampus(ukuran: 32),
              SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Pengaduan Kampus',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Notifikasi',
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      NotifikasiPage(provider: provider, user: user),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 104),
          children: [
            Text(
              'LAYANAN FASILITAS KAMPUS',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selamat datang, ${user.nama}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              aktif == 0
                  ? 'Sampaikan kendala fasilitas dan pantau penanganannya di sini.'
                  : '$aktif laporan Anda masih dalam penanganan. Pantau perkembangannya melalui daftar laporan.',
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: scheme.primary,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.edit_note_outlined,
                      size: 27,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Ada fasilitas yang perlu diperbaiki?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sertakan lokasi dan foto agar petugas dapat menindaklanjuti dengan tepat.',
                      style: TextStyle(
                        color: Color(0xFFD8E2EC),
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _buat(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: scheme.primary,
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Buat laporan'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            const JudulBagian('Ringkasan laporan'),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: width,
                      child: RingkasanAngka(
                        label: 'Total laporan',
                        angka: semua.length,
                        ikon: Icons.assignment_outlined,
                        warna: scheme.primary,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: RingkasanAngka(
                        label: 'Menunggu',
                        angka: menunggu,
                        ikon: StatusLaporan.menunggu.icon,
                        warna: StatusLaporan.menunggu.color,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: RingkasanAngka(
                        label: 'Dikerjakan',
                        angka: proses,
                        ikon: StatusLaporan.diproses.icon,
                        warna: StatusLaporan.diproses.color,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: RingkasanAngka(
                        label: 'Selesai',
                        angka: selesai,
                        ikon: StatusLaporan.selesai.icon,
                        warna: StatusLaporan.selesai.color,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            JudulBagian(
              'Laporan terbaru',
              aksi: 'Lihat semua',
              onAksi: onLihatLaporan,
            ),
            const SizedBox(height: 10),
            if (semua.isEmpty)
              const Card(
                child: KeadaanKosong(
                  judul: 'Belum ada laporan',
                  keterangan: 'Laporan yang Anda kirim akan tercatat di sini beserta perkembangannya.',
                ),
              )
            else
              for (final l in semua.take(3))
                KartuLaporan(
                  laporan: l,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DetailLaporanPage(
                        laporan: l,
                        provider: provider,
                        user: user,
                      ),
                    ),
                  ),
                ),
          ],
        ),
      );
    },
  );
}
