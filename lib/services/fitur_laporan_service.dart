import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'foto_firestore_service.dart';
import 'foto_lokal_service.dart';

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
      FotoLokalService.instance.hapus(path);

  Future<String> simpanFotoDraf(Uint8List bytes) async {
    // Diperiksa sejak dipilih agar foto yang terlalu besar ditolak lebih awal.
    FotoFirestoreService.validasi(bytes);
    final path = 'draf/$uid/${db.collection('laporan').doc().id}';
    await FotoLokalService.instance.simpan(path, bytes);
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
