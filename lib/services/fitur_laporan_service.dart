import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/app_user.dart';

class FiturLaporanService {
  final String uid;
  FiturLaporanService(this.uid);
  FirebaseFirestore get db => FirebaseFirestore.instance;
  DocumentReference<Map<String, dynamic>> get draf =>
      db.doc('users/$uid/draf/aktif');
  Future<Map<String, dynamic>?> muatDraf() async {
    final data = (await draf.get()).data();
    if (data != null) {
      try {
        final laporan = await db
            .doc('laporan/${data['laporanId'] as String}')
            .get();
        if (laporan.exists) {
          await hapusDraf(laporanId: data['laporanId'] as String);
          return null;
        }
      } on FirebaseException catch (e) {
        if (e.code != 'unavailable') rethrow;
        // Draf cache tetap dapat dibuka; pengiriman resmi tetap memerlukan server.
      }
    }
    return data;
  }

  Future<void> simpanDraf(Map<String, dynamic> data) =>
      draf.set({...data, 'updatedAt': FieldValue.serverTimestamp()});
  Future<void> hapusDraf({String? laporanId}) async {
    final paths = await db.runTransaction<List<String>>((tx) async {
      final data = (await tx.get(draf)).data();
      if (data == null ||
          (laporanId != null && data['laporanId'] != laporanId)) {
        return [];
      }
      tx.delete(draf);
      return List<String>.from(data['fotoPaths'] as List? ?? []);
    });
    for (final path in paths) {
      try {
        await hapusFotoDraf(path);
      } catch (_) {
        /* Pembersihan dapat diulang; laporan sudah tersimpan. */
      }
    }
  }

  Future<void> hapusFotoDraf(String path) =>
      FirebaseStorage.instance.ref(path).delete();

  Future<String> uploadDraf(Uint8List bytes) async {
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      throw StateError('Foto maksimal 5 MB.');
    }
    final png = bytes.length > 4 && bytes[0] == 137 && bytes[1] == 80;
    final jpg = bytes.length > 3 && bytes[0] == 255 && bytes[1] == 216;
    final webp =
        bytes.length > 12 &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP';
    if (!png && !jpg && !webp) {
      throw StateError('Gunakan foto JPEG, PNG, atau WebP.');
    }
    final path = 'draf/$uid/${db.collection('laporan').doc().id}';
    await FirebaseStorage.instance
        .ref(path)
        .putData(
          bytes,
          SettableMetadata(
            contentType: png
                ? 'image/png'
                : jpg
                ? 'image/jpeg'
                : 'image/webp',
          ),
        );
    return path;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> komentar(String id) => db
      .collection('laporan/$id/komentar')
      .orderBy('createdAt')
      .limitToLast(100)
      .snapshots();
  Future<void> kirimKomentar(String id, AppUser user, String teks) async {
    final bersih = teks.trim();
    if (bersih.isEmpty || bersih.length > 2000) {
      throw StateError('Komentar harus berisi 1–2000 karakter.');
    }
    await db.collection('laporan/$id/komentar').add({
      'uid': user.uid,
      'nama': user.nama,
      'teks': bersih,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<Set<String>> dibaca() => db
      .collection('users/$uid/dibaca')
      .snapshots()
      .map((s) => s.docs.map((d) => d.id).toSet());
  Future<void> tandaiDibaca(Iterable<String> ids) async {
    final daftar = ids.toList();
    for (var i = 0; i < daftar.length; i += 400) {
      final batch = db.batch();
      for (final id in daftar.skip(i).take(400)) {
        batch.set(db.doc('users/$uid/dibaca/$id'), {
          'waktu': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }
}
