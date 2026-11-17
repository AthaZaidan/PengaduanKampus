import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/laporan.dart';
import '../../providers/laporan_provider.dart';
import '../../widgets/komponen_kampus.dart';
import '../shared/detail_laporan_page.dart';
import '../shared/notifikasi_page.dart';

class AdminDashboardPage extends StatelessWidget {
  final LaporanProvider provider;
  final AppUser user;
  final VoidCallback onLihatSemua;
  const AdminDashboardPage({
    super.key,
    required this.provider,
    required this.user,
    required this.onLihatSemua,
  });

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: provider,
    builder: (context, _) {
      final scheme = Theme.of(context).colorScheme;
      final semua = provider.untuk(user);
      int hitung(StatusLaporan s) => semua.where((l) => l.status == s).length;
      final verifikasi = hitung(StatusLaporan.menunggu);
      final penugasan = hitung(StatusLaporan.diverifikasi);
      final ditangani =
          hitung(StatusLaporan.ditugaskan) + hitung(StatusLaporan.diproses);
      final terlambat = semua.where((l) => l.aktif && l.melewatiSla).length;
      final antrean =
          semua
              .where(
                (l) =>
                    l.status == StatusLaporan.menunggu ||
                    l.status == StatusLaporan.diverifikasi,
              )
              .toList()
            ..sort((a, b) {
              final p = b.prioritas.index.compareTo(a.prioritas.index);
              return p != 0 ? p : a.tanggalLapor.compareTo(b.tanggalLapor);
            });
      return Scaffold(
        appBar: AppBar(
          title: const Text('Beranda admin'),
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
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Text(
              'ADMINISTRASI FASILITAS',
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
              verifikasi + penugasan == 0
                  ? 'Seluruh laporan sudah ditindaklanjuti.'
                  : '${verifikasi + penugasan} laporan memerlukan verifikasi atau penugasan.',
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
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
                        label: 'Perlu verifikasi',
                        angka: verifikasi,
                        ikon: StatusLaporan.menunggu.icon,
                        warna: StatusLaporan.menunggu.color,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: RingkasanAngka(
                        label: 'Perlu ditugaskan',
                        angka: penugasan,
                        ikon: StatusLaporan.diverifikasi.icon,
                        warna: StatusLaporan.diverifikasi.color,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: RingkasanAngka(
                        label: 'Sedang ditangani',
                        angka: ditangani,
                        ikon: StatusLaporan.diproses.icon,
                        warna: StatusLaporan.diproses.color,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: RingkasanAngka(
                        label: 'Melewati SLA',
                        angka: terlambat,
                        ikon: Icons.timer_off_outlined,
                        warna: StatusLaporan.ditolak.color,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            JudulBagian(
              'Perlu tindakan',
              aksi: 'Lihat semua',
              onAksi: onLihatSemua,
            ),
            const SizedBox(height: 10),
            if (antrean.isEmpty)
              const Card(
                child: KeadaanKosong(
                  judul: 'Antrean sudah ditangani',
                  keterangan: 'Laporan baru yang memerlukan verifikasi akan muncul di sini.',
                  ikon: Icons.task_alt,
                ),
              )
            else
              for (final l in antrean.take(6))
                KartuLaporan(
                  laporan: l,
                  tampilkanInternal: true,
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
