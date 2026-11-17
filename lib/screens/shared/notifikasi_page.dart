import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/fitur_laporan_service.dart';
import '../../services/notifikasi_push_service.dart';
import '../../services/laporan_repository.dart';

import '../../models/app_user.dart';
import '../../models/laporan.dart';
import '../../providers/laporan_provider.dart';
import 'detail_laporan_page.dart';

/// Daftar pemberitahuan perubahan status laporan (diambil dari timeline).
class NotifikasiPage extends StatefulWidget {
  final LaporanProvider provider;
  final AppUser user;

  const NotifikasiPage({super.key, required this.provider, required this.user});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  LaporanProvider get provider => widget.provider;
  AppUser get user => widget.user;
  Set<String> _dibaca = {};
  StreamSubscription<Set<String>>? _subscription;
  bool _sibuk = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _komentarSub;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _pesan = [];
  @override
  void initState() {
    super.initState();
    if (provider.menggunakanFirebase) {
      _komentarSub = FirebaseFirestore.instance
          .collection('users/${user.uid}/pesan_masuk')
          .orderBy('waktu', descending: true)
          .limit(100)
          .snapshots()
          .listen((s) {
            if (mounted) setState(() => _pesan = s.docs);
          }, onError: (Object _) {});
    }
    if (provider.menggunakanFirebase) {
      _subscription = FiturLaporanService(user.uid).dibaca().listen(
        (ids) {
          if (mounted) setState(() => _dibaca = ids);
        },
        onError: (Object _) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Status baca belum dapat dimuat.')),
            );
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _komentarSub?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _tandai(Iterable<String> ids) async {
    final daftar = ids.toList();
    try {
      if (provider.menggunakanFirebase) {
        await FiturLaporanService(user.uid).tandaiDibaca(daftar);
      }
      if (mounted) setState(() => _dibaca.addAll(daftar));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(pesanGalatFirebase(e))));
      }
    }
  }

  Future<void> _aktifkan() async {
    setState(() => _sibuk = true);
    try {
      await NotifikasiPushService.instance.aktifkan(user);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perangkat terdaftar untuk notifikasi push.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(pesanGalatFirebase(e))));
      }
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  List<_Notif> _kumpulkan() {
    final hasil = <_Notif>[];
    for (final laporan in provider.untuk(user)) {
      // Entri pertama adalah "Laporan dibuat", jadi dilewati.
      for (
        var i = user.peran.isAdmin ? 0 : 1;
        i < laporan.riwayat.length;
        i++
      ) {
        hasil.add(_Notif(laporan, laporan.riwayat[i], '${laporan.id}_$i'));
      }
    }
    for (final doc in _pesan) {
      final list = provider
          .untuk(user)
          .where((l) => l.id == doc.data()['laporanId']);
      if (list.isEmpty) continue;
      final waktu = doc.data()['waktu'];
      if (waktu is! Timestamp) continue;
      hasil.add(
        _Notif(
          list.first,
          RiwayatStatus(
            status: list.first.status,
            waktu: waktu.toDate(),
            oleh: 'Pesan klarifikasi',
          ),
          doc.id,
          komentar: true,
        ),
      );
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Opsi notifikasi',
            onSelected: (v) {
              if (v == 'baca') {
                _tandai(daftar.map((n) => n.id));
              } else if (!_sibuk) {
                _aktifkan();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'baca',
                child: Text('Tandai semua dibaca'),
              ),
              if (provider.menggunakanFirebase)
                const PopupMenuItem(
                  value: 'push',
                  child: Text('Aktifkan notifikasi push'),
                ),
            ],
          ),
        ],
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      body: daftar.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Belum ada notifikasi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Perubahan status laporan akan muncul di sini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: daftar.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _NotifTile(
                notif: daftar[i],
                dibaca: _dibaca.contains(daftar[i].id),
                onTap: () {
                  _tandai([daftar[i].id]);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DetailLaporanPage(
                        laporan: daftar[i].laporan,
                        provider: provider,
                        user: user,
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _Notif {
  final Laporan laporan;
  final RiwayatStatus entri;
  final String id;
  final bool komentar;

  const _Notif(this.laporan, this.entri, this.id, {this.komentar = false});
}

class _NotifTile extends StatelessWidget {
  final _Notif notif;
  final bool dibaca;
  final VoidCallback onTap;

  const _NotifTile({
    required this.notif,
    required this.onTap,
    required this.dibaca,
  });

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
      color: dibaca
          ? Theme.of(context).colorScheme.surface
          : Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
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
                    if (!dibaca)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Belum dibaca',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
                      notif.komentar
                          ? 'Klarifikasi baru'
                          : notif.id.endsWith('_0')
                          ? 'Laporan baru diterima'
                          : 'Status berubah menjadi ${status.label}',
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
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
