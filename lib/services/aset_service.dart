import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/aset_kampus.dart';

/// Layanan untuk mengambil master data aset dari Firestore atau parse kode QR.
class AsetService {
  final FirebaseFirestore? _firestore;

  AsetService({FirebaseFirestore? db}) : _firestore = db;

  FirebaseFirestore? get _db {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Mencari data aset berdasarkan kode QR:
  /// 1. Cek di koleksi Firestore `assets/{kode}` (bila Firebase aktif).
  /// 2. Jika tidak ada atau offline/gagal, parse kode QR secara cerdas.
  Future<AsetKampus> cariAset(String kodeQr) async {
    final cleanKode = kodeQr.trim();
    if (cleanKode.isEmpty) {
      return const AsetKampus(
        kode: '',
        nama: 'Aset tidak dikenal',
        lokasi: 'Lokasi kampus',
      );
    }

    final db = _db;
    if (db != null) {
      try {
        final doc = await db.collection('assets').doc(cleanKode).get();
        if (doc.exists && doc.data() != null) {
          return AsetKampus.fromFirestore(doc.id, doc.data()!);
        }
      } catch (_) {
        // Abaikan error jaringan/permission dan gunakan parser offline
      }
    }

    return AsetKampus.dariKodeMentah(cleanKode);
  }

  /// Menambahkan atau memperbarui data aset di Firestore (untuk Admin).
  Future<void> simpanAset(AsetKampus aset) async {
    final db = _db;
    if (db == null) return;
    await db
        .collection('assets')
        .doc(aset.kode)
        .set(aset.toFirestore(), SetOptions(merge: true));
  }

  /// Aliran data seluruh aset dari Firestore untuk antarmuka admin.
  Stream<List<AsetKampus>> streamSemuaAset() {
    final db = _db;
    if (db == null) return const Stream.empty();
    return db
        .collection('assets')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AsetKampus.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }

  /// Menghapus data aset dari Firestore.
  Future<void> hapusAset(String kode) async {
    final db = _db;
    if (db == null) return;
    await db.collection('assets').doc(kode).delete();
  }
}
