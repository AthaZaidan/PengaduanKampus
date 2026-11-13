import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../models/laporan.dart';
import '../../providers/laporan_provider.dart';
import '../../widgets/sla_chip.dart';
import '../shared/detail_laporan_page.dart';
import '../shared/notifikasi_page.dart';

/// Beranda admin fasilitas: antrian kerja (verifikasi, penugasan, SLA).
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
    final scheme = Theme.of(context).colorScheme;
    final semua = provider.untuk(user);

    int hitung(StatusLaporan s) => semua.where((l) => l.status == s).length;
    final perluVerifikasi = hitung(StatusLaporan.menunggu);
    final perluDitugaskan = hitung(StatusLaporan.diverifikasi);
    final dikerjakan =
        hitung(StatusLaporan.ditugaskan) + hitung(StatusLaporan.diproses);
    final lewatSla = semua.where((l) => l.aktif && l.melewatiSla).length;

    // Antrian: laporan yang butuh tindakan admin, prioritas tinggi & terlama dulu.
    final antrian = semua
        .where((l) =>
            l.status == StatusLaporan.menunggu ||
            l.status == StatusLaporan.diverifikasi)
        .toList()
      ..sort((a, b) {
        final p = b.prioritas.index.compareTo(a.prioritas.index);
        return p != 0 ? p : a.tanggalLapor.compareTo(b.tanggalLapor);
      });

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Beranda Admin',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
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
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  scheme.primary,
                  Color.alphaBlend(
                      Colors.black.withValues(alpha: 0.3), scheme.primary),
                ],
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.admin_panel_settings_rounded,
                    color: Colors.white, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, ${user.nama}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        perluVerifikasi + perluDitugaskan == 0
                            ? 'Tidak ada laporan yang menunggu tindakan.'
                            : '${perluVerifikasi + perluDitugaskan} laporan menunggu tindakan Anda.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Antrian(
                  nilai: perluVerifikasi,
                  label: 'Perlu Verifikasi',
                  ikon: StatusLaporan.menunggu.icon,
                  warna: StatusLaporan.menunggu.color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Antrian(
                  nilai: perluDitugaskan,
                  label: 'Perlu Ditugaskan',
                  ikon: StatusLaporan.diverifikasi.icon,
                  warna: StatusLaporan.diverifikasi.color,
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
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Antrian(
                  nilai: lewatSla,
                  label: 'Lewat SLA',
                  ikon: Icons.timer_off_outlined,
                  warna: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Perlu Tindakan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: onLihatSemua,
                child: const Text('Semua Laporan'),
              ),
            ],
          ),
          if (antrian.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.task_alt_rounded,
                        size: 44, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'Semua laporan sudah ditindaklanjuti.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
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

  const _Antrian({
    required this.nilai,
    required this.label,
    required this.ikon,
    required this.warna,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: warna.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
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
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    laporan.status.color.withValues(alpha: 0.15),
                child: Icon(laporan.status.icon,
                    color: laporan.status.color, size: 20),
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
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$aksi \u2022 ${laporan.lokasi}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color:
                                laporan.prioritas.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            laporan.prioritas.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: laporan.prioritas.color,
                            ),
                          ),
                        ),
                        SlaChip(laporan: laporan),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
