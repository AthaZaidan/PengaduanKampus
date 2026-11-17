import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/laporan.dart';
import '../services/laporan_repository.dart';

class LaporanProvider extends ChangeNotifier {
  /// Repository kosong hanya untuk pengujian unit tanpa layanan Firebase.
  LaporanProvider({this._repository});
  static final LaporanProvider shared = LaporanProvider(
    repository: FirebaseLaporanRepository(),
  );
  final LaporanRepository? _repository;
  final List<Laporan> _laporanList = [];
  StreamSubscription<HasilSinkronisasi>? _subscription;
  AppUser? _user;
  int _sesi = 0;
  bool memuat = false;
  bool menyimpan = false;
  bool dariCache = false;
  String? galat;

  void hubungkan(AppUser user) {
    if (_repository == null) return;
    putuskan();
    _user = user;
    final sesi = _sesi;
    memuat = true;
    _subscription = _repository
        .pantau(user)
        .listen(
          (hasil) {
            if (sesi != _sesi) return;
            _laporanList
              ..clear()
              ..addAll(hasil.laporan);
            dariCache = hasil.dariCache;
            memuat = false;
            galat = null;
            notifyListeners();
          },
          onError: (Object error) {
            if (sesi != _sesi) return;
            memuat = false;
            galat = pesanGalatFirebase(error);
            _laporanList.clear();
            notifyListeners();
          },
        );
  }

  void cobaLagi() {
    final user = _user;
    if (user != null) {
      hubungkan(user);
      notifyListeners();
    }
  }

  void putuskan() {
    _sesi++;
    _subscription?.cancel();
    _subscription = null;
    _user = null;
    _laporanList.clear();
    memuat = false;
    menyimpan = false;
    dariCache = false;
    galat = null;
  }

  @override
  void dispose() {
    putuskan();
    super.dispose();
  }

  List<Laporan> get laporanList => List.unmodifiable(_laporanList);
  Laporan? cari(String id) {
    for (final l in _laporanList) {
      if (l.id == id) return l;
    }
    return null;
  }

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

  void _terapkan(Laporan laporan) {
    final i = _laporanList.indexWhere((l) => l.id == laporan.id);
    if (i < 0) {
      _laporanList.insert(0, laporan);
    } else if (_laporanList[i].revisi <= laporan.revisi) {
      _laporanList[i] = laporan;
    }
    _laporanList.sort((a, b) => b.tanggalLapor.compareTo(a.tanggalLapor));
  }

  Future<T> _simpan<T>(Future<T> Function(int sesi) aksi) async {
    if (menyimpan) throw StateError('Masih menyimpan perubahan sebelumnya.');
    if (_user == null) throw StateError('Silakan masuk kembali.');
    final sesi = _sesi;
    menyimpan = true;
    galat = null;
    notifyListeners();
    try {
      return await aksi(sesi);
    } catch (error) {
      if (sesi == _sesi) galat = pesanGalatFirebase(error);
      rethrow;
    } finally {
      if (sesi == _sesi) {
        menyimpan = false;
        notifyListeners();
      }
    }
  }

  void _cekSesi(int sesi) {
    if (sesi != _sesi) {
      throw StateError('Sesi berubah. Silakan muat ulang laporan.');
    }
  }

  Future<void> tambahLaporan(Laporan laporan) async {
    if (_repository == null) {
      _laporanList.insert(0, laporan);
      notifyListeners();
      return;
    }
    await _simpan((sesi) async {
      final hasil = await _repository.tambah(laporan);
      _cekSesi(sesi);
      _terapkan(hasil);
    });
  }

  Future<bool> _ubah(
    String id,
    bool Function(Laporan) perubahan, {
    List<Uint8List> fotoSesudah = const [],
  }) async {
    final l = cari(id);
    if (l == null) return false;
    if (_repository == null) {
      final ok = perubahan(l);
      if (ok) {
        l.fotoSesudah.addAll(fotoSesudah);
        notifyListeners();
      }
      return ok;
    }
    return _simpan((sesi) async {
      final hasil = await _repository.ubah(
        l,
        perubahan,
        fotoSesudah: fotoSesudah,
      );
      _cekSesi(sesi);
      if (hasil == null) return false;
      _terapkan(hasil);
      return true;
    });
  }

  void _catat(
    Laporan l,
    StatusLaporan status, {
    required String oleh,
    String? catatanDefault,
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
  }

  Future<bool> verifikasi(String id, {required String oleh, String? catatan}) =>
      _ubah(id, (l) {
        if (l.status != StatusLaporan.menunggu) return false;
        _catat(
          l,
          StatusLaporan.diverifikasi,
          oleh: oleh,
          catatan: catatan,
          catatanDefault: 'Laporan dinyatakan valid.',
        );
        return true;
      });

  Future<bool> tolak(
    String id, {
    required String oleh,
    required String alasan,
  }) => _ubah(id, (l) {
    if (alasan.trim().isEmpty ||
        (l.status != StatusLaporan.menunggu &&
            l.status != StatusLaporan.diverifikasi)) {
      return false;
    }
    _catat(l, StatusLaporan.ditolak, oleh: oleh, catatan: alasan);
    return true;
  });

  Future<bool> tugaskan(
    String id, {
    required String teknisiId,
    required String teknisiNama,
    required String oleh,
    String? catatan,
  }) => _ubah(id, (l) {
    if (teknisiId.trim().isEmpty ||
        (l.status != StatusLaporan.diverifikasi &&
            l.status != StatusLaporan.ditugaskan)) {
      return false;
    }
    final ganti = l.status == StatusLaporan.ditugaskan;
    l.teknisiId = teknisiId;
    l.teknisiNama = teknisiNama;
    _catat(
      l,
      StatusLaporan.ditugaskan,
      oleh: oleh,
      catatan: catatan,
      catatanDefault: ganti
          ? 'Teknisi diganti menjadi $teknisiNama.'
          : 'Ditugaskan kepada $teknisiNama.',
    );
    return true;
  });

  Future<bool> mulaiKerja(String id, {required String oleh, String? catatan}) =>
      _ubah(id, (l) {
        if (l.status != StatusLaporan.ditugaskan) return false;
        _catat(
          l,
          StatusLaporan.diproses,
          oleh: oleh,
          catatan: catatan,
          catatanDefault: 'Teknisi mulai mengerjakan.',
        );
        return true;
      });

  Future<bool> selesaikan(
    String id, {
    required String oleh,
    String? catatan,
    List<Uint8List> fotoSesudah = const [],
  }) => _ubah(id, (l) {
    if (l.status != StatusLaporan.diproses) return false;
    _catat(
      l,
      StatusLaporan.selesai,
      oleh: oleh,
      catatan: catatan,
      catatanDefault: 'Pekerjaan selesai.',
    );
    return true;
  }, fotoSesudah: fotoSesudah);

  /// Kompatibilitas pengujian; aturan server tetap membatasi transisi per peran.
  Future<void> updateStatus(
    String id,
    StatusLaporan status, {
    String? catatan,
    String oleh = 'Admin',
  }) async {
    await _ubah(id, (l) {
      if (l.status == status) return false;
      _catat(l, status, oleh: oleh, catatan: catatan);
      return true;
    });
  }

  String generateId() =>
      _repository?.generateId() ??
      'RPT-${(_laporanList.length + 1).toString().padLeft(3, '0')}';
}
