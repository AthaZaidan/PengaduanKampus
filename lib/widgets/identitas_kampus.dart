import 'package:flutter/material.dart';

import '../theme/tema_kampus.dart';

/// Lambang geometris milik aplikasi, bukan lambang resmi suatu universitas.
class LambangKampus extends StatelessWidget {
  final double ukuran;
  const LambangKampus({super.key, this.ukuran = 56});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Pengaduan Kampus',
    image: true,
    child: SizedBox.square(
      dimension: ukuran,
      child: const CustomPaint(painter: LambangKampusPainter()),
    ),
  );
}

/// Kanvas yang sama digunakan untuk ikon launcher dan identitas di dalam aplikasi.
class LambangKampusPainter extends CustomPainter {
  final bool latarPenuh;
  const LambangKampusPainter({this.latarPenuh = false});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 64, size.height / 64);
    final background = Paint()..color = TemaKampus.utama;
    if (latarPenuh) {
      canvas.drawRect(const Rect.fromLTWH(0, 0, 64, 64), background);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 64, 64),
          const Radius.circular(14),
        ),
        background,
      );
    }
    final garis = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;
    // Atap, serambi, tiga pilar, dan fondasi.
    canvas.drawPath(
      Path()
        ..moveTo(14, 26)
        ..lineTo(30, 16)
        ..lineTo(46, 26)
        ..close(),
      garis,
    );
    canvas.drawLine(const Offset(17, 31), const Offset(43, 31), garis);
    for (final x in [20.0, 30.0, 40.0]) {
      canvas.drawLine(Offset(x, 32), Offset(x, 44), garis);
    }
    canvas.drawLine(const Offset(16, 47), const Offset(40, 47), garis);
    canvas.drawCircle(
      const Offset(47, 44),
      10,
      Paint()..color = TemaKampus.utama,
    );
    canvas.drawCircle(
      const Offset(47, 44),
      8.2,
      Paint()..color = TemaKampus.aksen,
    );
    canvas.drawPath(
      Path()
        ..moveTo(43.4, 44)
        ..lineTo(46, 46.6)
        ..lineTo(50.8, 41.4),
      Paint()
        ..color = TemaKampus.utama
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LambangKampusPainter oldDelegate) =>
      oldDelegate.latarPenuh != latarPenuh;
}
