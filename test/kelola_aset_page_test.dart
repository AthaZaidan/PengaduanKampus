import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengaduan_kampus/models/aset_kampus.dart';
import 'package:pengaduan_kampus/models/laporan.dart';
import 'package:pengaduan_kampus/screens/admin/kelola_aset_page.dart';
import 'package:pengaduan_kampus/services/aset_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MockAsetService extends AsetService {
  final List<AsetKampus> _list = [];
  final _streamController = StreamController<List<AsetKampus>>.broadcast();

  MockAsetService(List<AsetKampus> initial) {
    _list.addAll(initial);
    _streamController.add(_list);
  }

  @override
  Stream<List<AsetKampus>> streamSemuaAset() async* {
    yield _list;
    yield* _streamController.stream;
  }

  @override
  Future<void> simpanAset(AsetKampus aset) async {
    _list.removeWhere((a) => a.kode == aset.kode);
    _list.add(aset);
    _streamController.add(_list);
  }

  @override
  Future<void> hapusAset(String kode) async {
    _list.removeWhere((a) => a.kode == kode);
    _streamController.add(_list);
  }

  void dispose() {
    _streamController.close();
  }
}

void main() {
  group('KelolaAsetPage Widget Test', () {
    late MockAsetService mockService;
    final dummyAset = [
      const AsetKampus(
        kode: 'AST-2-3-PROYEKTOR-01',
        nama: 'Proyektor Epson EB-X400',
        lokasi: 'Gedung 2 — Lantai 3 — Ruang 302',
        kategori: KategoriKerusakan.fasilitas,
        deskripsi: 'Resolusi XGA 3600 lumens',
      ),
      const AsetKampus(
        kode: 'AST-1-1-AC-DAIKIN',
        nama: 'AC Daikin 2 PK',
        lokasi: 'Gedung 1 — Lantai 1 — Ruang Dosen',
        kategori: KategoriKerusakan.fasilitas,
      ),
    ];

    setUp(() {
      mockService = MockAsetService(dummyAset);
    });

    tearDown(() {
      mockService.dispose();
    });

    testWidgets('Menampilkan daftar aset dan membuka modal QR Code', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: KelolaAsetPage(asetService: mockService),
        ),
      );

      // Tunggu stream memancarkan data
      await tester.pumpAndSettle();

      // Pastikan judul dan aset muncul
      expect(find.text('Kelola Aset Kampus'), findsOneWidget);
      expect(find.text('AST-2-3-PROYEKTOR-01'), findsOneWidget);
      expect(find.text('Proyektor Epson EB-X400'), findsOneWidget);
      expect(find.text('AST-1-1-AC-DAIKIN'), findsOneWidget);

      // Cari dan klik tombol "Lihat QR Code" pada proyektor
      final tombolQr = find.widgetWithText(FilledButton, 'Lihat QR Code').first;
      await tester.tap(tombolQr);
      await tester.pumpAndSettle();

      // Modal QR Code harus terbuka
      expect(find.text('QR Code Aset'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('Salin Kode'), findsOneWidget);
      expect(find.text('Tutup'), findsOneWidget);

      // Tekan tombol Tutup
      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();

      // Modal tertutup
      expect(find.text('QR Code Aset'), findsNothing);
    });

    testWidgets('Pencarian aset memfilter daftar dengan benar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: KelolaAsetPage(asetService: mockService),
        ),
      );

      await tester.pumpAndSettle();

      // Ketik 'daikin' di search bar
      await tester.enterText(find.byType(TextField).first, 'daikin');
      await tester.pumpAndSettle();

      // Hanya AC Daikin yang muncul, Proyektor terfilter
      expect(find.text('AST-1-1-AC-DAIKIN'), findsOneWidget);
      expect(find.text('AST-2-3-PROYEKTOR-01'), findsNothing);

      // Hapus filter
      await tester.enterText(find.byType(TextField).first, '');
      await tester.pumpAndSettle();

      // Keduanya muncul lagi
      expect(find.text('AST-1-1-AC-DAIKIN'), findsOneWidget);
      expect(find.text('AST-2-3-PROYEKTOR-01'), findsOneWidget);
    });
  });
}
