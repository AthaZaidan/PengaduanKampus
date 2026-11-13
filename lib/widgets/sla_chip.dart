import 'package:flutter/material.dart';
import '../models/laporan.dart';
import '../models/statistik_laporan.dart';

/// Penanda SLA: sisa waktu / terlambat (laporan aktif) atau hasil akhir.
class SlaChip extends StatelessWidget {
  final Laporan laporan;

  const SlaChip({super.key, required this.laporan});

  @override
  Widget build(BuildContext context) {
    if (laporan.status == StatusLaporan.ditolak) {
      return const SizedBox.shrink();
    }

    final String teks;
    final Color warna;

    if (laporan.aktif) {
      final sisa = laporan.batasSla.difference(DateTime.now());
      if (sisa.isNegative) {
        teks = 'Lewat SLA ${StatistikLaporan.formatDurasi(-sisa)}';
        warna = const Color(0xFFEF4444);
      } else {
        teks = 'Sisa ${StatistikLaporan.formatDurasi(sisa)}';
        warna = sisa < const Duration(hours: 6)
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981);
      }
    } else if (laporan.melewatiSla) {
      teks = 'Selesai lewat SLA';
      warna = const Color(0xFFEF4444);
    } else {
      teks = 'Selesai sesuai SLA';
      warna = const Color(0xFF10B981);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 11, color: warna),
          const SizedBox(width: 3),
          Text(
            teks,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: warna,
            ),
          ),
        ],
      ),
    );
  }
}
