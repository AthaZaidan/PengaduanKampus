import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../providers/laporan_provider.dart';
import '../shared/kerangka_navigasi.dart';
import '../shared/profile_page.dart';
import '../shared/statistik_page.dart';
import 'buat_laporan_page.dart';
import 'home_page.dart';
import 'user_laporan_page.dart';

/// Navigasi untuk pelapor: mahasiswa, dosen, dan staf.
class UserShell extends StatefulWidget {
  final LaporanProvider provider;
  final AppUser user;

  const UserShell({
    super.key,
    required this.provider,
    required this.user,
  });

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  int _index = 0;
  late final List<TabNav> _tabs = _susunTab();

  List<TabNav> _susunTab() {
    final p = widget.provider;
    final u = widget.user;

    return [
      TabNav(
        'Dashboard',
        Icons.dashboard_outlined,
        Icons.dashboard_rounded,
        HomePage(
          provider: p,
          user: u,
          onBuatLaporan: () => setState(() => _index = 1),
        ),
      ),
      TabNav(
        'Laporan',
        Icons.list_alt_outlined,
        Icons.list_alt_rounded,
        UserLaporanPage(provider: p, user: u),
      ),
      TabNav('Statistik', Icons.bar_chart_outlined, Icons.bar_chart_rounded,
          StatistikPage(provider: p, user: u)),
      TabNav(
        'Profil',
        Icons.person_outline_rounded,
        Icons.person_rounded,
        ProfilePage(provider: p, user: u),
      ),
    ];
  }

  // Tombol "Buat Laporan" hanya di tab Dashboard dan Laporan.
  bool get _tampilkanTombolBuat => _index <= 1;

  void _buatLaporan() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BuatLaporanPage(
          provider: widget.provider,
          user: widget.user,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return KerangkaNavigasi(
      tabs: _tabs,
      index: _index,
      onPilih: (i) => setState(() => _index = i),
      tombolAksi: _tampilkanTombolBuat
          ? FloatingActionButton.extended(
              onPressed: _buatLaporan,
              backgroundColor: scheme.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Buat Laporan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }
}
