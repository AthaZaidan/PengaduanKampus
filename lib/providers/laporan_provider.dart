import 'package:flutter/foundation.dart';
import '../models/laporan.dart';

class LaporanProvider extends ChangeNotifier {
  final List<Laporan> _laporanList = _dataAwal();

  static List<Laporan> _dataAwal() {
    final now = DateTime.now();

    final tgl1 = now.subtract(const Duration(days: 3));
    final tgl2 = now.subtract(const Duration(days: 1));
    final tgl3 = now.subtract(const Duration(hours: 5));

    return [
      Laporan(
        id: 'RPT-001',
        judul: 'AC Kelas 3.2 Tidak Berfungsi',
        deskripsi:
            'AC di ruang kelas 3.2 gedung B sudah tidak berfungsi selama 3 hari. Suhu ruangan sangat panas sehingga mengganggu proses belajar mengajar.',
        lokasi: 'Gedung B - Ruang 3.2',
        kategori: KategoriKerusakan.fasilitas,
        prioritas: PrioritasLaporan.tinggi,
        pelapor: 'Ahmad Fauzi',
        tanggalLapor: tgl1,
        status: StatusLaporan.diproses,
        riwayat: [
          RiwayatStatus(
            status: StatusLaporan.menunggu,
            waktu: tgl1,
            oleh: 'Ahmad Fauzi',
            catatan: 'Laporan dibuat',
          ),
          RiwayatStatus(
            status: StatusLaporan.diproses,
            waktu: now.subtract(const Duration(days: 2)),
            oleh: 'Admin',
            catatan: 'Teknisi akan melakukan pengecekan unit AC.',
          ),
        ],
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
        tanggalLapor: tgl2,
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
        tanggalLapor: tgl3,
        status: StatusLaporan.selesai,
        catatanAdmin: 'Router telah diganti dan koneksi sudah normal kembali.',
        riwayat: [
          RiwayatStatus(
            status: StatusLaporan.menunggu,
            waktu: tgl3,
            oleh: 'Budi Santoso',
            catatan: 'Laporan dibuat',
          ),
          RiwayatStatus(
            status: StatusLaporan.diproses,
            waktu: now.subtract(const Duration(hours: 4)),
            oleh: 'Admin',
            catatan: 'Teknisi jaringan menuju lokasi.',
          ),
          RiwayatStatus(
            status: StatusLaporan.selesai,
            waktu: now.subtract(const Duration(hours: 1)),
            oleh: 'Admin',
            catatan: 'Router telah diganti dan koneksi sudah normal kembali.',
          ),
        ],
      ),
    ];
  }

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

  /// Mengubah status laporan dan mencatatnya ke timeline [Laporan.riwayat].
  ///
  /// [catatan] kosong/null tidak menimpa catatan penanganan yang sudah ada.
  void updateStatus(
    String id,
    StatusLaporan status, {
    String? catatan,
    String oleh = 'Admin',
  }) {
    final idx = _laporanList.indexWhere((l) => l.id == id);
    if (idx == -1) return;

    final laporan = _laporanList[idx];
    if (laporan.status == status) return;

    final catatanBersih = catatan?.trim();
    final adaCatatan = catatanBersih != null && catatanBersih.isNotEmpty;

    laporan.status = status;
    if (adaCatatan) {
      laporan.catatanAdmin = catatanBersih;
    }
    laporan.riwayat.add(
      RiwayatStatus(
        status: status,
        waktu: DateTime.now(),
        oleh: oleh,
        catatan: adaCatatan ? catatanBersih : null,
      ),
    );
    notifyListeners();
  }

  String generateId() {
    final nomor = _laporanList.length + 1;
    return 'RPT-${nomor.toString().padLeft(3, '0')}';
  }
}
