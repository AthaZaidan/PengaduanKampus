import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/app_user.dart';

/// Pembuatan akun oleh admin.
///
/// `createUserWithEmailAndPassword` otomatis me-login akun yang baru dibuat,
/// sehingga admin akan ikut "keluar" bila dipanggil pada instance Firebase
/// utama. Karena itu akun dibuat lewat instance Firebase *sekunder*; sesi
/// admin pada instance utama tidak tersentuh.
class AkunService {
  AkunService._();

  static const _namaAppSekunder = 'pembuat-akun';

  static Future<FirebaseApp> _appSekunder() async {
    for (final app in Firebase.apps) {
      if (app.name == _namaAppSekunder) return app;
    }
    return Firebase.initializeApp(
      name: _namaAppSekunder,
      options: Firebase.app().options,
    );
  }

  /// Membuat akun Firebase Auth + dokumen `users/{uid}` dengan role `teknisi`.
  /// Mengembalikan uid akun baru.
  ///
  /// Dokumen Firestore ditulis memakai sesi admin (instance utama). Jika
  /// penulisan gagal, akun Auth yang baru dibuat dihapus lagi supaya tidak
  /// ada akun "yatim" tanpa data peran.
  ///
  /// Melempar [FirebaseAuthException] (mis. `email-already-in-use`) atau
  /// [FirebaseException] (mis. `permission-denied` dari Firestore Rules).
  static Future<String> buatAkunTeknisi({
    required AppUser pembuat,
    required String nama,
    required String email,
    required String telepon,
    required String password,
  }) async {
    if (!pembuat.peran.isAdmin) {
      throw StateError('Hanya admin yang dapat membuat akun teknisi.');
    }

    final authSekunder = FirebaseAuth.instanceFor(app: await _appSekunder());
    try {
      final cred = await authSekunder.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final baru = cred.user;
      if (baru == null) throw StateError('Akun gagal dibuat.');

      try {
        await baru.updateDisplayName(nama);
        await FirebaseFirestore.instance.collection('users').doc(baru.uid).set({
          'uid': baru.uid,
          'name': nama,
          'nim': '-',
          'email': email,
          'phone': telepon,
          'role': PeranPengguna.teknisi.kode,
          'createdBy': pembuat.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        try {
          await baru.delete();
        } catch (_) {
          // Penghapusan gagal: akun Auth tersisa, bisa dihapus manual di
          // Firebase Console.
        }
        rethrow;
      }
      return baru.uid;
    } finally {
      await authSekunder.signOut();
    }
  }
}
