import 'package:flutter/foundation.dart';
import '../models/laporan.dart';

class LaporanProvider extends ChangeNotifier {
  final List<Laporan> _laporanList = [
    Laporan(
      id: 'RPT-001',
      judul: 'AC Kelas 3.2 Tidak Berfungsi',
      deskripsi:
          'AC di ruang kelas 3.2 gedung B sudah tidak berfungsi selama 3 hari. Suhu ruangan sangat panas sehingga mengganggu proses belajar mengajar.',
      lokasi: 'Gedung B - Ruang 3.2',
      kategori: KategoriKerusakan.fasilitas,
      prioritas: PrioritasLaporan.tinggi,
      pelapor: 'Ahmad Fauzi',
      tanggalLapor: DateTime.now().subtract(const Duration(days: 3)),
      status: StatusLaporan.diproses,
    ),
    Laporan(
      id: 'RPT-002',
      judul: 'Toilet Lantai 2 Tersumbat',
      deskripsi:
          'Toilet di lantai 2 gedung A mengalami penyumbatan dan mengeluarkan bau tidak sedap.',
      lokasi: 'Gedung A - Lantai 2',
      kategori: KategoriKerusakan.kebersihan,
      prioritas: PrioritasLaporan.sedang,
      pelapor: 'Siti Rahayu',
      tanggalLapor: DateTime.now().subtract(const Duration(days: 1)),
      status: StatusLaporan.menunggu,
    ),
    Laporan(
      id: 'RPT-003',
      judul: 'Wifi Lab Komputer Putus',
      deskripsi:
          'Koneksi wifi di laboratorium komputer lantai 1 terputus-putus dan sangat lambat sejak semalam.',
      lokasi: 'Gedung C - Lab Komputer Lt.1',
      kategori: KategoriKerusakan.internet,
      prioritas: PrioritasLaporan.tinggi,
      pelapor: 'Budi Santoso',
      tanggalLapor: DateTime.now().subtract(const Duration(hours: 5)),
      status: StatusLaporan.selesai,
      catatanAdmin: 'Router telah diganti dan koneksi sudah normal kembali.',
    ),
  ];

  List<Laporan> get laporanList => List.unmodifiable(_laporanList);

  List<Laporan> get laporanMenunggu =>
      _laporanList.where((l) => l.status == StatusLaporan.menunggu).toList();
  List<Laporan> get laporanDiproses =>
      _laporanList.where((l) => l.status == StatusLaporan.diproses).toList();
  List<Laporan> get laporanSelesai =>
      _laporanList.where((l) => l.status == StatusLaporan.selesai).toList();
  List<Laporan> get laporanDitolak =>
      _laporanList.where((l) => l.status == StatusLaporan.ditolak).toList();

  void tambahLaporan(Laporan laporan) {
    _laporanList.insert(0, laporan);
    notifyListeners();
  }

  void updateStatus(String id, StatusLaporan status, {String? catatan}) {
    final idx = _laporanList.indexWhere((l) => l.id == id);
    if (idx != -1) {
      _laporanList[idx].status = status;
      if (catatan != null) {
        _laporanList[idx].catatanAdmin = catatan;
      }
      notifyListeners();
    }
  }

  String generateId() {
    final nomor = _laporanList.length + 1;
    return 'RPT-${nomor.toString().padLeft(3, '0')}';
  }
}
