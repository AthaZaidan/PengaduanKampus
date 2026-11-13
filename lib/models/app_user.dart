import 'package:flutter/material.dart';

/// Peran pengguna. Mahasiswa, dosen, dan staf memakai hak akses yang sama
/// (pelapor); admin fasilitas dan teknisi punya hak akses sendiri.
enum PeranPengguna { mahasiswa, dosen, staf, admin, teknisi }

extension PeranPenggunaExt on PeranPengguna {
  /// Nilai yang disimpan di field `role` pada Firestore (users/{uid}).
  String get kode {
    switch (this) {
      case PeranPengguna.mahasiswa:
        return 'mahasiswa';
      case PeranPengguna.dosen:
        return 'dosen';
      case PeranPengguna.staf:
        return 'staf';
      case PeranPengguna.admin:
        return 'admin';
      case PeranPengguna.teknisi:
        return 'teknisi';
    }
  }

  String get label {
    switch (this) {
      case PeranPengguna.mahasiswa:
        return 'Mahasiswa';
      case PeranPengguna.dosen:
        return 'Dosen';
      case PeranPengguna.staf:
        return 'Staf';
      case PeranPengguna.admin:
        return 'Admin Fasilitas';
      case PeranPengguna.teknisi:
        return 'Teknisi';
    }
  }

  IconData get icon {
    switch (this) {
      case PeranPengguna.mahasiswa:
        return Icons.school_outlined;
      case PeranPengguna.dosen:
        return Icons.co_present_outlined;
      case PeranPengguna.staf:
        return Icons.badge_outlined;
      case PeranPengguna.admin:
        return Icons.admin_panel_settings_outlined;
      case PeranPengguna.teknisi:
        return Icons.engineering_outlined;
    }
  }

  bool get isPelapor =>
      this == PeranPengguna.mahasiswa ||
      this == PeranPengguna.dosen ||
      this == PeranPengguna.staf;
  bool get isAdmin => this == PeranPengguna.admin;
  bool get isTeknisi => this == PeranPengguna.teknisi;

  /// Warna aksen tampilan untuk peran ini.
  Color get warna {
    if (isAdmin) return const Color(0xFF5E35B1);
    if (isTeknisi) return const Color(0xFF00796B);
    return const Color(0xFF1565C0);
  }
}

class AppUser {
  final String uid;
  final String nama;
  final String email;
  final String? nim;
  final String? telepon;
  final PeranPengguna peran;

  const AppUser({
    required this.uid,
    required this.nama,
    required this.email,
    required this.peran,
    this.nim,
    this.telepon,
  });

  AppUser copyWith({String? nama, PeranPengguna? peran}) {
    return AppUser(
      uid: uid,
      nama: nama ?? this.nama,
      email: email,
      nim: nim,
      telepon: telepon,
      peran: peran ?? this.peran,
    );
  }

  /// Mengubah nilai `role` dari Firestore menjadi [PeranPengguna].
  /// Nilai lama `student` (dan nilai tak dikenal) dianggap mahasiswa.
  static PeranPengguna peranDariKode(String? kode) {
    switch ((kode ?? '').trim().toLowerCase()) {
      case 'admin':
      case 'admin_fasilitas':
      case 'admin fasilitas':
        return PeranPengguna.admin;
      case 'teknisi':
        return PeranPengguna.teknisi;
      case 'dosen':
        return PeranPengguna.dosen;
      case 'staf':
      case 'staff':
        return PeranPengguna.staf;
      default:
        return PeranPengguna.mahasiswa;
    }
  }

  /// Membangun [AppUser] dari dokumen `users/{uid}`; [namaAuth] / [emailAuth]
  /// dipakai bila field di Firestore kosong.
  factory AppUser.dariData({
    required String uid,
    required Map<String, dynamic> data,
    String? namaAuth,
    String? emailAuth,
  }) {
    String? bersih(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return (s.isEmpty || s == '-') ? null : s;
    }

    return AppUser(
      uid: uid,
      nama: bersih(data['name']) ?? bersih(namaAuth) ?? 'Pengguna',
      email: bersih(data['email']) ?? bersih(emailAuth) ?? '-',
      nim: bersih(data['nim']),
      telepon: bersih(data['phone']),
      peran: peranDariKode(data['role']?.toString()),
    );
  }
}
