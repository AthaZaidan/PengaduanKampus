
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import 'foto_firestore_service.dart';
import 'foto_lokal_service.dart';

class FiturLaporanService {
  final String uid;

  FiturLaporanService(this.uid);

  FirebaseFirestore get db => FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get draf =>
      db.doc('users/$uid/draf/aktif');

  // Memuat draf laporan
  Future<Map<String, dynamic>?> muatDraf() async {
    final snapshot = await draf.get();
    final data = snapshot.data();

    if (data == null) {
      return null;
    }

    final laporanId = data['laporanId'];

    if (laporanId is String && laporanId.isNotEmpty) {
      try {
        final laporan = await db.doc('laporan/$laporanId').get();

        if (laporan.exists) {
          await hapusDraf(laporanId: laporanId);
          return null;
        }
      } on FirebaseException catch (e) {
        if (e.code != 'unavailable') {
          rethrow;
        }
      }
    }

    return data;
  }

  // Menyimpan draf laporan
  Future<void> simpanDraf(Map<String, dynamic> data) async {
    await draf.set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Menghapus draf beserta foto lokalnya
  Future<void> hapusDraf({String? laporanId}) async {
    final paths = await db.runTransaction<List<String>>((tx) async {
      final snapshot = await tx.get(draf);
      final data = snapshot.data();

      if (data == null ||
          (laporanId != null && data['laporanId'] != laporanId)) {
        return [];
      }

      tx.delete(draf);

      return List<String>.from(
        data['fotoPaths'] as List? ?? [],
      );
    });

    for (final path in paths) {
      try {
        await hapusFotoDraf(path);
      } catch (_) {
        // Penghapusan foto gagal, tetapi proses tetap berjalan.
      }
    }
  }

  // Menghapus foto draf
  Future<void> hapusFotoDraf(String path) {
    return FotoLokalService.instance.hapus(path);
  }

  // Menyimpan foto draf
  Future<String> simpanFotoDraf(Uint8List bytes) async {
    FotoFirestoreService.validasi(bytes);

    final path = 'draf/$uid/${db.collection('laporan').doc().id}';

    await FotoLokalService.instance.simpan(path, bytes);

    return path;
  }

  // Mengambil komentar laporan
  Stream<QuerySnapshot<Map<String, dynamic>>> komentar(String id) {
    return db
        .collection('laporan/$id/komentar')
        .orderBy('createdAt')
        .limitToLast(100)
        .snapshots();
  }

  // Mengirim komentar
  Future<void> kirimKomentar(
    String id,
    AppUser user,
    String teks,
  ) async {
    final bersih = teks.trim();

    if (bersih.isEmpty || bersih.length > 2000) {
      throw StateError(
        'Komentar harus berisi 1–2000 karakter.',
      );
    }

    await db.collection('laporan/$id/komentar').add({
      'uid': user.uid,
      'nama': user.nama,
      'role': user.peran.name,
      'teks': bersih,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Mengambil daftar laporan/notifikasi yang sudah dibaca
  Stream<Set<String>> dibaca() {
    return db
        .collection('users/$uid/dibaca')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toSet();
    });
  }

  // Menandai laporan/notifikasi sebagai sudah dibaca
  Future<void> tandaiDibaca(Iterable<String> ids) async {
    final daftar = ids.toSet().toList();

    for (var i = 0; i < daftar.length; i += 400) {
      final batch = db.batch();

      for (final id in daftar.skip(i).take(400)) {
        batch.set(
          db.doc('users/$uid/dibaca/$id'),
          {
            'waktu': FieldValue.serverTimestamp(),
          },
        );
      }

      await batch.commit();
    }
  }

  // Mengambil daftar notifikasi yang sudah dihapus oleh user
  Stream<Set<String>> dihapus() {
    return db
        .collection('users/$uid/notif_dihapus')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toSet();
    });
  }

  // Menyimpan ID notifikasi yang dihapus oleh user
  Future<void> hapusNotifikasi(Iterable<String> ids) async {
    final daftar = ids.toSet().toList();

    if (daftar.isEmpty) return;

    for (var i = 0; i < daftar.length; i += 400) {
      final batch = db.batch();

      for (final id in daftar.skip(i).take(400)) {
        batch.set(
          db.doc('users/$uid/notif_dihapus/$id'),
          {
            'dihapusPada': FieldValue.serverTimestamp(),
          },
        );
      }

      await batch.commit();
    }
  }
}
