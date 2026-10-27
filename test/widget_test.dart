import 'package:flutter_test/flutter_test.dart';
import 'package:pengaduan_kampus/main.dart';

void main() {
  testWidgets('PengaduanKampus app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const PengaduanKampusApp());
    expect(find.text('Pengaduan Kampus'), findsWidgets);
  });
}
