import 'package:flutter/material.dart';

/// Warna aksen aplikasi yang mengikuti peran pengguna.
/// `null` = pakai tema bawaan (mis. di halaman login).
class TemaAksen {
  static final ValueNotifier<Color?> warna = ValueNotifier<Color?>(null);
}
