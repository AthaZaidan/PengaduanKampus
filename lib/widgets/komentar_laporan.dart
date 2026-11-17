import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/fitur_laporan_service.dart';
import '../services/laporan_repository.dart';

class KomentarLaporan extends StatefulWidget {
  final String laporanId;
  final AppUser user;
  const KomentarLaporan({
    super.key,
    required this.laporanId,
    required this.user,
  });
  @override
  State<KomentarLaporan> createState() => _KomentarLaporanState();
}

class _KomentarLaporanState extends State<KomentarLaporan> {
  final _teks = TextEditingController();
  late final _service = FiturLaporanService(widget.user.uid);
  late final _stream = _service.komentar(widget.laporanId);
  bool _sibuk = false;
  String? _galat;
  @override
  void dispose() {
    _teks.dispose();
    super.dispose();
  }

  Future<void> _kirim() async {
    if (_sibuk || _teks.text.trim().isEmpty) return;
    setState(() {
      _sibuk = true;
      _galat = null;
    });
    try {
      await _service.kirimKomentar(widget.laporanId, widget.user, _teks.text);
      if (mounted) _teks.clear();
    } catch (e) {
      if (mounted) setState(() => _galat = pesanGalatFirebase(e));
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Klarifikasi laporan',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          const Text(
            'Percakapan ini dapat dibaca oleh pelapor dan petugas yang berwenang.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.hasError) {
                return const Text(
                  'Komentar belum dapat dimuat. Periksa koneksi atau izin akses.',
                );
              }
              if (!snap.hasData) return const LinearProgressIndicator();
              if (snap.data!.docs.isEmpty) {
                return const Text(
                  'Belum ada komentar.',
                  style: TextStyle(fontSize: 12),
                );
              }
              return Column(
                children: [
                  for (final doc in snap.data!.docs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc.data()['nama'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(doc.data()['teks'] as String),
                            if (doc.metadata.hasPendingWrites)
                              const Text(
                                'Menunggu konfirmasi server',
                                style: TextStyle(fontSize: 10),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _teks,
            enabled: !_sibuk,
            minLines: 1,
            maxLines: 4,
            maxLength: 2000,
            decoration: const InputDecoration(
              labelText: 'Tulis klarifikasi atau pertanyaan',
            ),
          ),
          if (_galat != null)
            Text(
              _galat!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          FilledButton.icon(
            onPressed: _sibuk ? null : _kirim,
            icon: const Icon(Icons.send_outlined, size: 18),
            label: Text(_sibuk ? 'Mengirim…' : 'Kirim komentar'),
          ),
        ],
      ),
    ),
  );
}
