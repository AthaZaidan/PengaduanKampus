import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Berkas aplikasi, bukan folder sementara milik kamera/image_picker.
class FotoLokalService {
  static final instance = FotoLokalService();
  final Future<Directory> Function() direktori;

  FotoLokalService({Future<Directory> Function()? direktori})
    : direktori = direktori ?? getApplicationSupportDirectory;

  Future<File> _file(String path) async {
    if (!RegExp(r'^(draf|laporan)/[A-Za-z0-9_/-]+$').hasMatch(path) ||
        path.split('/').any((p) => p.isEmpty)) {
      throw StateError('Lokasi foto tidak valid.');
    }
    final root = await direktori();
    return File('${root.path}/foto_lokal/$path');
  }

  Future<void> simpan(String path, Uint8List bytes) async {
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      throw StateError('Foto harus berisi data dan maksimal 5 MB.');
    }
    final file = await _file(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
  }

  Future<Uint8List?> baca(String path) async {
    final file = await _file(path);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  Future<void> hapus(String path) async {
    final file = await _file(path);
    if (await file.exists()) await file.delete();
  }
}
