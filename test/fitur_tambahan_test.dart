import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengaduan_kampus/models/laporan.dart';
import 'package:pengaduan_kampus/models/app_user.dart';
import 'package:pengaduan_kampus/models/filter_laporan.dart';
import 'package:pengaduan_kampus/providers/laporan_provider.dart';
import 'package:pengaduan_kampus/services/fitur_laporan_service.dart';
import 'package:pengaduan_kampus/screens/user/buat_laporan_page.dart';
import 'package:pengaduan_kampus/theme/tema_kampus.dart';

const user = AppUser(
  uid: 'u',
  nama: 'Pelapor',
  email: 'u@kampus.id',
  peran: PeranPengguna.mahasiswa,
);
Laporan buat(
  String id, {
  DateTime? tanggal,
  PrioritasLaporan prioritas = PrioritasLaporan.sedang,
}) => Laporan(
  id: id,
  judul: 'Lampu ruangan $id',
  deskripsi: 'Lampu mati',
  lokasi: 'Gedung A',
  kategori: KategoriKerusakan.listrik,
  prioritas: prioritas,
  pelapor: user.nama,
  pelaporId: user.uid,
  tanggalLapor: tanggal ?? DateTime(2026, 1, 1),
  teknisiId: 't',
);

class DrafUji extends FiturLaporanService {
  DrafUji() : super('u');
  Map<String, dynamic>? data;
  bool gagalMuat = false;
  int jumlahSimpan = 0;
  @override
  Future<Map<String, dynamic>?> muatDraf() async {
    if (gagalMuat) throw StateError('Offline');
    return data;
  }

  @override
  Future<void> simpanDraf(Map<String, dynamic> isi) async {
    data = Map.of(isi);
    jumlahSimpan++;
  }

  @override
  Future<void> hapusDraf({String? laporanId}) async {
    data = null;
  }
}

void main() {
  test('rentang tanggal inklusif dan prioritas bekerja bersama pencarian', () {
    final a = buat(
      'a',
      tanggal: DateTime(2026, 1, 2, 23, 59),
      prioritas: PrioritasLaporan.tinggi,
    );
    final b = buat('b', tanggal: DateTime(2026, 1, 3));
    final f = FilterLaporan(
      mulai: DateTime(2026, 1, 2),
      sampai: DateTime(2026, 1, 2),
      prioritas: PrioritasLaporan.tinggi,
    );
    expect(f.terapkan([a, b], ' GEDUNG ').map((l) => l.id), ['a']);
    expect(f.terapkan([a, b], 'tidak ada'), isEmpty);
  });
  test('pengurutan tidak mengubah daftar sumber', () {
    final list = [
      buat('rendah', prioritas: PrioritasLaporan.rendah),
      buat('tinggi', prioritas: PrioritasLaporan.tinggi),
    ];
    expect(
      const FilterLaporan(urutan: UrutanLaporan.prioritas)
          .terapkan(list, '')
          .first
          .id,
      'tinggi',
    );
    expect(list.first.id, 'rendah');
  });
  test(
    'pemeriksaan ulang dan konfirmasi menjaga timeline dan waktu selesai',
    () async {
      final p = LaporanProvider();
      final l = buat('id');
      await p.tambahLaporan(l);
      expect(await p.konfirmasi('id', oleh: user.nama), isFalse);
      await p.verifikasi('id', oleh: 'Admin');
      await p.tugaskan(
        'id',
        teknisiId: 't',
        teknisiNama: 'Teknisi',
        oleh: 'Admin',
      );
      await p.mulaiKerja('id', oleh: 'Teknisi');
      await p.selesaikan('id', oleh: 'Teknisi');
      expect(await p.bukaUlang('id', oleh: user.nama, alasan: ' '), isFalse);
      expect(
        await p.bukaUlang('id', oleh: user.nama, alasan: 'Masih padam'),
        isTrue,
      );
      expect(l.status, StatusLaporan.diproses);
      await p.selesaikan('id', oleh: 'Teknisi', catatan: 'Kabel diganti');
      final waktu = l.waktuSelesai;
      expect(await p.konfirmasi('id', oleh: user.nama), isTrue);
      expect(l.waktuSelesai, waktu);
      expect(l.dikonfirmasi, isTrue);
      expect(await p.konfirmasi('id', oleh: user.nama), isFalse);
      expect(
        await p.bukaUlang('id', oleh: user.nama, alasan: 'Ulang'),
        isFalse,
      );
      p.dispose();
    },
  );
  testWidgets('draf dipulihkan dan ketikan baru disimpan otomatis', (
    tester,
  ) async {
    final service = DrafUji()
      ..data = {
        'laporanId': 'tetap',
        'judul': 'Judul lama',
        'deskripsi': 'Deskripsi lama',
        'lokasi': 'Gedung A',
        'kategori': 'listrik',
        'prioritas': 'tinggi',
        'fotoPaths': <String>[],
      };
    final p = LaporanProvider();
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaKampus.bangun(),
        home: BuatLaporanPage(provider: p, user: user, drafService: service),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Judul lama'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Judul baru');
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(service.data!['laporanId'], 'tetap');
    expect(service.data!['judul'], 'Judul baru');
    expect(service.jumlahSimpan, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    p.dispose();
  });
  testWidgets('pemulihan gagal tidak menimpa draf sebelumnya', (tester) async {
    final service = DrafUji()..gagalMuat = true;
    final p = LaporanProvider();
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaKampus.bangun(),
        home: BuatLaporanPage(provider: p, user: user, drafService: service),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Coba pulihkan draf lagi'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField).first).enabled,
      isFalse,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    expect(service.jumlahSimpan, 0);
    p.dispose();
  });
}
