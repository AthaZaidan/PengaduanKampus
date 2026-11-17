import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pengaduan_kampus/models/app_user.dart';
import 'package:pengaduan_kampus/models/laporan.dart';
import 'package:pengaduan_kampus/providers/laporan_provider.dart';
import 'package:pengaduan_kampus/services/laporan_repository.dart';

const user = AppUser(
  uid: 'u1',
  nama: 'Pelapor',
  email: 'u1@kampus.id',
  peran: PeranPengguna.mahasiswa,
);
Laporan baru() => Laporan(
  id: 'unik',
  judul: 'AC rusak',
  deskripsi: 'Tidak dingin',
  lokasi: 'Gedung A',
  kategori: KategoriKerusakan.fasilitas,
  prioritas: PrioritasLaporan.sedang,
  pelapor: 'Pelapor',
  pelaporId: 'u1',
  tanggalLapor: DateTime(2026, 11, 17),
);

class RepositoryUji implements LaporanRepository {
  final stream = StreamController<HasilSinkronisasi>.broadcast(sync: true);
  Completer<Laporan>? simpan;
  Object? gagal;
  AppUser? dipantau;
  int jumlahSimpan = 0;
  @override
  String generateId() => 'unik';
  @override
  Stream<HasilSinkronisasi> pantau(AppUser user) {
    dipantau = user;
    return stream.stream;
  }

  @override
  Future<Laporan> tambah(Laporan l) async {
    jumlahSimpan++;
    if (gagal != null) throw gagal!;
    return simpan == null ? l : simpan!.future;
  }

  @override
  Future<Laporan?> ubah(
    Laporan sebelumnya,
    bool Function(Laporan) perubahan, {
    List<Uint8List> fotoSesudah = const [],
  }) async {
    if (gagal != null) throw gagal!;
    final salinan = Laporan.fromFirestore(
      sebelumnya.id,
      sebelumnya.toFirestore(),
    );
    if (!perubahan(salinan)) return null;
    final data = salinan.toFirestore()..['revisi'] = sebelumnya.revisi + 1;
    return Laporan.fromFirestore(sebelumnya.id, data);
  }
}

void main() {
  late RepositoryUji repository;
  late LaporanProvider provider;
  setUp(() {
    repository = RepositoryUji();
    provider = LaporanProvider(repository: repository)..hubungkan(user);
  });
  tearDown(() async {
    provider.dispose();
    await repository.stream.close();
  });

  test('menunggu konfirmasi server dan mencegah pengiriman ganda', () async {
    repository.simpan = Completer<Laporan>();
    final pending = provider.tambahLaporan(baru());
    expect(provider.menyimpan, isTrue);
    expect(provider.laporanList, isEmpty);
    await expectLater(provider.tambahLaporan(baru()), throwsStateError);
    expect(repository.jumlahSimpan, 1);
    repository.simpan!.complete(baru());
    await pending;
    expect(provider.menyimpan, isFalse);
    expect(provider.laporanList.single.id, 'unik');
  });

  test('gagal membuat laporan tidak menambah daftar lokal', () async {
    repository.gagal = StateError('Tidak ada koneksi');
    await expectLater(provider.tambahLaporan(baru()), throwsStateError);
    expect(provider.laporanList, isEmpty);
    expect(provider.menyimpan, isFalse);
    expect(provider.galat, 'Tidak ada koneksi');
  });

  test(
    'gagal memperbarui tidak mengubah status dan timeline yang terlihat',
    () async {
      repository.stream.add(HasilSinkronisasi([baru()]));
      repository.gagal = StateError('Akses ditolak');
      await expectLater(
        provider.verifikasi('unik', oleh: 'Admin'),
        throwsStateError,
      );
      expect(provider.laporanList.single.status, StatusLaporan.menunggu);
      expect(provider.laporanList.single.riwayat.length, 1);
    },
  );

  test('snapshot server memperbarui detail dan membedakan cache', () async {
    repository.stream.add(HasilSinkronisasi([baru()], dariCache: true));
    expect(provider.memuat, isFalse);
    expect(provider.dariCache, isTrue);
    expect(repository.dipantau!.uid, user.uid);
    await provider.verifikasi('unik', oleh: 'Admin');
    expect(provider.cari('unik')!.status, StatusLaporan.diverifikasi);
    expect(provider.cari('unik')!.revisi, 1);
    repository.stream.add(HasilSinkronisasi([]));
    expect(provider.cari('unik'), isNull);
    expect(provider.dariCache, isFalse);
  });

  test('hasil simpan sesi lama tidak masuk ke sesi akun baru', () async {
    repository.simpan = Completer<Laporan>();
    final pending = provider.tambahLaporan(baru());
    final assertion = expectLater(pending, throwsStateError);
    provider.hubungkan(
      const AppUser(
        uid: 'u2',
        nama: 'Kedua',
        email: 'u2@kampus.id',
        peran: PeranPengguna.mahasiswa,
      ),
    );
    repository.simpan!.complete(baru());
    await assertion;
    expect(provider.laporanList, isEmpty);
    expect(provider.galat, isNull);
  });

  test(
    'putus sesi menghapus cache yang terlihat dan listener akun lama',
    () async {
      repository.stream.add(HasilSinkronisasi([baru()]));
      provider.putuskan();
      repository.stream.add(HasilSinkronisasi([baru()]));
      expect(provider.laporanList, isEmpty);
      expect(provider.menyimpan, isFalse);
    },
  );

  test(
    'format Firestore mempertahankan data laporan, foto privat, dan audit',
    () {
      final l = baru();
      l.fotoPaths.add('laporan/u1/unik/sebelum/u1/foto');
      l.riwayat.add(
        RiwayatStatus(
          status: StatusLaporan.diverifikasi,
          waktu: DateTime(2026, 11, 17, 10),
          oleh: 'Admin',
          olehId: 'admin',
          catatan: 'Valid',
        ),
      );
      final hasil = Laporan.fromFirestore(l.id, l.toFirestore());
      expect(hasil.toFirestore(), l.toFirestore());
      expect(hasil.foto, isEmpty);
      expect(hasil.jumlahFoto, 1);
      expect(hasil.riwayat.last.olehId, 'admin');
    },
  );
}
