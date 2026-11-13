import 'dart:typed_data';

import 'package:flutter/material.dart';

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
  final String? catatan;

  const RiwayatStatus({
    required this.status,
    required this.waktu,
    required this.oleh,
    this.catatan,
  });
}

class Laporan {
  final String id;
  final String judul;
  final String deskripsi;
  final String lokasi;
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

  /// Timeline perubahan status, urut dari yang paling lama ke terbaru.
  final List<RiwayatStatus> riwayat;

  Laporan({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.lokasi,
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
    List<RiwayatStatus>? riwayat,
  })  : foto = foto ?? const [],
        fotoSesudah = fotoSesudah ?? <Uint8List>[],
        riwayat = riwayat ??
            [
              RiwayatStatus(
                status: status,
                waktu: tanggalLapor,
                oleh: pelapor,
                catatan: 'Laporan dibuat',
              ),
            ];

  /// Batas waktu penyelesaian (SLA) berdasarkan prioritas.
  DateTime get batasSla => tanggalLapor.add(prioritas.targetSla);

  /// Waktu laporan dinyatakan selesai (null bila belum selesai).
  DateTime? get waktuSelesai {
    DateTime? hasil;
    for (final r in riwayat) {
      if (r.status == StatusLaporan.selesai) hasil = r.waktu;
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
        return const Color(0xFFF59E0B);
      case StatusLaporan.diverifikasi:
        return const Color(0xFF8B5CF6);
      case StatusLaporan.ditugaskan:
        return const Color(0xFF06B6D4);
      case StatusLaporan.diproses:
        return const Color(0xFF3B82F6);
      case StatusLaporan.selesai:
        return const Color(0xFF10B981);
      case StatusLaporan.ditolak:
        return const Color(0xFFEF4444);
    }
  }

  IconData get icon {
    switch (this) {
      case StatusLaporan.menunggu:
        return Icons.hourglass_empty_rounded;
      case StatusLaporan.diverifikasi:
        return Icons.verified_rounded;
      case StatusLaporan.ditugaskan:
        return Icons.assignment_ind_rounded;
      case StatusLaporan.diproses:
        return Icons.autorenew_rounded;
      case StatusLaporan.selesai:
        return Icons.check_circle_rounded;
      case StatusLaporan.ditolak:
        return Icons.cancel_rounded;
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
        return Icons.chair_alt_rounded;
      case KategoriKerusakan.listrik:
        return Icons.bolt_rounded;
      case KategoriKerusakan.airBersih:
        return Icons.water_drop_rounded;
      case KategoriKerusakan.internet:
        return Icons.wifi_rounded;
      case KategoriKerusakan.kebersihan:
        return Icons.cleaning_services_rounded;
      case KategoriKerusakan.lainnya:
        return Icons.more_horiz_rounded;
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

  Color get color {
    switch (this) {
      case PrioritasLaporan.rendah:
        return const Color(0xFF6B7280);
      case PrioritasLaporan.sedang:
        return const Color(0xFFF59E0B);
      case PrioritasLaporan.tinggi:
        return const Color(0xFFEF4444);
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
