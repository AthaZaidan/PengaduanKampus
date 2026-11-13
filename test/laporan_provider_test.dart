import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pengaduan_kampus/models/laporan.dart';
import 'package:pengaduan_kampus/providers/laporan_provider.dart';

Laporan _laporanBaru(String id, {List<Uint8List>? foto}) {
  return Laporan(
    id: id,
    judul: 'Lampu Koridor Mati',
    deskripsi: 'Lampu koridor lantai 1 mati sejak kemarin sore.',
    lokasi: 'Gedung A - Lantai 1',
    kategori: KategoriKerusakan.listrik,
    prioritas: PrioritasLaporan.sedang,
    pelapor: 'Tester',
    tanggalLapor: DateTime.now(),
    foto: foto,
  );
}

void main() {
  group('LaporanProvider', () {
    test('tambahLaporan memberi tahu listener (dasar refresh UI)', () {
      final provider = LaporanProvider();
      var dipanggil = 0;
      provider.addListener(() => dipanggil++);

      final jumlahAwal = provider.laporanList.length;
      provider.tambahLaporan(_laporanBaru(provider.generateId()));

      expect(dipanggil, 1);
      expect(provider.laporanList.length, jumlahAwal + 1);
      expect(provider.laporanList.first.judul, 'Lampu Koridor Mati');
    });

    test('updateStatus memberi tahu listener dan menambah timeline', () {
      final provider = LaporanProvider();
      final laporan = _laporanBaru(provider.generateId());
      provider.tambahLaporan(laporan);

      var dipanggil = 0;
      provider.addListener(() => dipanggil++);

      provider.updateStatus(
        laporan.id,
        StatusLaporan.diproses,
        catatan: '  Teknisi menuju lokasi  ',
      );

      expect(dipanggil, 1);
      expect(laporan.status, StatusLaporan.diproses);
      expect(laporan.catatanAdmin, 'Teknisi menuju lokasi');
      expect(laporan.riwayat.length, 2);
      expect(laporan.riwayat.last.status, StatusLaporan.diproses);
      expect(laporan.riwayat.last.oleh, 'Admin');
      expect(laporan.riwayat.last.catatan, 'Teknisi menuju lokasi');
    });

    test('catatan kosong tidak menimpa catatan sebelumnya', () {
      final provider = LaporanProvider();
      final laporan = _laporanBaru(provider.generateId());
      provider.tambahLaporan(laporan);

      provider.updateStatus(laporan.id, StatusLaporan.diproses,
          catatan: 'Sedang dicek');
      provider.updateStatus(laporan.id, StatusLaporan.selesai, catatan: '   ');

      expect(laporan.catatanAdmin, 'Sedang dicek');
      expect(laporan.riwayat.last.status, StatusLaporan.selesai);
      expect(laporan.riwayat.last.catatan, isNull);
    });

    test('status yang sama atau id tidak dikenal diabaikan', () {
      final provider = LaporanProvider();
      final laporan = _laporanBaru(provider.generateId());
      provider.tambahLaporan(laporan);

      var dipanggil = 0;
      provider.addListener(() => dipanggil++);

      provider.updateStatus(laporan.id, StatusLaporan.menunggu);
      provider.updateStatus('RPT-XXX', StatusLaporan.selesai);

      expect(dipanggil, 0);
      expect(laporan.riwayat.length, 1);
    });
  });

  group('Laporan', () {
    test('laporan baru otomatis punya entri awal di timeline', () {
      final laporan = _laporanBaru('RPT-100');

      expect(laporan.riwayat.length, 1);
      expect(laporan.riwayat.first.status, StatusLaporan.menunggu);
      expect(laporan.riwayat.first.oleh, 'Tester');
      expect(laporan.foto, isEmpty);
    });

    test('foto lampiran tersimpan di laporan', () {
      final foto = [
        Uint8List.fromList([1, 2, 3]),
        Uint8List.fromList([4, 5, 6]),
      ];
      final laporan = _laporanBaru('RPT-101', foto: foto);

      expect(laporan.foto.length, 2);
      expect(laporan.foto.first, [1, 2, 3]);
    });
  });
}
