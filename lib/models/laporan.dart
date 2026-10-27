import 'package:flutter/material.dart';

enum StatusLaporan { menunggu, diproses, selesai, ditolak }

class Laporan {
  final String id;
  final String judul;
  final String deskripsi;
  final String lokasi;
  final KategoriKerusakan kategori;
  final PrioritasLaporan prioritas;
  final String pelapor;
  final DateTime tanggalLapor;
  StatusLaporan status;
  String? catatanAdmin;

  Laporan({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.lokasi,
    required this.kategori,
    required this.prioritas,
    required this.pelapor,
    required this.tanggalLapor,
    this.status = StatusLaporan.menunggu,
    this.catatanAdmin,
  });
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
        return 'Menunggu';
      case StatusLaporan.diproses:
        return 'Diproses';
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
      case StatusLaporan.diproses:
        return Icons.autorenew_rounded;
      case StatusLaporan.selesai:
        return Icons.check_circle_rounded;
      case StatusLaporan.ditolak:
        return Icons.cancel_rounded;
    }
  }
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
