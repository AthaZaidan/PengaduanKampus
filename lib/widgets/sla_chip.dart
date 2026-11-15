import 'package:flutter/material.dart';

import '../models/laporan.dart';
import '../models/statistik_laporan.dart';
import '../theme/app_theme.dart';

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
    final Color bgColor;

    if (laporan.aktif) {
      final sisa = laporan.batasSla.difference(DateTime.now());
      if (sisa.isNegative) {
        teks = 'Lewat SLA ${StatistikLaporan.formatDurasi(-sisa)}';
        warna = AppColors.statusDitolak;
        bgColor = AppColors.statusDitolakBg;
      } else {
        teks = 'Sisa ${StatistikLaporan.formatDurasi(sisa)}';
        if (sisa < const Duration(hours: 6)) {
          warna = AppColors.statusMenunggu;
          bgColor = AppColors.statusMenungguBg;
        } else {
          warna = AppColors.statusSelesai;
          bgColor = AppColors.statusSelesaiBg;
        }
      }
    } else if (laporan.melewatiSla) {
      teks = 'Selesai lewat SLA';
      warna = AppColors.statusDitolak;
      bgColor = AppColors.statusDitolakBg;
    } else {
      teks = 'Selesai tepat waktu';
      warna = AppColors.statusSelesai;
      bgColor = AppColors.statusSelesaiBg;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warna.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 12, color: warna),
          const SizedBox(width: 4),
          Text(
            teks,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: warna,
            ),
          ),
        ],
      ),
    );
  }
}
