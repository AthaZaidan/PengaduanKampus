import 'package:flutter_test/flutter_test.dart';
import 'package:pengaduan_kampus/models/laporan.dart';
import 'package:pengaduan_kampus/models/statistik_laporan.dart';

Laporan _buat(
  String id, {
  required DateTime tanggal,
  StatusLaporan status = StatusLaporan.menunggu,
  KategoriKerusakan kategori = KategoriKerusakan.fasilitas,
  PrioritasLaporan prioritas = PrioritasLaporan.sedang,
  List<RiwayatStatus>? riwayat,
}) {
  return Laporan(
    id: id,
    judul: 'Laporan $id',
    deskripsi: 'Deskripsi laporan $id',
    lokasi: 'Gedung A',
    kategori: kategori,
    prioritas: prioritas,
    pelapor: 'Tester',
    tanggalLapor: tanggal,
    status: status,
    riwayat: riwayat,
  );
}

void main() {
  final sekarang = DateTime(2026, 11, 13, 12);

  group('StatistikLaporan.dari', () {
    test('daftar kosong menghasilkan angka nol', () {
      final stat = StatistikLaporan.dari([], sekarang: sekarang);

      expect(stat.total, 0);
      expect(stat.tingkatPenyelesaian, 0);
      expect(stat.rataRataPenyelesaian, isNull);
      expect(stat.tujuhHari.length, 7);
      expect(stat.tujuhHari.every((e) => e.value == 0), isTrue);
    });

    test('menghitung per status, kategori, dan prioritas', () {
      final daftar = [
        _buat('1',
            tanggal: sekarang,
            status: StatusLaporan.selesai,
            kategori: KategoriKerusakan.internet,
            prioritas: PrioritasLaporan.tinggi),
        _buat('2',
            tanggal: sekarang,
            kategori: KategoriKerusakan.internet,
            prioritas: PrioritasLaporan.tinggi),
        _buat('3',
            tanggal: sekarang,
            status: StatusLaporan.diproses,
            kategori: KategoriKerusakan.listrik,
            prioritas: PrioritasLaporan.rendah),
      ];
      final stat = StatistikLaporan.dari(daftar, sekarang: sekarang);

      expect(stat.total, 3);
      expect(stat.perStatus[StatusLaporan.selesai], 1);
      expect(stat.perStatus[StatusLaporan.menunggu], 1);
      expect(stat.perStatus[StatusLaporan.diproses], 1);
      expect(stat.perStatus[StatusLaporan.ditolak], 0);
      expect(stat.perKategori[KategoriKerusakan.internet], 2);
      expect(stat.perKategori[KategoriKerusakan.listrik], 1);
      expect(stat.perPrioritas[PrioritasLaporan.tinggi], 2);
      expect(stat.perPrioritas[PrioritasLaporan.rendah], 1);
      expect(stat.menunggu, 1);
      expect(stat.tingkatPenyelesaian, closeTo(1 / 3, 0.0001));
    });

    test('rata-rata waktu penyelesaian dihitung dari timeline', () {
      final dibuat = DateTime(2026, 11, 13, 8);
      final daftar = [
        _buat(
          '1',
          tanggal: dibuat,
          status: StatusLaporan.selesai,
          riwayat: [
            RiwayatStatus(
                status: StatusLaporan.menunggu, waktu: dibuat, oleh: 'A'),
            RiwayatStatus(
              status: StatusLaporan.selesai,
              waktu: dibuat.add(const Duration(hours: 2)),
              oleh: 'Admin',
            ),
          ],
        ),
        _buat(
          '2',
          tanggal: dibuat,
          status: StatusLaporan.selesai,
          riwayat: [
            RiwayatStatus(
                status: StatusLaporan.menunggu, waktu: dibuat, oleh: 'A'),
            RiwayatStatus(
              status: StatusLaporan.selesai,
              waktu: dibuat.add(const Duration(hours: 4)),
              oleh: 'Admin',
            ),
          ],
        ),
        // belum selesai: tidak ikut dihitung
        _buat('3', tanggal: dibuat),
      ];
      final stat = StatistikLaporan.dari(daftar, sekarang: sekarang);

      expect(stat.rataRataPenyelesaian, const Duration(hours: 3));
    });

    test('tren 7 hari: urut lama ke hari ini dan menghitung per hari', () {
      final daftar = [
        _buat('1', tanggal: DateTime(2026, 11, 13, 9)),
        _buat('2', tanggal: DateTime(2026, 11, 13, 10)),
        _buat('3', tanggal: DateTime(2026, 11, 11, 15)),
        // di luar rentang 7 hari: tidak dihitung
        _buat('4', tanggal: DateTime(2026, 11, 1, 9)),
      ];
      final stat = StatistikLaporan.dari(daftar, sekarang: sekarang);

      expect(stat.tujuhHari.first.key, DateTime(2026, 11, 7));
      expect(stat.tujuhHari.last.key, DateTime(2026, 11, 13));
      expect(stat.tujuhHari.last.value, 2);
      expect(stat.tujuhHari[4].key, DateTime(2026, 11, 11));
      expect(stat.tujuhHari[4].value, 1);
      expect(stat.tujuhHari.fold<int>(0, (a, e) => a + e.value), 3);
    });
  });

  group('StatistikLaporan.formatDurasi', () {
    test('berbagai rentang waktu', () {
      expect(StatistikLaporan.formatDurasi(null), '-');
      expect(StatistikLaporan.formatDurasi(const Duration(seconds: 20)),
          '< 1 menit');
      expect(StatistikLaporan.formatDurasi(const Duration(minutes: 45)),
          '45 menit');
      expect(StatistikLaporan.formatDurasi(const Duration(hours: 3)), '3 jam');
      expect(StatistikLaporan.formatDurasi(const Duration(days: 1, hours: 3)),
          '1 hari 3 jam');
      expect(StatistikLaporan.formatDurasi(const Duration(days: 2)), '2 hari');
    });
  });
}
