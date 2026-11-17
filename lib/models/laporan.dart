import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Alur: dilaporkan (menunggu) -> terverifikasi -> ditugaskan -> dikerjakan
/// (diproses) -> selesai. Laporan yang tidak valid berakhir sebagai ditolak.
enum StatusLaporan {
  menunggu,
  diverifikasi,
  ditugaskan,
  diproses,
  selesai,
  ditolak,
}

/// Satu entri pada timeline perubahan status sebuah laporan.
class RiwayatStatus {
  final StatusLaporan status;
  final DateTime waktu;
  final String oleh;
  final String? olehId;
  final String? catatan;

  const RiwayatStatus({
    required this.status,
    required this.waktu,
    required this.oleh,
    this.olehId,
    this.catatan,
  });
}

class Laporan {
  final String id;
  final String judul;
  final String deskripsi;
  final String lokasi;
  bool dikonfirmasi;
  final KategoriKerusakan kategori;
  final PrioritasLaporan prioritas;
  final String pelapor;

  /// uid pelapor (Firebase Auth). Null untuk data contoh.
  final String? pelaporId;
  final DateTime tanggalLapor;
  StatusLaporan status;
  String? catatanAdmin;

  /// Teknisi yang ditugaskan (diisi admin saat status ditugaskan).
  String? teknisiId;
  String? teknisiNama;

  /// Foto lampiran pelapor = foto SEBELUM penanganan.
  final List<Uint8List> foto;

  /// Foto SESUDAH penanganan (diunggah teknisi saat menyelesaikan).
  final List<Uint8List> fotoSesudah;

  /// Path privat di Storage; gambar tidak dimasukkan ke dokumen Firestore.
  final List<String> fotoPaths;
  final List<String> fotoSesudahPaths;
  final int revisi;

  /// Timeline perubahan status, urut dari yang paling lama ke terbaru.
  final List<RiwayatStatus> riwayat;

  Laporan({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.lokasi,
    this.dikonfirmasi = false,
    required this.kategori,
    required this.prioritas,
    required this.pelapor,
    required this.tanggalLapor,
    this.pelaporId,
    this.status = StatusLaporan.menunggu,
    this.catatanAdmin,
    this.teknisiId,
    this.teknisiNama,
    List<Uint8List>? foto,
    List<Uint8List>? fotoSesudah,
    List<String>? fotoPaths,
    List<String>? fotoSesudahPaths,
    this.revisi = 0,
    List<RiwayatStatus>? riwayat,
  }) : foto = foto ?? const [],
       fotoPaths = fotoPaths ?? <String>[],
       fotoSesudahPaths = fotoSesudahPaths ?? <String>[],
       fotoSesudah = fotoSesudah ?? <Uint8List>[],
       riwayat =
           riwayat ??
           [
             RiwayatStatus(
               status: status,
               waktu: tanggalLapor,
               oleh: pelapor,
               catatan: 'Laporan dibuat',
             ),
           ];

  int get jumlahFoto => foto.length + fotoPaths.length;
  int get jumlahFotoSesudah => fotoSesudah.length + fotoSesudahPaths.length;

  Map<String, dynamic> toFirestore() => {
    'judul': judul,
    'deskripsi': deskripsi,
    'lokasi': lokasi,
    'dikonfirmasi': dikonfirmasi,
    'kategori': kategori.name,
    'prioritas': prioritas.name,
    'pelapor': pelapor,
    'pelaporId': pelaporId,
    'tanggalLapor': Timestamp.fromDate(tanggalLapor),
    'status': status.name,
    'catatanAdmin': catatanAdmin,
    'teknisiId': teknisiId,
    'teknisiNama': teknisiNama,
    'fotoPaths': fotoPaths,
    'fotoSesudahPaths': fotoSesudahPaths,
    'revisi': revisi,
    'riwayat': riwayat
        .map(
          (r) => {
            'status': r.status.name,
            'waktu': Timestamp.fromDate(r.waktu),
            'oleh': r.oleh,
            'olehId': r.olehId,
            'catatan': r.catatan,
          },
        )
        .toList(),
  };

  factory Laporan.fromFirestore(String id, Map<String, dynamic> data) {
    return Laporan(
      id: id,
      judul: data['judul'] as String,
      deskripsi: data['deskripsi'] as String,
      lokasi: data['lokasi'] as String,
      dikonfirmasi: data['dikonfirmasi'] as bool? ?? false,
      kategori: KategoriKerusakan.values.byName(data['kategori'] as String),
      prioritas: PrioritasLaporan.values.byName(data['prioritas'] as String),
      pelapor: data['pelapor'] as String,
      pelaporId: data['pelaporId'] as String?,
      tanggalLapor: (data['tanggalLapor'] as Timestamp).toDate(),
      status: StatusLaporan.values.byName(data['status'] as String),
      catatanAdmin: data['catatanAdmin'] as String?,
      teknisiId: data['teknisiId'] as String?,
      teknisiNama: data['teknisiNama'] as String?,
      fotoPaths: List<String>.from(data['fotoPaths'] as List? ?? []),
      fotoSesudahPaths: List<String>.from(
        data['fotoSesudahPaths'] as List? ?? [],
      ),
      revisi: data['revisi'] as int? ?? 0,
      riwayat: (data['riwayat'] as List).map((item) {
        final r = Map<String, dynamic>.from(item as Map);
        return RiwayatStatus(
          status: StatusLaporan.values.byName(r['status'] as String),
          waktu: (r['waktu'] as Timestamp).toDate(),
          oleh: r['oleh'] as String,
          olehId: r['olehId'] as String?,
          catatan: r['catatan'] as String?,
        );
      }).toList(),
    );
  }

  /// Batas waktu penyelesaian (SLA) berdasarkan prioritas.
  DateTime get batasSla => tanggalLapor.add(prioritas.targetSla);

  /// Waktu laporan dinyatakan selesai (null bila belum selesai).
  DateTime? get waktuSelesai {
    DateTime? hasil;
    StatusLaporan? sebelumnya;
    for (final r in riwayat) {
      if (r.status == StatusLaporan.selesai &&
          sebelumnya != StatusLaporan.selesai) {
        hasil = r.waktu;
      }
      sebelumnya = r.status;
    }
    return hasil;
  }

  /// Aktif = belum selesai dan belum ditolak.
  bool get aktif => status.aktif;

  /// True bila laporan aktif sudah lewat SLA, atau selesai setelah SLA.
  bool get melewatiSla {
    if (status == StatusLaporan.ditolak) return false;
    if (aktif) return DateTime.now().isAfter(batasSla);
    final selesai = waktuSelesai;
    return selesai != null && selesai.isAfter(batasSla);
  }
}

enum KategoriKerusakan {
  fasilitas,
  listrik,
  airBersih,
  internet,
  kebersihan,
  lainnya,
}

enum PrioritasLaporan { rendah, sedang, tinggi }

extension StatusLaporanExt on StatusLaporan {
  String get label {
    switch (this) {
      case StatusLaporan.menunggu:
        return 'Dilaporkan';
      case StatusLaporan.diverifikasi:
        return 'Terverifikasi';
      case StatusLaporan.ditugaskan:
        return 'Ditugaskan';
      case StatusLaporan.diproses:
        return 'Dikerjakan';
      case StatusLaporan.selesai:
        return 'Selesai';
      case StatusLaporan.ditolak:
        return 'Ditolak';
    }
  }

  Color get color {
    switch (this) {
      case StatusLaporan.menunggu:
        return AppColors.statusMenunggu;
      case StatusLaporan.diverifikasi:
        return AppColors.statusDiverifikasi;
      case StatusLaporan.ditugaskan:
        return AppColors.statusDitugaskan;
      case StatusLaporan.diproses:
        return AppColors.statusDiproses;
      case StatusLaporan.selesai:
        return AppColors.statusSelesai;
      case StatusLaporan.ditolak:
        return AppColors.statusDitolak;
    }
  }

  /// Warna latar status dari API model main; tidak memengaruhi data Firestore.
  Color get backgroundColor => switch (this) {
    StatusLaporan.menunggu => AppColors.statusMenungguBg,
    StatusLaporan.diverifikasi => AppColors.statusDiverifikasiBg,
    StatusLaporan.ditugaskan => AppColors.statusDitugaskanBg,
    StatusLaporan.diproses => AppColors.statusDiprosesBg,
    StatusLaporan.selesai => AppColors.statusSelesaiBg,
    StatusLaporan.ditolak => AppColors.statusDitolakBg,
  };

  IconData get icon {
    switch (this) {
      case StatusLaporan.menunggu:
        return Icons.hourglass_empty;
      case StatusLaporan.diverifikasi:
        return Icons.verified_outlined;
      case StatusLaporan.ditugaskan:
        return Icons.assignment_ind_outlined;
      case StatusLaporan.diproses:
        return Icons.sync_outlined;
      case StatusLaporan.selesai:
        return Icons.check_circle_outline;
      case StatusLaporan.ditolak:
        return Icons.cancel_outlined;
    }
  }

  /// Masih dalam proses (belum selesai / ditolak).
  bool get aktif =>
      this != StatusLaporan.selesai && this != StatusLaporan.ditolak;
}

extension KategoriExt on KategoriKerusakan {
  String get label {
    switch (this) {
      case KategoriKerusakan.fasilitas:
        return 'Fasilitas';
      case KategoriKerusakan.listrik:
        return 'Listrik';
      case KategoriKerusakan.airBersih:
        return 'Air Bersih';
      case KategoriKerusakan.internet:
        return 'Internet / Wifi';
      case KategoriKerusakan.kebersihan:
        return 'Kebersihan';
      case KategoriKerusakan.lainnya:
        return 'Lainnya';
    }
  }

  IconData get icon {
    switch (this) {
      case KategoriKerusakan.fasilitas:
        return Icons.chair_alt_outlined;
      case KategoriKerusakan.listrik:
        return Icons.bolt_outlined;
      case KategoriKerusakan.airBersih:
        return Icons.water_drop_outlined;
      case KategoriKerusakan.internet:
        return Icons.wifi_outlined;
      case KategoriKerusakan.kebersihan:
        return Icons.cleaning_services_outlined;
      case KategoriKerusakan.lainnya:
        return Icons.more_horiz;
    }
  }
}

extension PrioritasExt on PrioritasLaporan {
  String get label {
    switch (this) {
      case PrioritasLaporan.rendah:
        return 'Rendah';
      case PrioritasLaporan.sedang:
        return 'Sedang';
      case PrioritasLaporan.tinggi:
        return 'Tinggi';
    }
  }

  Color get backgroundColor => switch (this) {
    PrioritasLaporan.rendah => const Color(0xFFF1F3F5),
    PrioritasLaporan.sedang => AppColors.statusMenungguBg,
    PrioritasLaporan.tinggi => AppColors.statusDitolakBg,
  };

  Color get color {
    switch (this) {
      case PrioritasLaporan.rendah:
        return const Color(0xFF6B7280);
      case PrioritasLaporan.sedang:
        return AppColors.statusMenunggu;
      case PrioritasLaporan.tinggi:
        return AppColors.statusDitolak;
    }
  }
}

/// Target waktu penyelesaian (SLA) per prioritas.
extension PrioritasSla on PrioritasLaporan {
  Duration get targetSla {
    switch (this) {
      case PrioritasLaporan.tinggi:
        return const Duration(hours: 24);
      case PrioritasLaporan.sedang:
        return const Duration(hours: 72);
      case PrioritasLaporan.rendah:
        return const Duration(days: 7);
    }
  }
}
