import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../providers/laporan_provider.dart';
import '../shared/kerangka_navigasi.dart';
import '../shared/profile_page.dart';
import '../shared/statistik_page.dart';
import 'admin_dashboard_page.dart';
import 'admin_laporan_page.dart';
import 'kelola_teknisi_page.dart';

/// Navigasi untuk admin fasilitas: beranda, laporan, statistik, kelola
/// teknisi, dan profil.
class AdminShell extends StatefulWidget {
  final LaporanProvider provider;
  final AppUser user;

  const AdminShell({
    super.key,
    required this.provider,
    required this.user,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;
  late final List<TabNav> _tabs = _susunTab();

  List<TabNav> _susunTab() {
    final p = widget.provider;
    final u = widget.user;

    return [
      TabNav(
        'Beranda',
        Icons.dashboard_outlined,
        Icons.dashboard_rounded,
        AdminDashboardPage(
          provider: p,
          user: u,
          onLihatSemua: () => setState(() => _index = 1),
        ),
      ),
      TabNav(
        'Laporan',
        Icons.list_alt_outlined,
        Icons.list_alt_rounded,
        AdminLaporanPage(provider: p, user: u),
      ),
      TabNav('Statistik', Icons.bar_chart_outlined, Icons.bar_chart_rounded,
          StatistikPage(provider: p, user: u)),
      TabNav(
        'Teknisi',
        Icons.engineering_outlined,
        Icons.engineering_rounded,
        KelolaTeknisiPage(provider: p, user: u),
      ),
      TabNav(
        'Profil',
        Icons.person_outline_rounded,
        Icons.person_rounded,
        ProfilePage(provider: p, user: u),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return KerangkaNavigasi(
      tabs: _tabs,
      index: _index,
      onPilih: (i) => setState(() => _index = i),
    );
  }
}
