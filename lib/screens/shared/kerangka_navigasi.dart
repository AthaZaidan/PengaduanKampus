import 'package:flutter/material.dart';

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
      body: tabs[index].halaman,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -3),
            )
          ],
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: onPilih,
          destinations: [
            for (final t in tabs)
              NavigationDestination(
                icon: Icon(t.ikon),
                selectedIcon: Icon(t.ikonAktif),
                label: t.label,
              ),
          ],
        ),
      ),
      floatingActionButton: tombolAksi,
    );
  }
}
