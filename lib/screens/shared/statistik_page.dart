import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../models/laporan.dart';
import '../../models/statistik_laporan.dart';
import '../../providers/laporan_provider.dart';

class StatistikPage extends StatelessWidget {
  final LaporanProvider provider;
  final AppUser user;

  const StatistikPage({super.key, required this.provider, required this.user});

  @override
  Widget build(BuildContext context) {
    // Rebuild otomatis setiap provider memanggil notifyListeners().
    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stat = StatistikLaporan.dari(provider.untuk(user));

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Statistik',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
      ),
      body: stat.total == 0
          ? const _KosongState()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _RingkasanGrid(stat: stat),
                const SizedBox(height: 12),
                _KartuSeksi(
                  judul: 'Status Laporan',
                  ikon: Icons.donut_large_rounded,
                  child: _StatusDonut(stat: stat),
                ),
                const SizedBox(height: 12),
                _KartuSeksi(
                  judul: 'Laporan per Kategori',
                  ikon: Icons.category_outlined,
                  child: _KategoriBars(stat: stat),
                ),
                const SizedBox(height: 12),
                _KartuSeksi(
                  judul: 'Tingkat Prioritas',
                  ikon: Icons.flag_outlined,
                  child: _PrioritasBars(stat: stat),
                ),
                const SizedBox(height: 12),
                _KartuSeksi(
                  judul: '7 Hari Terakhir',
                  ikon: Icons.bar_chart_rounded,
                  child: _TrenChart(stat: stat),
                ),
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
            Icon(Icons.bar_chart_rounded,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'Belum ada data statistik',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Statistik akan muncul setelah ada laporan masuk.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
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
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 1.5,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(ikon, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  judul,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
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
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                ikon: Icons.assignment_outlined,
                warna: scheme.primary,
                nilai: '${stat.total}',
                label: 'Total Laporan',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniStat(
                ikon: Icons.task_alt_rounded,
                warna: StatusLaporan.selesai.color,
                nilai: '${(stat.tingkatPenyelesaian * 100).round()}%',
                label: 'Tingkat Penyelesaian',
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
                warna: const Color(0xFF8B5CF6),
                nilai: StatistikLaporan.formatDurasi(stat.rataRataPenyelesaian),
                label: 'Rata-rata Penyelesaian',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniStat(
                ikon: Icons.hourglass_empty_rounded,
                warna: StatusLaporan.menunggu.color,
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
  final String nilai;
  final String label;

  const _MiniStat({
    required this.ikon,
    required this.warna,
    required this.nilai,
    required this.label,
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
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      nilai,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
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
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(120, 120),
                painter: _DonutPainter(
                  nilai: [
                    for (final s in daftar) (stat.perStatus[s] ?? 0).toDouble(),
                  ],
                  warna: [for (final s in daftar) s.color],
                  warnaTrack: Colors.grey.shade200,
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'laporan',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            children: [
              for (final s in daftar)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: s.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child:
                            Text(s.label, style: const TextStyle(fontSize: 13)),
                      ),
                      Text(
                        '${stat.perStatus[s] ?? 0}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${_persen(stat.perStatus[s] ?? 0, stat.total)}%',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
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
                Icon(ikon, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5),
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
                backgroundColor: warna.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(warna),
              ),
            ),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$nilai',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
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
    final scheme = Theme.of(context).colorScheme;
    final urut = KategoriKerusakan.values.toList()
      ..sort((a, b) =>
          (stat.perKategori[b] ?? 0).compareTo(stat.perKategori[a] ?? 0));
    final maks = stat.perKategori.values.fold<int>(0, math.max);
    final teratas = urut.first;
    final jumlahTeratas = stat.perKategori[teratas] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (jumlahTeratas > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'Terbanyak: ${teratas.label} ($jumlahTeratas laporan)',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
        for (final k in urut)
          _BarRow(
            label: k.label,
            ikon: k.icon,
            nilai: stat.perKategori[k] ?? 0,
            maks: maks,
            warna: scheme.primary,
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
    final scheme = Theme.of(context).colorScheme;
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
                        8.0, _tinggiMaks * stat.tujuhHari[i].value / maks),
                label: _namaHari[stat.tujuhHari[i].key.weekday - 1],
                hariIni: i == stat.tujuhHari.length - 1,
                warna: scheme.primary,
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
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          width: 22,
          height: tinggi,
          decoration: BoxDecoration(
            color: jumlah == 0
                ? Colors.grey.shade300
                : (hariIni ? warna : warna.withValues(alpha: 0.4)),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: hariIni ? FontWeight.bold : FontWeight.normal,
            color: hariIni ? warna : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
