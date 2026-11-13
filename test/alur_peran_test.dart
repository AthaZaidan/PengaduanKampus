import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pengaduan_kampus/models/app_user.dart';
import 'package:pengaduan_kampus/models/laporan.dart';
import 'package:pengaduan_kampus/providers/laporan_provider.dart';

Laporan _buat(
  String id, {
  String? pelaporId,
  DateTime? tanggal,
  PrioritasLaporan prioritas = PrioritasLaporan.sedang,
}) {
  return Laporan(
    id: id,
    judul: 'Laporan $id',
    deskripsi: 'Deskripsi $id',
    lokasi: 'Gedung A',
    kategori: KategoriKerusakan.fasilitas,
    prioritas: prioritas,
    pelapor: 'Tester',
    pelaporId: pelaporId,
    tanggalLapor: tanggal ?? DateTime.now(),
  );
}

AppUser _user(String uid, PeranPengguna peran) =>
    AppUser(uid: uid, nama: 'User $uid', email: '$uid@x.id', peran: peran);

void main() {
  group('AppUser.peranDariKode', () {
    test('memetakan nilai role dari Firestore', () {
      expect(AppUser.peranDariKode('admin'), PeranPengguna.admin);
      expect(AppUser.peranDariKode(' Teknisi '), PeranPengguna.teknisi);
      expect(AppUser.peranDariKode('dosen'), PeranPengguna.dosen);
      expect(AppUser.peranDariKode('staff'), PeranPengguna.staf);
      expect(AppUser.peranDariKode('mahasiswa'), PeranPengguna.mahasiswa);
    });

    test('nilai lama "student", kosong, atau tak dikenal = mahasiswa', () {
      expect(AppUser.peranDariKode('student'), PeranPengguna.mahasiswa);
      expect(AppUser.peranDariKode(null), PeranPengguna.mahasiswa);
      expect(AppUser.peranDariKode('apa-saja'), PeranPengguna.mahasiswa);
    });

    test('kelompok peran', () {
      expect(PeranPengguna.dosen.isPelapor, isTrue);
      expect(PeranPengguna.staf.isPelapor, isTrue);
      expect(PeranPengguna.admin.isPelapor, isFalse);
      expect(PeranPengguna.admin.isAdmin, isTrue);
      expect(PeranPengguna.teknisi.isTeknisi, isTrue);
    });
  });

  group('LaporanProvider.untuk (data per peran)', () {
    test('pelapor hanya melihat miliknya, admin semua, teknisi tugasnya', () {
      final provider = LaporanProvider();
      final awal = provider.laporanList.length;

      provider.tambahLaporan(_buat('A', pelaporId: 'u1'));
      provider.tambahLaporan(_buat('B', pelaporId: 'u2'));
      provider.verifikasi('A', oleh: 'Admin');
      provider.tugaskan('A',
          teknisiId: 't1', teknisiNama: 'Teknisi 1', oleh: 'Admin');

      expect(provider.untuk(_user('u1', PeranPengguna.mahasiswa)).map((l) => l.id),
          ['A']);
      expect(provider.untuk(_user('u2', PeranPengguna.dosen)).map((l) => l.id),
          ['B']);
      expect(provider.untuk(_user('x', PeranPengguna.admin)).length, awal + 2);
      expect(provider.untuk(_user('t1', PeranPengguna.teknisi)).map((l) => l.id),
          ['A']);
      expect(provider.untuk(_user('t2', PeranPengguna.teknisi)), isEmpty);
    });
  });

  group('Alur status', () {
    test('alur lengkap: dilaporkan > terverifikasi > ditugaskan > dikerjakan > selesai',
        () {
      final provider = LaporanProvider();
      final l = _buat('ALUR');
      provider.tambahLaporan(l);
      var dipanggil = 0;
      provider.addListener(() => dipanggil++);

      expect(provider.verifikasi('ALUR', oleh: 'Admin'), isTrue);
      expect(l.status, StatusLaporan.diverifikasi);

      expect(
        provider.tugaskan('ALUR',
            teknisiId: 't1', teknisiNama: 'Pak Rudi', oleh: 'Admin'),
        isTrue,
      );
      expect(l.status, StatusLaporan.ditugaskan);
      expect(l.teknisiId, 't1');
      expect(l.teknisiNama, 'Pak Rudi');

      expect(provider.mulaiKerja('ALUR', oleh: 'Pak Rudi'), isTrue);
      expect(l.status, StatusLaporan.diproses);

      final foto = [Uint8List.fromList([1, 2, 3])];
      expect(
        provider.selesaikan('ALUR',
            oleh: 'Pak Rudi', catatan: 'AC sudah diperbaiki', fotoSesudah: foto),
        isTrue,
      );
      expect(l.status, StatusLaporan.selesai);
      expect(l.catatanAdmin, 'AC sudah diperbaiki');
      expect(l.fotoSesudah.length, 1);

      expect(l.riwayat.map((r) => r.status), [
        StatusLaporan.menunggu,
        StatusLaporan.diverifikasi,
        StatusLaporan.ditugaskan,
        StatusLaporan.diproses,
        StatusLaporan.selesai,
      ]);
      expect(dipanggil, 4);
    });

    test('urutan yang salah ditolak', () {
      final provider = LaporanProvider();
      final l = _buat('SALAH');
      provider.tambahLaporan(l);

      // belum diverifikasi
      expect(
        provider.tugaskan('SALAH',
            teknisiId: 't1', teknisiNama: 'T', oleh: 'Admin'),
        isFalse,
      );
      expect(provider.mulaiKerja('SALAH', oleh: 'T'), isFalse);
      expect(provider.selesaikan('SALAH', oleh: 'T'), isFalse);

      provider.verifikasi('SALAH', oleh: 'Admin');
      // verifikasi dua kali / id tidak ada
      expect(provider.verifikasi('SALAH', oleh: 'Admin'), isFalse);
      expect(provider.verifikasi('TIDAK-ADA', oleh: 'Admin'), isFalse);
      expect(l.status, StatusLaporan.diverifikasi);
    });

    test('tolak wajib alasan dan hanya sebelum ditugaskan', () {
      final provider = LaporanProvider();
      final l = _buat('TOLAK');
      provider.tambahLaporan(l);

      expect(provider.tolak('TOLAK', oleh: 'Admin', alasan: '   '), isFalse);
      expect(l.status, StatusLaporan.menunggu);

      expect(
          provider.tolak('TOLAK', oleh: 'Admin', alasan: 'Laporan ganda'), isTrue);
      expect(l.status, StatusLaporan.ditolak);
      expect(l.catatanAdmin, 'Laporan ganda');
      expect(l.aktif, isFalse);

      // sudah ditolak: tidak bisa diverifikasi lagi
      expect(provider.verifikasi('TOLAK', oleh: 'Admin'), isFalse);
    });

    test('ganti teknisi saat masih berstatus ditugaskan', () {
      final provider = LaporanProvider();
      final l = _buat('GANTI');
      provider.tambahLaporan(l);
      provider.verifikasi('GANTI', oleh: 'Admin');
      provider.tugaskan('GANTI',
          teknisiId: 't1', teknisiNama: 'Satu', oleh: 'Admin');

      expect(
        provider.tugaskan('GANTI',
            teknisiId: 't2', teknisiNama: 'Dua', oleh: 'Admin'),
        isTrue,
      );
      expect(l.status, StatusLaporan.ditugaskan);
      expect(l.teknisiId, 't2');
      expect(l.riwayat.last.catatan, 'Teknisi diganti menjadi Dua.');

      // setelah dikerjakan tidak bisa diganti lagi
      provider.mulaiKerja('GANTI', oleh: 'Dua');
      expect(
        provider.tugaskan('GANTI',
            teknisiId: 't3', teknisiNama: 'Tiga', oleh: 'Admin'),
        isFalse,
      );
    });
  });

  group('SLA', () {
    test('target per prioritas', () {
      expect(PrioritasLaporan.tinggi.targetSla, const Duration(hours: 24));
      expect(PrioritasLaporan.sedang.targetSla, const Duration(hours: 72));
      expect(PrioritasLaporan.rendah.targetSla, const Duration(days: 7));
    });

    test('laporan aktif yang lewat batas dihitung terlambat', () {
      final baru = _buat('BARU', prioritas: PrioritasLaporan.tinggi);
      final lama = _buat(
        'LAMA',
        prioritas: PrioritasLaporan.tinggi,
        tanggal: DateTime.now().subtract(const Duration(days: 3)),
      );

      expect(baru.melewatiSla, isFalse);
      expect(lama.melewatiSla, isTrue);
    });

    test('laporan selesai dinilai dari waktu selesai, bukan waktu sekarang', () {
      final provider = LaporanProvider();
      final l = _buat(
        'CEPAT',
        prioritas: PrioritasLaporan.tinggi,
        tanggal: DateTime.now().subtract(const Duration(days: 10)),
      );
      // Riwayat dibuat manual: selesai 2 jam setelah dilaporkan.
      final dibuat = l.tanggalLapor;
      final selesai = Laporan(
        id: 'CEPAT2',
        judul: 'x',
        deskripsi: 'x',
        lokasi: 'x',
        kategori: KategoriKerusakan.fasilitas,
        prioritas: PrioritasLaporan.tinggi,
        pelapor: 'T',
        tanggalLapor: dibuat,
        status: StatusLaporan.selesai,
        riwayat: [
          RiwayatStatus(status: StatusLaporan.menunggu, waktu: dibuat, oleh: 'T'),
          RiwayatStatus(
            status: StatusLaporan.selesai,
            waktu: dibuat.add(const Duration(hours: 2)),
            oleh: 'Teknisi',
          ),
        ],
      );
      provider.tambahLaporan(selesai);

      expect(selesai.melewatiSla, isFalse);
    });
  });
}
