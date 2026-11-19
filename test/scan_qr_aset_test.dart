import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengaduan_kampus/models/aset_kampus.dart';
import 'package:pengaduan_kampus/models/filter_laporan.dart';
import 'package:pengaduan_kampus/models/laporan.dart';
import 'package:pengaduan_kampus/screens/shared/scan_qr_page.dart';
import 'package:pengaduan_kampus/services/lokasi_service.dart';

void main() {
  group('AsetKampus Model & Parser QR', () {
    test('Parse format berpola AST-2-3-PROYEKTOR-01', () {
      final aset = AsetKampus.dariKodeMentah('AST-2-3-PROYEKTOR-01');

      expect(aset.kode, 'AST-2-3-PROYEKTOR-01');
      expect(aset.nama, 'PROYEKTOR 01');
      expect(aset.gedung, 'Gedung 2');
      expect(aset.ruangan, 'Ruang 3');
      expect(aset.lokasi, 'Gedung 2 — Ruang 3');
      expect(aset.kategori, KategoriKerusakan.fasilitas);
    });

    test('Parse format JSON cerdas', () {
      const jsonQr =
          '{"kode": "AST-B-302-WIFI", "nama": "Access Point TP-Link", "lokasi": "Gedung B — Ruang 302"}';
      final aset = AsetKampus.dariKodeMentah(jsonQr);

      expect(aset.kode, 'AST-B-302-WIFI');
      expect(aset.nama, 'Access Point TP-Link');
      expect(aset.lokasi, 'Gedung B — Ruang 302');
    });

    test('Deteksi kategori otomatis berdasarkan nama aset', () {
      final ac = AsetKampus.dariKodeMentah('AST-1-1-AC-DAIKIN');
      expect(ac.kategori, KategoriKerusakan.fasilitas);

      final kran = AsetKampus.dariKodeMentah('AST-1-1-KRAN-AIR');
      expect(kran.kategori, KategoriKerusakan.airBersih);

      final wifi = AsetKampus.dariKodeMentah('AST-1-1-WIFI-ROUTER');
      expect(wifi.kategori, KategoriKerusakan.internet);

      final sampah = AsetKampus.dariKodeMentah('AST-1-1-TEMPAT-SAMPAH');
      expect(sampah.kategori, KategoriKerusakan.kebersihan);
    });

    test('Laporan menyimpan dan membaca kodeAset serta koordinat GPS', () {
      final laporan = Laporan(
        id: 'lap-01',
        judul: 'Proyektor Mati',
        deskripsi: 'Proyektor tidak mau menyala saat ditekan powernya.',
        lokasi: 'Gedung 2 — Ruang 3',
        kodeAset: 'AST-2-3-PROYEKTOR-01',
        latitude: -6.200000,
        longitude: 106.816666,
        kategori: KategoriKerusakan.fasilitas,
        prioritas: PrioritasLaporan.sedang,
        pelapor: 'Atha',
        tanggalLapor: DateTime.now(),
      );

      final map = laporan.toFirestore();
      expect(map['kodeAset'], 'AST-2-3-PROYEKTOR-01');
      expect(map['latitude'], -6.200000);
      expect(map['longitude'], 106.816666);
    });

    test('HasilLokasiGps format koordinat dan link Google Maps', () {
      const gps = HasilLokasiGps(latitude: -6.200000, longitude: 106.816666);
      expect(gps.teksKoordinat, '-6.200000, 106.816666');
      expect(
        gps.googleMapsUrl,
        'https://www.google.com/maps/search/?api=1&query=-6.2,106.816666',
      );
    });

    test('JSON QR mendeteksi kategori eksplisit maupun otomatis dari nama', () {
      const jsonEksplisit =
          '{"kode": "AST-01", "nama": "Perangkat Kampus", "lokasi": "Gedung A", "kategori": "internet"}';
      expect(
        AsetKampus.dariKodeMentah(jsonEksplisit).kategori,
        KategoriKerusakan.internet,
      );

      const jsonOtomatis =
          '{"kode": "AST-02", "nama": "Lampu Koridor", "lokasi": "Gedung B"}';
      expect(
        AsetKampus.dariKodeMentah(jsonOtomatis).kategori,
        KategoriKerusakan.listrik,
      );
    });

    test('FilterLaporan dapat mencari laporan berdasarkan kodeAset', () {
      final l1 = Laporan(
        id: 'lap-1',
        judul: 'Proyektor mati',
        deskripsi: 'Tidak menyala',
        lokasi: 'Gedung 2',
        kodeAset: 'AST-2-3-PROYEKTOR-01',
        kategori: KategoriKerusakan.fasilitas,
        prioritas: PrioritasLaporan.sedang,
        pelapor: 'Budi',
        tanggalLapor: DateTime(2026, 11, 18),
      );
      final l2 = Laporan(
        id: 'lap-2',
        judul: 'Kran bocor',
        deskripsi: 'Air menetes',
        lokasi: 'Gedung 1',
        kategori: KategoriKerusakan.airBersih,
        prioritas: PrioritasLaporan.rendah,
        pelapor: 'Sari',
        tanggalLapor: DateTime(2026, 11, 18),
      );

      final hasil = const FilterLaporan().terapkan([l1, l2], 'proyektor-01');
      expect(hasil.map((l) => l.id), ['lap-1']);
    });
  });

  group('ScanQrPage UI & Fallback Manual Input', () {
    testWidgets('Input kode manual mengembalikan objek AsetKampus', (
      tester,
    ) async {
      AsetKampus? hasilScan;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      hasilScan = await Navigator.of(context).push<AsetKampus>(
                        MaterialPageRoute(builder: (_) => const ScanQrPage()),
                      );
                    },
                    child: const Text('Buka Scanner'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Tap buka scanner
      await tester.tap(find.text('Buka Scanner'));
      await tester.pumpAndSettle();

      expect(find.text('Scan QR Aset Kampus'), findsOneWidget);
      expect(find.text('Ketik Kode Manual'), findsOneWidget);

      // Tap dialog input manual
      await tester.tap(find.text('Ketik Kode Manual'));
      await tester.pumpAndSettle();

      expect(find.text('Input Kode Aset Manual'), findsOneWidget);

      // Ketik kode aset AST-2-3-PROYEKTOR-01
      await tester.enterText(find.byType(TextField), 'AST-2-3-PROYEKTOR-01');
      await tester.pumpAndSettle();

      // Tap tombol Gunakan
      await tester.tap(find.text('Gunakan'));
      await tester.pumpAndSettle();

      // Pastikan kembali ke halaman utama dan hasilScan terisi dengan benar
      expect(find.text('Buka Scanner'), findsOneWidget);
      expect(hasilScan, isNotNull);
      expect(hasilScan!.kode, 'AST-2-3-PROYEKTOR-01');
      expect(hasilScan!.gedung, 'Gedung 2');
      expect(hasilScan!.ruangan, 'Ruang 3');
      expect(hasilScan!.nama, 'PROYEKTOR 01');
    });
  });
}
