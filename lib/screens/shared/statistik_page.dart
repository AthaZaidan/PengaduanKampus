import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/laporan.dart';
import '../../models/statistik_laporan.dart';
import '../../providers/laporan_provider.dart';
import '../../theme/app_theme.dart';

class StatistikPage extends StatelessWidget {
  final LaporanProvider provider;
  final AppUser user;

  const StatistikPage({super.key, required this.provider, required this.user});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final stat = StatistikLaporan.dari(provider.untuk(user));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Statistik Laporan',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
      ),
      body: stat.total == 0
          ? const _KosongState()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _RingkasanGrid(stat: stat),
                const SizedBox(height: 14),
                _KartuSeksi(
                  judul: 'Status Laporan',
                  ikon: Icons.donut_large_rounded,
                  child: _StatusDonut(stat: stat),
                ),
                const SizedBox(height: 14),
                _KartuSeksi(
                  judul: 'Laporan per Kategori',
                  ikon: Icons.category_outlined,
                  child: _KategoriBars(stat: stat),
                ),
                const SizedBox(height: 14),
                _KartuSeksi(
                  judul: 'Tingkat Prioritas',
                  ikon: Icons.flag_outlined,
                  child: _PrioritasBars(stat: stat),
                ),
                const SizedBox(height: 14),
                _KartuSeksi(
                  judul: 'Tren 7 Hari Terakhir',
                  ikon: Icons.bar_chart_rounded,
                  child: _TrenChart(stat: stat),
                ),
                const SizedBox(height: 30),
              ],
            ),
    );
  }
}

class _KosongState extends StatelessWidget {
  const _KosongState();

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
                color: AppColors.softSage.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                size: 44,
                color: AppColors.sageGreen,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Belum Ada Data Statistik',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.deepForest,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Statistik performa dan pengaduan akan muncul setelah ada laporan tercatat.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _KartuSeksi extends StatelessWidget {
  final String judul;
  final IconData ikon;
  final Widget child;

  const _KartuSeksi({
    required this.judul,
    required this.ikon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderSubtle, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(ikon, size: 18, color: AppColors.forestGreen),
                const SizedBox(width: 8),
                Text(
                  judul,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepForest,
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ringkasan 2x2
// ---------------------------------------------------------------------------

class _RingkasanGrid extends StatelessWidget {
  final StatistikLaporan stat;

  const _RingkasanGrid({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                ikon: Icons.assignment_outlined,
                warna: AppColors.forestGreen,
                latar: AppColors.softSage.withValues(alpha: 0.5),
                nilai: '${stat.total}',
                label: 'Total Laporan',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniStat(
                ikon: Icons.task_alt_rounded,
                warna: AppColors.statusSelesai,
                latar: AppColors.statusSelesaiBg,
                nilai: '${(stat.tingkatPenyelesaian * 100).round()}%',
                label: 'Tingkat Selesai',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                ikon: Icons.timer_outlined,
                warna: AppColors.mutedTeal,
                latar: AppColors.mutedTeal.withValues(alpha: 0.15),
                nilai: StatistikLaporan.formatDurasi(stat.rataRataPenyelesaian),
                label: 'Rata-rata Penanganan',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniStat(
                ikon: Icons.hourglass_empty_rounded,
                warna: AppColors.statusMenunggu,
                latar: AppColors.statusMenungguBg,
                nilai: '${stat.menunggu}',
                label: 'Menunggu Tindakan',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData ikon;
  final Color warna;
  final Color latar;
  final String nilai;
  final String label;

  const _MiniStat({
    required this.ikon,
    required this.warna,
    required this.latar,
    required this.nilai,
    required this.label,
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
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    nilai,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.deepForest,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
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

// ---------------------------------------------------------------------------
// Donut status
// ---------------------------------------------------------------------------

class _StatusDonut extends StatelessWidget {
  final StatistikLaporan stat;

  const _StatusDonut({required this.stat});

  @override
  Widget build(BuildContext context) {
    final daftar = StatusLaporan.values;

    return Row(
      children: [
        SizedBox(
          width: 124,
          height: 124,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(124, 124),
                painter: _DonutPainter(
                  nilai: [
                    for (final s in daftar) (stat.perStatus[s] ?? 0).toDouble(),
                  ],
                  warna: [for (final s in daftar) s.color],
                  warnaTrack: AppColors.surfaceContainer,
                  tebal: 16,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${stat.total}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.deepForest,
                    ),
                  ),
                  const Text(
                    'laporan',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            children: [
              for (final s in daftar)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.5),
                  child: Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: s.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.label,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.deepForest,
                          ),
                        ),
                      ),
                      Text(
                        '${stat.perStatus[s] ?? 0}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: AppColors.deepForest,
                        ),
                      ),
                      SizedBox(
                        width: 42,
                        child: Text(
                          '${_persen(stat.perStatus[s] ?? 0, stat.total)}%',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static int _persen(int nilai, int total) =>
      total == 0 ? 0 : (nilai / total * 100).round();
}

class _DonutPainter extends CustomPainter {
  final List<double> nilai;
  final List<Color> warna;
  final Color warnaTrack;
  final double tebal;

  _DonutPainter({
    required this.nilai,
    required this.warna,
    required this.warnaTrack,
    required this.tebal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      tebal / 2,
      tebal / 2,
      size.width - tebal,
      size.height - tebal,
    );

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = tebal
      ..color = warnaTrack;
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);

    final total = nilai.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return;

    var mulai = -math.pi / 2;
    for (var i = 0; i < nilai.length; i++) {
      if (nilai[i] <= 0) continue;
      final sapuan = nilai[i] / total * 2 * math.pi;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = tebal
        ..strokeCap = StrokeCap.round
        ..color = warna[i];
      canvas.drawArc(rect, mulai, sapuan, false, paint);
      mulai += sapuan;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => true;
}

// ---------------------------------------------------------------------------
// Bar horizontal (kategori & prioritas)
// ---------------------------------------------------------------------------

class _BarRow extends StatelessWidget {
  final String label;
  final IconData ikon;
  final int nilai;
  final int maks;
  final Color warna;

  const _BarRow({
    required this.label,
    required this.ikon,
    required this.nilai,
    required this.maks,
    required this.warna,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Row(
              children: [
                Icon(ikon, size: 16, color: AppColors.sageGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.deepForest,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: maks == 0 ? 0 : nilai / maks,
                minHeight: 10,
                backgroundColor: AppColors.surfaceContainerLow,
                valueColor: AlwaysStoppedAnimation<Color>(warna),
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$nilai',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.deepForest,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KategoriBars extends StatelessWidget {
  final StatistikLaporan stat;

  const _KategoriBars({required this.stat});

  @override
  Widget build(BuildContext context) {
    final urut = KategoriKerusakan.values.toList()
      ..sort(
        (a, b) =>
            (stat.perKategori[b] ?? 0).compareTo(stat.perKategori[a] ?? 0),
      );
    final maks = stat.perKategori.values.fold<int>(0, math.max);
    final teratas = urut.first;
    final jumlahTeratas = stat.perKategori[teratas] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (jumlahTeratas > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Paling sering dilaporkan: ${teratas.label} ($jumlahTeratas laporan)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.forestGreen,
              ),
            ),
          ),
        for (final k in urut)
          _BarRow(
            label: k.label,
            ikon: k.icon,
            nilai: stat.perKategori[k] ?? 0,
            maks: maks,
            warna: AppColors.forestGreen,
          ),
      ],
    );
  }
}

class _PrioritasBars extends StatelessWidget {
  final StatistikLaporan stat;

  const _PrioritasBars({required this.stat});

  @override
  Widget build(BuildContext context) {
    const urutan = [
      PrioritasLaporan.tinggi,
      PrioritasLaporan.sedang,
      PrioritasLaporan.rendah,
    ];
    final maks = stat.perPrioritas.values.fold<int>(0, math.max);

    return Column(
      children: [
        for (final p in urutan)
          _BarRow(
            label: p.label,
            ikon: Icons.flag_rounded,
            nilai: stat.perPrioritas[p] ?? 0,
            maks: maks,
            warna: p.color,
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tren 7 hari
// ---------------------------------------------------------------------------

class _TrenChart extends StatelessWidget {
  final StatistikLaporan stat;

  const _TrenChart({required this.stat});

  static const _namaHari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  static const double _tinggiMaks = 90;

  @override
  Widget build(BuildContext context) {
    final maks = stat.tujuhHari.fold<int>(0, (m, e) => math.max(m, e.value));

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < stat.tujuhHari.length; i++)
            Expanded(
              child: _Batang(
                jumlah: stat.tujuhHari[i].value,
                tinggi: stat.tujuhHari[i].value == 0
                    ? 3.0
                    : math.max(
                        8.0,
                        _tinggiMaks * stat.tujuhHari[i].value / maks,
                      ),
                label: _namaHari[stat.tujuhHari[i].key.weekday - 1],
                hariIni: i == stat.tujuhHari.length - 1,
                warna: AppColors.forestGreen,
              ),
            ),
        ],
      ),
    );
  }
}

class _Batang extends StatelessWidget {
  final int jumlah;
  final double tinggi;
  final String label;
  final bool hariIni;
  final Color warna;

  const _Batang({
    required this.jumlah,
    required this.tinggi,
    required this.label,
    required this.hariIni,
    required this.warna,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          jumlah == 0 ? '' : '$jumlah',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: hariIni ? AppColors.forestGreen : AppColors.deepForest,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: 20,
          height: tinggi,
          decoration: BoxDecoration(
            color: jumlah == 0
                ? AppColors.surfaceContainerHigh
                : (hariIni
                      ? warna
                      : AppColors.sageGreen.withValues(alpha: 0.5)),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: hariIni ? FontWeight.w700 : FontWeight.w500,
            color: hariIni ? warna : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
