import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengaduan_kampus/main.dart';

void main() {
  testWidgets('PengaduanKampus app launches and navigates from splash', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PengaduanKampusApp());
    expect(find.text('Pengaduan Kampus'), findsWidgets);
    expect(find.text('LAYANAN FASILITAS KAMPUS'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2200));
    await tester.pumpAndSettle();
    expect(find.text('Masuk ke akun Anda'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('SplashScreen cleans up timer when disposed early', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PengaduanKampusApp());
    expect(find.text('Pengaduan Kampus'), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
