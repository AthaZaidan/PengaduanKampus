import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'foto_lokal_service.dart';

import '../models/app_user.dart';
import '../models/laporan.dart';

class HasilSinkronisasi {
  final List<Laporan> laporan;
  final bool dariCache;
  const HasilSinkronisasi(this.laporan, {this.dariCache = false});
}

abstract class LaporanRepository {
  String generateId();
  Stream<HasilSinkronisasi> pantau(AppUser user);
  Future<Laporan> tambah(Laporan laporan);
  Future<Laporan?> ubah(
    Laporan sebelumnya,
    bool Function(Laporan) perubahan, {
    List<Uint8List> fotoSesudah = const [],
  });
}

/// Transaksi membaca ulang dokumen server dan menolak revisi yang sudah usang.
/// Foto disalin ke perangkat sebelum transaksi; UI sukses setelah commit server.
class FirebaseLaporanRepository implements LaporanRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _koleksi =>
      _db.collection('laporan');
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  String generateId() => _koleksi.doc().id;

  @override
  Stream<HasilSinkronisasi> pantau(AppUser user) {
    Query<Map<String, dynamic>> query = _koleksi;
    if (user.peran.isTeknisi) {
      query = query.where('teknisiId', isEqualTo: user.uid);
    } else if (!user.peran.isAdmin) {
      query = query.where('pelaporId', isEqualTo: user.uid);
    }
    return query.snapshots(includeMetadataChanges: true).map((snap) {
      final daftar =
          snap.docs.map((d) => Laporan.fromFirestore(d.id, d.data())).toList()
            ..sort((a, b) => b.tanggalLapor.compareTo(a.tanggalLapor));
      return HasilSinkronisasi(daftar, dariCache: snap.metadata.isFromCache);
    });
  }

  Future<List<String>> _simpanFoto(
    Laporan l,
    List<Uint8List> foto,
    String jenis,
  ) async {
    final paths = <String>[];
    try {
      for (final bytes in foto) {
        if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
          throw StateError('Ukuran foto harus di bawah 5 MB.');
        }
        final nama = _koleksi.doc().id;
        final path = 'laporan/${l.pelaporId}/${l.id}/$jenis/$_uid/$nama';
        _mime(bytes);
        await FotoLokalService.instance.simpan(path, bytes);
        paths.add(path);
      }
      return paths;
    } catch (_) {
      await _bersihkan(paths);
      rethrow;
    }
  }

  String _mime(Uint8List b) {
    if (b.length >= 3 && b[0] == 0xff && b[1] == 0xd8 && b[2] == 0xff) {
      return 'image/jpeg';
    }
    if (b.length >= 8 &&
        b[0] == 0x89 &&
        b[1] == 0x50 &&
        b[2] == 0x4e &&
        b[3] == 0x47) {
      return 'image/png';
    }
    if (b.length >= 12 &&
        String.fromCharCodes(b.take(4)) == 'RIFF' &&
        String.fromCharCodes(b.sublist(8, 12)) == 'WEBP') {
      return 'image/webp';
    }
    throw StateError('Gunakan foto JPEG, PNG, atau WebP.');
  }

  Future<void> _bersihkan(List<String> paths) async {
    for (final path in paths) {
      try {
        await FotoLokalService.instance.hapus(path);
      } catch (_) {
        // Pembersihan bersifat best effort; jangan menutupi galat utama.
      }
    }
  }

  @override
  Future<Laporan> tambah(Laporan laporan) async {
    final ref = _koleksi.doc(laporan.id);
    // Retry dari form yang sama memakai id yang sama sehingga tidak menggandakan laporan.
    final sudah = await ref.get(const GetOptions(source: Source.server));
    if (sudah.exists) {
      throw StateError(
        'Laporan ini sudah terkirim. Periksa daftar laporan, lalu hapus draf lama jika masih tampil.',
      );
    }
    final foto = <Uint8List>[...laporan.foto];
    for (final path in laporan.fotoPaths) {
      if (!path.startsWith('draf/$_uid/')) {
        throw StateError('Lampiran draf tidak valid.');
      }
      final bytes = await FotoLokalService.instance.baca(path);
      if (bytes == null) {
        throw StateError(
          'Foto draf tidak ada di perangkat ini. Hapus lampiran yang tidak tersedia atau pilih ulang fotonya.',
        );
      }
      foto.add(bytes);
    }
    if (foto.length > 3) throw StateError('Maksimal tiga foto laporan.');
    final paths = await _simpanFoto(laporan, foto, 'sebelum');
    final data = laporan.toFirestore()
      ..['fotoPaths'] = paths
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp()
      ..['updatedBy'] = _uid;
    (data['riwayat'] as List).last['olehId'] = _uid;
    try {
      final hasil = await _db.runTransaction<Laporan>((tx) async {
        final snap = await tx.get(ref);
        if (snap.exists) {
          throw StateError(
            'Laporan ini sudah terkirim. Periksa daftar laporan terlebih dahulu.',
          );
        }
        tx.set(ref, data);
        return Laporan.fromFirestore(laporan.id, data);
      });
      if (!hasil.fotoPaths.any(paths.contains)) await _bersihkan(paths);
      return hasil;
    } catch (_) {
      // Foto tetap lokal jika respons server terputus.
      rethrow;
    }
  }

  @override
  Future<Laporan?> ubah(
    Laporan sebelumnya,
    bool Function(Laporan) perubahan, {
    List<Uint8List> fotoSesudah = const [],
  }) async {
    if (sebelumnya.fotoSesudahPaths.length + fotoSesudah.length > 3) {
      throw StateError('Maksimal tiga foto hasil penanganan.');
    }
    final paths = await _simpanFoto(sebelumnya, fotoSesudah, 'sesudah');
    try {
      final hasil = await _db.runTransaction<Laporan?>((tx) async {
        final ref = _koleksi.doc(sebelumnya.id);
        final snap = await tx.get(ref);
        if (!snap.exists) return null;
        final terkini = Laporan.fromFirestore(snap.id, snap.data()!);
        if (terkini.revisi != sebelumnya.revisi) {
          throw StateError(
            'Laporan baru saja diubah petugas lain. Periksa status terbaru, lalu coba lagi.',
          );
        }
        if (!perubahan(terkini)) return null;
        terkini.fotoSesudahPaths.addAll(paths);
        final data = terkini.toFirestore()
          ..['revisi'] = terkini.revisi + 1
          ..['updatedAt'] = FieldValue.serverTimestamp()
          ..['updatedBy'] = _uid;
        (data['riwayat'] as List).last['olehId'] = _uid;
        tx.update(ref, data);
        return Laporan.fromFirestore(snap.id, data);
      });
      if (hasil == null) await _bersihkan(paths);
      return hasil;
    } catch (_) {
      // Foto tetap lokal jika respons server terputus.
      rethrow;
    }
  }
}

String pesanGalatFirebase(Object error) {
  if (error is StateError) return error.message;
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
      case 'unauthorized':
        return 'Akses ditolak. Periksa akun dan aturan akses Firebase.';
      case 'unavailable':
      case 'network-request-failed':
      case 'retry-limit-exceeded':
        return 'Belum tersimpan ke server. Periksa koneksi, lalu coba lagi.';
      case 'unauthenticated':
        return 'Sesi berakhir. Silakan masuk kembali.';
      case 'quota-exceeded':
        return 'Penyimpanan sementara tidak tersedia. Hubungi admin kampus.';
    }
  }
  return 'Gagal menyimpan ke Firebase. Silakan coba lagi.';
}
