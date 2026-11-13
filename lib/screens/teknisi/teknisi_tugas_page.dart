import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../models/laporan.dart';
import '../../providers/laporan_provider.dart';
import '../shared/riwayat_page.dart';

/// Daftar tugas yang ditugaskan admin kepada teknisi yang sedang login.
class TeknisiTugasPage extends StatelessWidget {
  final LaporanProvider provider;
  final AppUser user;

  const TeknisiTugasPage({super.key, required this.provider, required this.user});

  @override
  Widget build(BuildContext context) {
    return RiwayatPage(
      provider: provider,
      user: user,
      judul: 'Tugas Saya',
      tabs: const [
        TabStatus('Perlu Dikerjakan', status: {StatusLaporan.ditugaskan}),
        TabStatus('Dikerjakan', status: {StatusLaporan.diproses}),
        TabStatus('Selesai', status: {StatusLaporan.selesai}),
      ],
    );
  }
}
