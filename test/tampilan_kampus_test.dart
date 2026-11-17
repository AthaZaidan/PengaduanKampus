import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengaduan_kampus/models/app_user.dart';
import 'package:pengaduan_kampus/models/laporan.dart';
import 'package:pengaduan_kampus/providers/laporan_provider.dart';
import 'package:pengaduan_kampus/screens/authentication/login_page.dart';
import 'package:pengaduan_kampus/screens/authentication/register_page.dart';
import 'package:pengaduan_kampus/screens/user/user_shell.dart';
import 'package:pengaduan_kampus/screens/user/user_laporan_page.dart';
import 'package:pengaduan_kampus/screens/admin/admin_laporan_page.dart';
import 'package:pengaduan_kampus/screens/shared/notifikasi_page.dart';
import 'package:pengaduan_kampus/screens/admin/admin_shell.dart';
import 'package:pengaduan_kampus/screens/teknisi/teknisi_shell.dart';
import 'package:pengaduan_kampus/screens/user/buat_laporan_page.dart';
import 'package:pengaduan_kampus/screens/shared/detail_laporan_page.dart';
import 'package:pengaduan_kampus/screens/shared/statistik_page.dart';
import 'package:pengaduan_kampus/theme/tema_kampus.dart';

const _pelapor = AppUser(
  uid: 'pelapor',
  nama: 'Samuel Alexander Simanjuntak',
  email: 'samuel@students.usu.ac.id',
  peran: PeranPengguna.mahasiswa,
);
final _admin = _pelapor.copyWith(peran: PeranPengguna.admin);
const _teknisi = AppUser(
  uid: 'teknisi',
  nama: 'Petugas Fasilitas',
  email: 'teknisi@kampus.id',
  peran: PeranPengguna.teknisi,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Roboto');
    for (final name in ['Regular', 'Medium', 'Bold']) {
      font.addFont(rootBundle.load('assets/fonts/Roboto-$name.ttf'));
    }
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  for (final kecil in [false, true]) {
    final lebar = kecil ? 320.0 : 390.0;
    final skala = kecil ? 1.4 : 1.0;
    testWidgets('layar kampus pada lebar $lebar dan teks $skala', (
      tester,
    ) async {
      tester.view.physicalSize = Size(lebar, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final provider = LaporanProvider();
      for (final status in StatusLaporan.values) {
        await provider.tambahLaporan(
          Laporan(
            id: 'LaporanFirebaseNomor${status.index}',
            judul: 'Pendingin ruangan tidak berfungsi di ruang kuliah bersama',
            deskripsi: 'Pendingin ruangan sudah tidak berfungsi sejak kegiatan perkuliahan pagi.',
            lokasi: 'Gedung Perkuliahan Bersama — Lantai 3, Ruang 3.12',
            kategori: KategoriKerusakan.fasilitas,
            prioritas: PrioritasLaporan.tinggi,
            pelapor: _pelapor.nama,
            pelaporId: _pelapor.uid,
            tanggalLapor: DateTime.now(),
            status: status,
            teknisiId: 'teknisi',
            teknisiNama: _teknisi.nama,
          ),
        );
      }
      final layar = <String, Widget>{
        'laporan-saya': UserLaporanPage(provider: provider, user: _pelapor),
        'laporan-admin': AdminLaporanPage(provider: provider, user: _admin),
        'notifikasi': NotifikasiPage(provider: provider, user: _pelapor),
        'login': const LoginPage(),
        'daftar': const RegisterPage(),
        'beranda': UserShell(provider: provider, user: _pelapor),
        'admin': AdminShell(provider: provider, user: _admin),
        'teknisi': TeknisiShell(provider: provider, user: _teknisi),
        'buat-laporan': BuatLaporanPage(provider: provider, user: _pelapor),
        'detail': DetailLaporanPage(
          laporan: provider.laporanList.first,
          provider: provider,
          user: _pelapor,
        ),
        'statistik': StatistikPage(provider: provider, user: _pelapor),
      };
      for (final item in layar.entries) {
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: TemaKampus.bangun(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(skala)),
                child: child!,
              ),
              home: item.value,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '${item.key}: tampilan awal',
        );
        if (const bool.fromEnvironment('PREVIEW_UI') && !kecil) {
          await tester.runAsync(() async {
            final boundary =
                key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final file = File('build/ui-preview/${item.key}.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        // Render bagian bawah daftar/form, bukan hanya bagian yang tampak pertama.
        final scroll = find.byType(Scrollable);
        if (scroll.evaluate().isNotEmpty) {
          await tester.drag(scroll.first, const Offset(0, -1400));
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${item.key}: setelah gulir',
          );
        }
        await tester.pumpWidget(const SizedBox.shrink());
      }
      provider.dispose();
    });
  }
}
