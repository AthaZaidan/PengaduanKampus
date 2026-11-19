import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/laporan.dart';
import '../../providers/laporan_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sla_chip.dart';
import '../shared/detail_laporan_page.dart';
import '../shared/notifikasi_page.dart';
import 'kelola_aset_page.dart';
import 'kelola_lokasi_page.dart';

/// Tata letak dari AlhamSaragih, feature/pembaruan-ui (d63ebe2, 454065a).
/// Beranda admin fasilitas: antrean kerja (verifikasi, penugasan, SLA).
class AdminDashboardPage extends StatelessWidget {
  final LaporanProvider provider;
  final AppUser user;

  /// Pindah ke tab "Laporan" pada navigasi bawah.
  final VoidCallback onLihatSemua;

  const AdminDashboardPage({
    super.key,
    required this.provider,
    required this.user,
    required this.onLihatSemua,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final semua = provider.untuk(user);

    int hitung(StatusLaporan s) => semua.where((l) => l.status == s).length;
    final perluVerifikasi = hitung(StatusLaporan.menunggu);
    final perluDitugaskan = hitung(StatusLaporan.diverifikasi);
    final dikerjakan =
        hitung(StatusLaporan.ditugaskan) + hitung(StatusLaporan.diproses);
    final lewatSla = semua.where((l) => l.aktif && l.melewatiSla).length;

    // Antrian: laporan yang butuh tindakan admin, prioritas tinggi & terlama dulu.
    final antrian =
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Beranda Admin Fasilitas',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2, color: Colors.white),
            tooltip: 'Kelola Aset & QR Code',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const KelolaAsetPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.location_on_outlined, color: Colors.white),
            tooltip: 'Kelola Lokasi Kampus',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const KelolaLokasiPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            tooltip: 'Notifikasi',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NotifikasiPage(provider: provider, user: user),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Kartu sambutan adaptasi desain Alham
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.forestGreen,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_outlined,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat datang, ${user.nama}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        perluVerifikasi + perluDitugaskan == 0
                            ? 'Tidak ada laporan yang menunggu verifikasi atau penugasan.'
                            : '${perluVerifikasi + perluDitugaskan} laporan butuh penanganan segera.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2x2 Antrian Cards
          Row(
            children: [
              Expanded(
                child: _Antrian(
                  nilai: perluVerifikasi,
                  label: 'Perlu Verifikasi',
                  ikon: StatusLaporan.menunggu.icon,
                  warna: StatusLaporan.menunggu.color,
                  latar: StatusLaporan.menunggu.backgroundColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Antrian(
                  nilai: perluDitugaskan,
                  label: 'Perlu Ditugaskan',
                  ikon: StatusLaporan.diverifikasi.icon,
                  warna: StatusLaporan.diverifikasi.color,
                  latar: StatusLaporan.diverifikasi.backgroundColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Antrian(
                  nilai: dikerjakan,
                  label: 'Sedang Ditangani',
                  ikon: StatusLaporan.diproses.icon,
                  warna: StatusLaporan.diproses.color,
                  latar: StatusLaporan.diproses.backgroundColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Antrian(
                  nilai: lewatSla,
                  label: 'Lewat Batas SLA',
                  ikon: Icons.timer_off_outlined,
                  warna: AppColors.statusDitolak,
                  latar: AppColors.statusDitolakBg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _KartuKelolaAset(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const KelolaAsetPage()),
            ),
          ),
          const SizedBox(height: 10),
          _KartuKelolaLokasi(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const KelolaLokasiPage()),
            ),
          ),
          const SizedBox(height: 22),

          // Header Section Perlu Tindakan
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 4,
            children: [
              const Text(
                'Perlu Tindakan Cepat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepForest,
                ),
              ),
              TextButton(
                onPressed: onLihatSemua,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.forestGreen,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Semua Laporan',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (antrian.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.softSage.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.task_alt,
                      size: 38,
                      color: AppColors.forestGreen,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Semua laporan sudah ditindaklanjuti',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.deepForest,
                    ),
                  ),
                ],
              ),
            )
          else
            for (final l in antrian.take(6))
              _BarisAntrian(
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
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _Antrian extends StatelessWidget {
  final int nilai;
  final String label;
  final IconData ikon;
  final Color warna;
  final Color latar;

  const _Antrian({
    required this.nilai,
    required this.label,
    required this.ikon,
    required this.warna,
    required this.latar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepForest.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: latar,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(ikon, color: warna, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$nilai',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepForest,
                  ),
                ),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarisAntrian extends StatelessWidget {
  final Laporan laporan;
  final VoidCallback onTap;

  const _BarisAntrian({required this.laporan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final aksi = laporan.status == StatusLaporan.menunggu
        ? 'Perlu diverifikasi'
        : 'Perlu ditugaskan';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderSubtle, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: laporan.status.backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  laporan.status.icon,
                  color: laporan.status.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      laporan.judul,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.deepForest,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$aksi \u2022 ${laporan.lokasi}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Prioritas: dot indicator + teks (tanpa pill latar)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: laporan.prioritas.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              laporan.prioritas.label,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: laporan.prioritas.color,
                              ),
                            ),
                          ],
                        ),
                        SlaChip(laporan: laporan),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _KartuKelolaAset extends StatelessWidget {
  final VoidCallback onTap;

  const _KartuKelolaAset({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderSubtle, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.statusDitugaskanBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.qr_code_2,
                  color: AppColors.statusDitugaskan,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kelola Aset & QR Code',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: AppColors.deepForest,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Daftarkan inventaris kampus dan buat QR Code untuk pelaporan.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _KartuKelolaLokasi extends StatelessWidget {
  final VoidCallback onTap;

  const _KartuKelolaLokasi({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderSubtle, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.statusDiverifikasiBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.forestGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kelola Lokasi Kampus',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: AppColors.deepForest,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tambah atau hapus pilihan gedung dan ruang laporan.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
