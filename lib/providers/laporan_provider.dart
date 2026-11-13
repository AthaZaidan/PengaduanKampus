import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../models/laporan.dart';

class LaporanProvider extends ChangeNotifier {
  /// Instance bersama untuk seluruh aplikasi, supaya data tidak hilang saat
  /// pengguna berganti akun / peran dalam satu sesi.
  static final LaporanProvider shared = LaporanProvider();

  final List<Laporan> _laporanList = _dataAwal();

  static List<Laporan> _dataAwal() {
    final now = DateTime.now();

    final tgl1 = now.subtract(const Duration(days: 3));
    final tgl2 = now.subtract(const Duration(days: 1));
    final tgl3 = now.subtract(const Duration(hours: 5));
    final tgl4 = now.subtract(const Duration(days: 2));

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
        teknisiNama: 'Pak Rudi',
        riwayat: [
          RiwayatStatus(
            status: StatusLaporan.menunggu,
            waktu: tgl1,
            oleh: 'Ahmad Fauzi',
            catatan: 'Laporan dibuat',
          ),
          RiwayatStatus(
            status: StatusLaporan.diverifikasi,
            waktu: now.subtract(const Duration(days: 2, hours: 20)),
            oleh: 'Admin',
            catatan: 'Laporan dinyatakan valid.',
          ),
          RiwayatStatus(
            status: StatusLaporan.ditugaskan,
            waktu: now.subtract(const Duration(days: 2, hours: 18)),
            oleh: 'Admin',
            catatan: 'Ditugaskan kepada Pak Rudi.',
          ),
          RiwayatStatus(
            status: StatusLaporan.diproses,
            waktu: now.subtract(const Duration(days: 2)),
            oleh: 'Pak Rudi',
            catatan: 'Teknisi mulai mengerjakan.',
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
        teknisiNama: 'Pak Rudi',
        riwayat: [
          RiwayatStatus(
            status: StatusLaporan.menunggu,
            waktu: tgl3,
            oleh: 'Budi Santoso',
            catatan: 'Laporan dibuat',
          ),
          RiwayatStatus(
            status: StatusLaporan.diverifikasi,
            waktu: now.subtract(const Duration(hours: 4, minutes: 40)),
            oleh: 'Admin',
            catatan: 'Laporan dinyatakan valid.',
          ),
          RiwayatStatus(
            status: StatusLaporan.ditugaskan,
            waktu: now.subtract(const Duration(hours: 4, minutes: 20)),
            oleh: 'Admin',
            catatan: 'Ditugaskan kepada Pak Rudi.',
          ),
          RiwayatStatus(
            status: StatusLaporan.diproses,
            waktu: now.subtract(const Duration(hours: 3)),
            oleh: 'Pak Rudi',
            catatan: 'Teknisi jaringan menuju lokasi.',
          ),
          RiwayatStatus(
            status: StatusLaporan.selesai,
            waktu: now.subtract(const Duration(hours: 1)),
            oleh: 'Pak Rudi',
            catatan: 'Router telah diganti dan koneksi sudah normal kembali.',
          ),
        ],
      ),
      Laporan(
        id: 'RPT-004',
        judul: 'Lampu Koridor Gedung A Mati',
        deskripsi:
            'Tiga lampu di koridor lantai 1 gedung A mati sehingga area tersebut gelap pada sore hari.',
        lokasi: 'Gedung A - Koridor Lt.1',
        kategori: KategoriKerusakan.listrik,
        prioritas: PrioritasLaporan.rendah,
        pelapor: 'Dewi Lestari',
        tanggalLapor: tgl4,
        status: StatusLaporan.diverifikasi,
        riwayat: [
          RiwayatStatus(
            status: StatusLaporan.menunggu,
            waktu: tgl4,
            oleh: 'Dewi Lestari',
            catatan: 'Laporan dibuat',
          ),
          RiwayatStatus(
            status: StatusLaporan.diverifikasi,
            waktu: now.subtract(const Duration(days: 1, hours: 12)),
            oleh: 'Admin',
            catatan: 'Laporan dinyatakan valid.',
          ),
        ],
      ),
    ];
  }

  List<Laporan> get laporanList => List.unmodifiable(_laporanList);

  /// Laporan yang boleh dilihat [user] menurut perannya:
  /// admin melihat semua, teknisi melihat tugasnya, pelapor melihat miliknya.
  List<Laporan> untuk(AppUser user) {
    if (user.peran.isAdmin) return laporanList;
    if (user.peran.isTeknisi) {
      return _laporanList.where((l) => l.teknisiId == user.uid).toList();
    }
    return _laporanList.where((l) => l.pelaporId == user.uid).toList();
  }

  List<Laporan> _dengan(StatusLaporan s) =>
      _laporanList.where((l) => l.status == s).toList();

  List<Laporan> get laporanMenunggu => _dengan(StatusLaporan.menunggu);
  List<Laporan> get laporanDiverifikasi => _dengan(StatusLaporan.diverifikasi);
  List<Laporan> get laporanDitugaskan => _dengan(StatusLaporan.ditugaskan);
  List<Laporan> get laporanDiproses => _dengan(StatusLaporan.diproses);
  List<Laporan> get laporanSelesai => _dengan(StatusLaporan.selesai);
  List<Laporan> get laporanDitolak => _dengan(StatusLaporan.ditolak);

  void tambahLaporan(Laporan laporan) {
    _laporanList.insert(0, laporan);
    notifyListeners();
  }

  Laporan? _cari(String id) {
    for (final l in _laporanList) {
      if (l.id == id) return l;
    }
    return null;
  }

  /// Menetapkan status baru, mencatatnya ke timeline, dan memberi tahu UI.
  void _catat(
    Laporan l,
    StatusLaporan status, {
    required String oleh,
    required String catatanDefault,
    String? catatan,
  }) {
    final bersih = catatan?.trim();
    final ada = bersih != null && bersih.isNotEmpty;

    l.status = status;
    if (ada) l.catatanAdmin = bersih;
    l.riwayat.add(
      RiwayatStatus(
        status: status,
        waktu: DateTime.now(),
        oleh: oleh,
        catatan: ada ? bersih : catatanDefault,
      ),
    );
    notifyListeners();
  }

  // ----------------------------------------------------- aksi alur kerja
  // Setiap aksi mengembalikan true bila berhasil. Aksi ditolak (false) bila
  // laporan tidak ada atau statusnya belum sesuai urutan alur.

  /// Admin: dilaporkan -> terverifikasi.
  bool verifikasi(String id, {required String oleh, String? catatan}) {
    final l = _cari(id);
    if (l == null || l.status != StatusLaporan.menunggu) return false;
    _catat(l, StatusLaporan.diverifikasi,
        oleh: oleh,
        catatan: catatan,
        catatanDefault: 'Laporan dinyatakan valid.');
    return true;
  }

  /// Admin: dilaporkan / terverifikasi -> ditolak (alasan wajib).
  bool tolak(String id, {required String oleh, required String alasan}) {
    final l = _cari(id);
    if (l == null || alasan.trim().isEmpty) return false;
    if (l.status != StatusLaporan.menunggu &&
        l.status != StatusLaporan.diverifikasi) {
      return false;
    }
    _catat(l, StatusLaporan.ditolak,
        oleh: oleh, catatan: alasan, catatanDefault: 'Laporan ditolak.');
    return true;
  }

  /// Admin: terverifikasi -> ditugaskan. Saat sudah ditugaskan, memanggil ini
  /// lagi berarti mengganti teknisi.
  bool tugaskan(
    String id, {
    required String teknisiId,
    required String teknisiNama,
    required String oleh,
    String? catatan,
  }) {
    final l = _cari(id);
    if (l == null) return false;
    if (l.status != StatusLaporan.diverifikasi &&
        l.status != StatusLaporan.ditugaskan) {
      return false;
    }
    final ganti = l.status == StatusLaporan.ditugaskan;
    l.teknisiId = teknisiId;
    l.teknisiNama = teknisiNama;
    _catat(l, StatusLaporan.ditugaskan,
        oleh: oleh,
        catatan: catatan,
        catatanDefault: ganti
            ? 'Teknisi diganti menjadi $teknisiNama.'
            : 'Ditugaskan kepada $teknisiNama.');
    return true;
  }

  /// Teknisi: ditugaskan -> dikerjakan.
  bool mulaiKerja(String id, {required String oleh, String? catatan}) {
    final l = _cari(id);
    if (l == null || l.status != StatusLaporan.ditugaskan) return false;
    _catat(l, StatusLaporan.diproses,
        oleh: oleh,
        catatan: catatan,
        catatanDefault: 'Teknisi mulai mengerjakan.');
    return true;
  }

  /// Teknisi: dikerjakan -> selesai, boleh melampirkan foto sesudah.
  bool selesaikan(
    String id, {
    required String oleh,
    String? catatan,
    List<Uint8List> fotoSesudah = const [],
  }) {
    final l = _cari(id);
    if (l == null || l.status != StatusLaporan.diproses) return false;
    l.fotoSesudah.addAll(fotoSesudah);
    _catat(l, StatusLaporan.selesai,
        oleh: oleh, catatan: catatan, catatanDefault: 'Pekerjaan selesai.');
    return true;
  }

  /// Ubah status secara bebas (tanpa memeriksa urutan alur).
  /// [catatan] kosong/null tidak menimpa catatan penanganan yang sudah ada.
  void updateStatus(
    String id,
    StatusLaporan status, {
    String? catatan,
    String oleh = 'Admin',
  }) {
    final l = _cari(id);
    if (l == null || l.status == status) return;

    final bersih = catatan?.trim();
    final ada = bersih != null && bersih.isNotEmpty;

    l.status = status;
    if (ada) l.catatanAdmin = bersih;
    l.riwayat.add(
      RiwayatStatus(
        status: status,
        waktu: DateTime.now(),
        oleh: oleh,
        catatan: ada ? bersih : null,
      ),
    );
    notifyListeners();
  }

  String generateId() {
    final nomor = _laporanList.length + 1;
    return 'RPT-${nomor.toString().padLeft(3, '0')}';
  }
}
