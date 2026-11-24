import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/laporan.dart';
import '../../providers/laporan_provider.dart';
import '../../services/fitur_laporan_service.dart';
import '../../services/laporan_repository.dart';
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
  Set<String> _dihapus = {};
  bool _modePilih = false;
  final Set<String> _terpilih = {};

  StreamSubscription<Set<String>>? _subscription;
  StreamSubscription<Set<String>>? _dihapusSubscription;
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _komentarSubs = {};
  final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _komentar = {};
  bool _komentarGagal = false;

  void _pantauKomentar() {
    if (!provider.menggunakanFirebase) return;
    final ids = provider.untuk(user).map((l) => l.id).toSet();
    for (final id in _komentarSubs.keys.toList()) {
      if (!ids.contains(id)) {
        _komentarSubs.remove(id)?.cancel();
        _komentar.remove(id);
      }
    }
    for (final id in ids) {
      _komentarSubs.putIfAbsent(
        id,
        () => FirebaseFirestore.instance
            .collection('laporan/$id/komentar')
            .orderBy('createdAt')
            .limitToLast(10)
            .snapshots()
            .listen(
              (s) {
                if (mounted) setState(() => _komentar[id] = s.docs);
              },
              onError: (Object _) {
                if (mounted) setState(() => _komentarGagal = true);
              },
            ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    provider.addListener(_pantauKomentar);
    _pantauKomentar();
    if (provider.menggunakanFirebase) {
      final service = FiturLaporanService(user.uid);
      _subscription = service.dibaca().listen(
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
      _dihapusSubscription = service.dihapus().listen(
        (ids) {
          if (mounted) {
            setState(() {
              _dihapus = ids;
              _terpilih.removeWhere(ids.contains);
              if (_terpilih.isEmpty) _modePilih = false;
            });
          }
        },
        onError: (_) {},
      );
    }
  }

  @override
  void dispose() {
    provider.removeListener(_pantauKomentar);
    for (final sub in _komentarSubs.values) {
      sub.cancel();
    }
    _subscription?.cancel();
    _dihapusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _tandai(Iterable<String> ids) async {
    final daftar = ids.toList();
    if (daftar.isEmpty) return;
    try {
      if (provider.menggunakanFirebase) {
        await FiturLaporanService(user.uid).tandaiDibaca(daftar);
      }
      if (mounted) setState(() => _dibaca.addAll(daftar));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(pesanGalatFirebase(e))),
        );
      }
    }
  }

  void _togglePilih(String id) {
    setState(() {
      if (_terpilih.contains(id)) {
        _terpilih.remove(id);
        if (_terpilih.isEmpty) _modePilih = false;
      } else {
        _terpilih.add(id);
      }
    });
  }

  void _keluarModePilih() {
    setState(() {
      _modePilih = false;
      _terpilih.clear();
    });
  }

  Future<void> _hapusNotif({
    required List<String> targetIds,
    required bool semua,
  }) async {
    if (targetIds.isEmpty) return;

    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(semua ? 'Hapus semua notifikasi?' : 'Hapus notifikasi?'),
        content: Text(
          semua
              ? 'Semua notifikasi (${targetIds.length}) akan dihapus dari daftar Anda.'
              : '${targetIds.length} notifikasi terpilih akan dihapus dari daftar Anda.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    try {
      if (provider.menggunakanFirebase) {
        await FiturLaporanService(user.uid).hapusNotifikasi(targetIds);
      }
      if (!mounted) return;
      setState(() {
        _dihapus.addAll(targetIds);
        _terpilih.removeAll(targetIds);
        if (_terpilih.isEmpty) _modePilih = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            semua
                ? 'Semua notifikasi dihapus.'
                : '${targetIds.length} notifikasi dihapus.',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(pesanGalatFirebase(e))),
        );
      }
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
        final id = '${laporan.id}_$i';
        if (_dihapus.contains(id)) continue;
        hasil.add(_Notif(laporan, laporan.riwayat[i], id));
      }
    }
    for (final laporan in provider.untuk(user)) {
      final docs =
          _komentar[laporan.id] ??
          const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      for (final doc in docs) {
        final data = doc.data();
        if (data == null) continue;
        if (data['uid'] == user.uid) continue;
        final waktu = data['createdAt'];
        if (waktu is! Timestamp) continue;
        final id = 'komentar_${laporan.id}_${doc.id}';
        if (_dihapus.contains(id)) continue;
        hasil.add(
          _Notif(
            laporan,
            RiwayatStatus(
              status: laporan.status,
              waktu: waktu.toDate(),
              oleh: data['nama'] as String? ?? 'Pengguna',
              catatan: data['teks'] as String?,
            ),
            id,
            komentar: true,
          ),
        );
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
    final semuaTerpilih =
        daftar.isNotEmpty && _terpilih.length == daftar.length;

    return PopScope(
      canPop: !_modePilih,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _modePilih) {
          _keluarModePilih();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          leading: _modePilih
              ? IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Batal pilih',
                  onPressed: _keluarModePilih,
                )
              : null,
          title: Text(
            _modePilih ? '${_terpilih.length} dipilih' : 'Notifikasi',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: _modePilih
              ? [
                  TextButton(
                    onPressed: daftar.isEmpty
                        ? null
                        : () {
                            setState(() {
                              if (semuaTerpilih) {
                                _terpilih.clear();
                                _modePilih = false;
                              } else {
                                _terpilih
                                  ..clear()
                                  ..addAll(daftar.map((n) => n.id));
                              }
                            });
                          },
                    child: Text(semuaTerpilih ? 'Batal semua' : 'Pilih semua'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Hapus terpilih',
                    onPressed: _terpilih.isEmpty
                        ? null
                        : () => _hapusNotif(
                            targetIds: _terpilih.toList(),
                            semua: false,
                          ),
                  ),
                ]
              : [
                  if (daftar.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.checklist),
                      tooltip: 'Pilih notifikasi',
                      onPressed: () => setState(() => _modePilih = true),
                    ),
                  PopupMenuButton<String>(
                    tooltip: 'Opsi notifikasi',
                    onSelected: (v) {
                      if (v == 'baca') {
                        _tandai(daftar.map((n) => n.id));
                      } else if (v == 'pilih') {
                        setState(() => _modePilih = true);
                      } else if (v == 'hapus_semua' && daftar.isNotEmpty) {
                        _hapusNotif(
                          targetIds: daftar.map((n) => n.id).toList(),
                          semua: true,
                        );
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'baca',
                        enabled: daftar.isNotEmpty,
                        child: const Text('Tandai semua dibaca'),
                      ),
                      PopupMenuItem(
                        value: 'pilih',
                        enabled: daftar.isNotEmpty,
                        child: const Text('Pilih notifikasi'),
                      ),
                      PopupMenuItem(
                        value: 'hapus_semua',
                        enabled: daftar.isNotEmpty,
                        child: const Text('Hapus semua notifikasi'),
                      ),
                    ],
                  ),
                ],
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
        ),
        bottomNavigationBar: _komentarGagal
            ? const SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Komentar notifikasi belum dapat dimuat. Buka ulang halaman untuk mencoba lagi.',
                  ),
                ),
              )
            : null,
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
                itemBuilder: (context, i) {
                  final item = daftar[i];
                  return _NotifTile(
                    notif: item,
                    dibaca: _dibaca.contains(item.id),
                    modePilih: _modePilih,
                    terpilih: _terpilih.contains(item.id),
                    onLongPress: () {
                      setState(() {
                        _modePilih = true;
                        _terpilih.add(item.id);
                      });
                    },
                    onTap: () {
                      if (_modePilih) {
                        _togglePilih(item.id);
                        return;
                      }
                      _tandai([item.id]);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DetailLaporanPage(
                            laporan: item.laporan,
                            provider: provider,
                            user: user,
                          ),
                        ),
                      );
                    },
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
  final bool modePilih;
  final bool terpilih;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _NotifTile({
    required this.notif,
    required this.onTap,
    required this.onLongPress,
    required this.dibaca,
    this.modePilih = false,
    this.terpilih = false,
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
    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: terpilih
          ? scheme.primary.withValues(alpha: 0.12)
          : dibaca
              ? scheme.surface
              : scheme.primary.withValues(alpha: 0.05),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: terpilih ? scheme.primary : scheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (modePilih) ...[
                Checkbox(
                  value: terpilih,
                  onChanged: (_) => onTap(),
                ),
                const SizedBox(width: 4),
              ],
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
              if (!modePilih)
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}