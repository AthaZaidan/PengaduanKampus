// Pembuat aset, bukan pengujian rutin: flutter test tool/generate_app_icons_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengaduan_kampus/widgets/identitas_kampus.dart';

void main() {
  test('ekspor ikon dari sumber vektor aplikasi', () async {
    Future<void> tulis(String path, int ukuran, {bool penuh = true}) async {
      final recorder = ui.PictureRecorder();
      LambangKampusPainter(latarPenuh: penuh)
          .paint(Canvas(recorder), Size.square(ukuran.toDouble()));
      final picture = recorder.endRecording();
      final image = await picture.toImage(ukuran, ukuran);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
    }

    for (final item in {
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    }.entries) {
      await tulis(
        'android/app/src/main/res/mipmap-${item.key}/ic_launcher.png',
        item.value,
      );
    }
    for (final platform in ['ios', 'macos']) {
      final dir = '$platform/Runner/Assets.xcassets/AppIcon.appiconset';
      final json =
          jsonDecode(await File('$dir/Contents.json').readAsString()) as Map;
      for (final item in json['images'] as List) {
        if (item['filename'] == null) continue;
        final ukuran = double.parse((item['size'] as String).split('x').first);
        final skala = double.parse(
          (item['scale'] as String).replaceAll('x', ''),
        );
        await tulis(
          '$dir/${item['filename']}',
          (ukuran * skala).round(),
          penuh: platform == 'ios',
        );
      }
    }
    for (final ukuran in [192, 512]) {
      await tulis('web/icons/Icon-$ukuran.png', ukuran);
      await tulis('web/icons/Icon-maskable-$ukuran.png', ukuran);
    }
    await tulis('web/favicon.png', 32, penuh: false);
    await tulis('assets/branding/ikon-kampus.png', 1024);
  });
}
