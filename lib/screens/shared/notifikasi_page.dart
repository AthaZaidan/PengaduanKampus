import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../models/laporan.dart';
import '../../providers/laporan_provider.dart';
import 'detail_laporan_page.dart';

/// Daftar pemberitahuan perubahan status laporan (diambil dari timeline).
class NotifikasiPage extends StatelessWidget {
  final LaporanProvider provider;
  final AppUser user;

  const NotifikasiPage({super.key, required this.provider, required this.user});

  List<_Notif> _kumpulkan() {
    final hasil = <_Notif>[];
    for (final laporan in provider.untuk(user)) {
      // Entri pertama adalah "Laporan dibuat", jadi dilewati.
      for (var i = 1; i < laporan.riwayat.length; i++) {
        hasil.add(_Notif(laporan, laporan.riwayat[i]));
      }
    }
    hasil.sort((a, b) => b.entri.waktu.compareTo(a.entri.waktu));
    return hasil;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final daftar = _kumpulkan();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
      ),
      body: daftar.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_none_rounded,
                        size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text(
                      'Belum ada notifikasi',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Perubahan status laporan akan muncul di sini.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: daftar.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _NotifTile(
                notif: daftar[i],
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DetailLaporanPage(
                      laporan: daftar[i].laporan,
                      provider: provider,
                      user: user,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _Notif {
  final Laporan laporan;
  final RiwayatStatus entri;

  const _Notif(this.laporan, this.entri);
}

class _NotifTile extends StatelessWidget {
  final _Notif notif;
  final VoidCallback onTap;

  const _NotifTile({required this.notif, required this.onTap});

  static String _waktuRelatif(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Baru saja';
    if (d.inMinutes < 60) return '${d.inMinutes} menit lalu';
    if (d.inHours < 24) return '${d.inHours} jam lalu';
    if (d.inDays < 7) return '${d.inDays} hari lalu';
    return '${t.day}/${t.month}/${t.year}';
  }

  @override
  Widget build(BuildContext context) {
    final status = notif.entri.status;
    final catatan = notif.entri.catatan;

    return Card(
      elevation: 1.5,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: status.color.withValues(alpha: 0.15),
                child: Icon(status.icon, color: status.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notif.laporan.judul,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Status berubah menjadi ${status.label}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: status.color,
                      ),
                    ),
                    if (catatan != null && catatan.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        catatan,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      '${_waktuRelatif(notif.entri.waktu)} \u2022 ${notif.laporan.id}',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
