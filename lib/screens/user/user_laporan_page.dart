import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../models/laporan.dart';
import '../../providers/laporan_provider.dart';
import '../shared/riwayat_page.dart';

/// Daftar laporan milik pelapor (mahasiswa / dosen / staf).
class UserLaporanPage extends StatelessWidget {
  final LaporanProvider provider;
  final AppUser user;

  const UserLaporanPage({super.key, required this.provider, required this.user});

  @override
  Widget build(BuildContext context) {
    return RiwayatPage(
      provider: provider,
      user: user,
      judul: 'Laporan Saya',
      tabs: const [
        TabStatus('Semua'),
        TabStatus('Menunggu', status: {
          StatusLaporan.menunggu,
          StatusLaporan.diverifikasi,
          StatusLaporan.ditugaskan,
        }),
        TabStatus('Dikerjakan', status: {StatusLaporan.diproses}),
        TabStatus('Selesai', status: {StatusLaporan.selesai}),
        TabStatus('Ditolak', status: {StatusLaporan.ditolak}),
      ],
    );
  }
}
