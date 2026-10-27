import 'package:flutter_test/flutter_test.dart';
import 'package:pengaduan_kampus/main.dart';

void main() {
  testWidgets('PengaduanKampus smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PengaduanKampusApp());

    // Verify that the title is displayed
    expect(find.text('Pengaduan Kampus'), findsWidgets);
    expect(find.text('Menu Utama'), findsOneWidget);
  });
}
