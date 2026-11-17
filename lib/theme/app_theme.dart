import 'package:flutter/material.dart';

import 'tema_kampus.dart';
export 'palet_kampus.dart';

/// Semua layar menggunakan tema bersama dengan palet hijau Alham.
class AppTheme {
  AppTheme._();
  static ThemeData get lightTheme => TemaKampus.bangun();
}
