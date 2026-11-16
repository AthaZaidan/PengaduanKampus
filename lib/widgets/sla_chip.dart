import 'package:flutter/material.dart';

import '../models/laporan.dart';
import '../models/statistik_laporan.dart';
import '../theme/app_theme.dart';

/// Penanda SLA: sisa waktu / terlambat (laporan aktif) atau hasil akhir.
///
/// Desain: jika SLA masih aman → teks abu netral tanpa latar (lebih bersih).
/// Jika sudah lewat / kritis → warna Muted Terracotta (#B84A4A) dengan latar.
class SlaChip extends StatelessWidget {
  final Laporan laporan;

  const SlaChip({super.key, required this.laporan});

  @override
  Widget build(BuildContext context) {
    if (laporan.status == StatusLaporan.ditolak) {
      return const SizedBox.shrink();
    }

    // Selesai tepat waktu → badge hijau
    if (!laporan.aktif && !laporan.melewatiSla) {
      return _buildBadge(
        teks: 'Tepat Waktu',
        icon: Icons.check_rounded,
        warna: AppColors.statusSelesai,
        bgColor: AppColors.statusSelesaiBg,
      );
    }

    // Selesai tapi lewat SLA
    if (!laporan.aktif && laporan.melewatiSla) {
      return _buildBadge(
        teks: 'Lewat SLA',
        icon: Icons.timer_off_outlined,
        warna: AppColors.statusDitolak,
        bgColor: AppColors.statusDitolakBg,
      );
    }

    // Aktif: hitung sisa
    final sisa = laporan.batasSla.difference(DateTime.now());
    if (sisa.isNegative) {
      return _buildBadge(
        teks: 'Lewat ${StatistikLaporan.formatDurasi(-sisa)}',
        icon: Icons.timer_off_outlined,
        warna: AppColors.statusDitolak,
        bgColor: AppColors.statusDitolakBg,
      );
    }

    // SLA kritis (< 6 jam) → amber warning
    if (sisa < const Duration(hours: 6)) {
      return _buildBadge(
        teks: 'Sisa ${StatistikLaporan.formatDurasi(sisa)}',
        icon: Icons.timer_outlined,
        warna: AppColors.warning,
        bgColor: AppColors.statusMenungguBg,
      );
    }

    // SLA masih aman → teks netral abu-abu, tanpa latar pill berlebihan
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.access_time_rounded,
          size: 12,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: 3),
        Text(
          'Sisa ${StatistikLaporan.formatDurasi(sisa)}',
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildBadge({
    required String teks,
    required IconData icon,
    required Color warna,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: warna.withValues(alpha: 0.22), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: warna),
          const SizedBox(width: 3),
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
