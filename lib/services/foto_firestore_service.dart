import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Foto laporan disimpan di Firestore sebagai teks base64, pada subkoleksi
/// `laporan/{id}/foto/{fotoId}`. Dokumen laporan hanya memuat path rujukan
/// (`laporan/{pemilik}/{id}/{jenis}/{uploader}/{fotoId}`), sehingga daftar
/// laporan tetap ringan dan satu foto tidak melewati batas 1 MB per dokumen.
class FotoFirestoreService {
  static final instance = FotoFirestoreService();

  /// Pengaturan kompresi yang dipakai image_picker agar hasil base64 muat
  /// dalam satu dokumen Firestore.
  static const int lebarMaks = 1024;
  static const int kualitas = 60;

  /// Batas biner foto. Base64 membengkak ±33%, sedangkan satu dokumen
  /// Firestore dibatasi 1 MiB.
  static const int batasBytes = 700 * 1024;

  static final _pola = RegExp(r'^laporan/([^/]+)/([^/]+)/(sebelum|sesudah)/([^/]+)/([^/]+)$');
  final Map<String, Uint8List> _cache = {};

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Memastikan berkas adalah JPEG/PNG/WebP dan tidak melebihi batas.
  static String validasi(Uint8List b) {
    if (b.isEmpty) throw StateError('Foto kosong. Pilih foto lain.');
    if (b.length > batasBytes) {
      throw StateError(
        'Ukuran foto terlalu besar (maks. ${batasBytes ~/ 1024} KB setelah dikompres). Pilih foto lain.',
      );
    }
    if (b.length >= 3 && b[0] == 0xff && b[1] == 0xd8 && b[2] == 0xff) {
      return 'image/jpeg';
    }
    if (b.length >= 8 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4e && b[3] == 0x47) {
      return 'image/png';
    }
    if (b.length >= 12 &&
        String.fromCharCodes(b.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(b.sublist(8, 12)) == 'WEBP') {
      return 'image/webp';
    }
    throw StateError('Gunakan foto JPEG, PNG, atau WebP.');
  }

  static bool adalahPathFirestore(String path) => _pola.hasMatch(path);

  DocumentReference<Map<String, dynamic>> _ref(String path) {
    final m = _pola.firstMatch(path);
    if (m == null) throw StateError('Lokasi foto tidak valid.');
    return _db.doc('laporan/${m.group(2)}/foto/${m.group(5)}');
  }

  /// Mengubah foto menjadi base64 lalu menyimpannya ke Firestore.
  Future<void> simpan(String path, Uint8List bytes, {required String uploaderId}) async {
    final mime = validasi(bytes);
    final m = _pola.firstMatch(path);
    if (m == null) throw StateError('Lokasi foto tidak valid.');
    await _ref(path).set({
      'data': base64Encode(bytes),
      'mime': mime,
      'jenis': m.group(3),
      'pemilikId': m.group(1),
      'uploaderId': uploaderId,
      'ukuran': bytes.length,
      'createdAt': FieldValue.serverTimestamp(),
    });
    _cache[path] = bytes;
  }

  /// Mengambil foto dari Firestore dan mengubah base64 kembali menjadi gambar.
  Future<Uint8List?> baca(String path) async {
    final cache = _cache[path];
    if (cache != null) return cache;
    final snap = await _ref(path).get();
    final data = snap.data()?['data'];
    if (data is! String || data.isEmpty) return null;
    final bytes = base64Decode(data);
    _cache[path] = bytes;
    return bytes;
  }

  Future<void> hapus(String path) async {
    _cache.remove(path);
    await _ref(path).delete();
  }
}
