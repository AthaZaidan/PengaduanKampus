import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Satu definisi tab untuk navigasi bawah.
class TabNav {
  final String label;
  final IconData ikon;
  final IconData ikonAktif;
  final Widget halaman;

  const TabNav(this.label, this.ikon, this.ikonAktif, this.halaman);
}

/// Kerangka halaman utama dengan navigasi bawah. Dipakai bersama oleh shell
/// pelapor (user), teknisi, dan admin supaya tampilan navigasinya seragam.
class KerangkaNavigasi extends StatelessWidget {
  final List<TabNav> tabs;
  final int index;
  final ValueChanged<int> onPilih;

  /// Tombol melayang opsional (mis. "Buat Laporan" atau "Tambah Teknisi").
  final Widget? tombolAksi;

  const KerangkaNavigasi({
    super.key,
    required this.tabs,
    required this.index,
    required this.onPilih,
    this.tombolAksi,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: tabs[index].halaman,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: AppColors.borderSubtle, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepForest.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: NavigationBar(
            height: 66,
            elevation: 0,
            backgroundColor: Colors.white,
            indicatorColor: AppColors.softSage.withValues(alpha: 0.7),
            selectedIndex: index,
            onDestinationSelected: onPilih,
            destinations: [
              for (final t in tabs)
                NavigationDestination(
                  icon: Icon(t.ikon, size: 23, color: AppColors.textMuted),
                  selectedIcon: Icon(
                    t.ikonAktif,
                    size: 23,
                    color: AppColors.forestGreen,
                  ),
                  label: t.label,
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: tombolAksi,
    );
  }
}
