import 'dart:typed_data';

import 'package:web/web.dart' as web;
import 'package:pengaduan_kampus/services/foto_lokal_web.dart';

/// Tes IndexedDB mandiri tanpa memuat renderer CanvasKit dari runner Flutter.
Future<void> main() async {
  final service = FotoLokalService();
  const path = 'draf/smoke/foto';
  try {
    final bytes = Uint8List.fromList([137, 80, 78, 71]);
    await service.simpan(path, bytes);
    final hasil = await FotoLokalService().baca(path);
    if (hasil == null || hasil.join(',') != bytes.join(',')) {
      throw StateError('Foto tidak dipulihkan dari IndexedDB.');
    }
    await service.hapus(path);
    if (await service.baca(path) != null) {
      throw StateError('Foto yang dihapus masih tersedia.');
    }
    var ditolak = false;
    try {
      await service.simpan('../rahasia', bytes);
    } on StateError {
      ditolak = true;
    }
    if (!ditolak) throw StateError('Path tidak valid diterima.');
    web.document.body!.textContent =
        'PASS: IndexedDB simpan, pulihkan, hapus, dan validasi path';
  } catch (error) {
    web.document.body!.textContent = 'FAIL: $error';
  }
}
