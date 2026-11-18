import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pengaduan_kampus/services/foto_firestore_service.dart';
import 'package:pengaduan_kampus/services/foto_lokal_native.dart';

void main() {
  late Directory root;
  late FotoLokalService service;
  const draf = 'draf/pengguna/foto';
  const laporan = 'laporan/pengguna/id/sebelum/pengguna/foto';
  final bytes = Uint8List.fromList([137, 80, 78, 71]);

  setUp(() async {
    root = await Directory.systemTemp.createTemp('foto_kampus_');
    service = FotoLokalService(direktori: () async => root);
  });

  tearDown(() async => root.delete(recursive: true));

  test(
    'foto tetap tersedia setelah instance penyimpanan dibuat ulang',
    () async {
      await service.simpan(laporan, bytes);
      final dibukaUlang = FotoLokalService(direktori: () async => root);
      expect(await dibukaUlang.baca(laporan), bytes);
    },
  );

  test('menghapus draf tidak menghapus salinan foto laporan', () async {
    await service.simpan(draf, bytes);
    await service.simpan(laporan, (await service.baca(draf))!);
    await service.hapus(draf);
    expect(await service.baca(draf), isNull);
    expect(await service.baca(laporan), bytes);
  });

  test(
    'referensi dari perangkat lain menghasilkan foto tidak tersedia',
    () async {
      expect(await service.baca(laporan), isNull);
      await service.hapus(laporan);
    },
  );

  test('path tidak boleh mengakses berkas di luar direktori foto', () async {
    for (final path in [
      '../rahasia',
      'draf/../rahasia',
      '/tmp/foto',
      'draf//foto',
      r'draf\pengguna\foto',
    ]) {
      await expectLater(service.simpan(path, bytes), throwsStateError);
      await expectLater(service.baca(path), throwsStateError);
      await expectLater(service.hapus(path), throwsStateError);
    }
  });

  test('foto kosong dan lebih dari 5 MB ditolak sebelum disimpan', () async {
    await expectLater(service.simpan(draf, Uint8List(0)), throwsStateError);
    await expectLater(
      service.simpan(draf, Uint8List(5 * 1024 * 1024 + 1)),
      throwsStateError,
    );
    expect(await service.baca(draf), isNull);
  });

  group('FotoFirestoreService', () {
    test('validasi menerima JPEG, PNG, dan WebP', () {
      expect(
        FotoFirestoreService.validasi(Uint8List.fromList([0xff, 0xd8, 0xff])),
        'image/jpeg',
      );
      expect(
        FotoFirestoreService.validasi(
          Uint8List.fromList([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
        ),
        'image/png',
      );
      expect(
        FotoFirestoreService.validasi(
          Uint8List.fromList([
            0x52, 0x49, 0x46, 0x46, // RIFF
            0x00, 0x00, 0x00, 0x00,
            0x57, 0x45, 0x42, 0x50, // WEBP
          ]),
        ),
        'image/webp',
      );
    });

    test('validasi menolak foto kosong, terlalu besar, atau bukan gambar', () {
      expect(
        () => FotoFirestoreService.validasi(Uint8List(0)),
        throwsStateError,
      );
      expect(
        () => FotoFirestoreService.validasi(
          Uint8List(FotoFirestoreService.batasBytes + 1)
            ..[0] = 0xff
            ..[1] = 0xd8
            ..[2] = 0xff,
        ),
        throwsStateError,
      );
      expect(
        () => FotoFirestoreService.validasi(Uint8List.fromList([1, 2, 3, 4])),
        throwsStateError,
      );
    });

    test('adalahPathFirestore mengenali pola path sebelum dan sesudah', () {
      expect(
        FotoFirestoreService.adalahPathFirestore(
          'laporan/u1/l1/sebelum/u1/f1',
        ),
        isTrue,
      );
      expect(
        FotoFirestoreService.adalahPathFirestore(
          'laporan/u1/l1/sesudah/t1/f2',
        ),
        isTrue,
      );
      expect(
        FotoFirestoreService.adalahPathFirestore('draf/u1/f1'),
        isFalse,
      );
      expect(
        FotoFirestoreService.adalahPathFirestore(
          'laporan/u1/l1/lain/u1/f1',
        ),
        isFalse,
      );
    });
  });
}
