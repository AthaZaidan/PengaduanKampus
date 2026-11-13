import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../models/laporan.dart';
import '../../providers/laporan_provider.dart';
import '../shared/riwayat_page.dart';

/// Semua laporan masuk, dengan tab per tahap alur kerja.
class AdminLaporanPage extends StatelessWidget {
  final LaporanProvider provider;
  final AppUser user;

  const AdminLaporanPage({super.key, required this.provider, required this.user});

  @override
  Widget build(BuildContext context) {
    return RiwayatPage(
      provider: provider,
      user: user,
      judul: 'Semua Laporan',
      tabs: const [
        TabStatus('Semua'),
        TabStatus('Baru', status: {StatusLaporan.menunggu}),
        TabStatus('Terverifikasi', status: {StatusLaporan.diverifikasi}),
        TabStatus('Ditugaskan', status: {StatusLaporan.ditugaskan}),
        TabStatus('Dikerjakan', status: {StatusLaporan.diproses}),
        TabStatus('Selesai', status: {StatusLaporan.selesai}),
        TabStatus('Ditolak', status: {StatusLaporan.ditolak}),
      ],
    );
  }
}
