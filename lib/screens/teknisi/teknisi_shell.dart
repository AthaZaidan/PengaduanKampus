import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../providers/laporan_provider.dart';
import '../shared/kerangka_navigasi.dart';
import '../shared/profile_page.dart';
import 'teknisi_kinerja_page.dart';
import 'teknisi_tugas_page.dart';

/// Navigasi untuk teknisi: tugas, kinerja, dan profil.
class TeknisiShell extends StatefulWidget {
  final LaporanProvider provider;
  final AppUser user;

  const TeknisiShell({
    super.key,
    required this.provider,
    required this.user,
  });

  @override
  State<TeknisiShell> createState() => _TeknisiShellState();
}

class _TeknisiShellState extends State<TeknisiShell> {
  int _index = 0;
  late final List<TabNav> _tabs = _susunTab();

  List<TabNav> _susunTab() {
    final p = widget.provider;
    final u = widget.user;

    return [
      TabNav(
        'Tugas',
        Icons.assignment_outlined,
        Icons.assignment_rounded,
        TeknisiTugasPage(provider: p, user: u),
      ),
      TabNav(
        'Kinerja',
        Icons.bar_chart_outlined,
        Icons.bar_chart_rounded,
        TeknisiKinerjaPage(provider: p, user: u),
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
