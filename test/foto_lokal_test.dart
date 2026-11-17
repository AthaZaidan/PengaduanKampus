import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
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
}
