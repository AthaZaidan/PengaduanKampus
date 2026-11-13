import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../providers/laporan_provider.dart';
import '../shared/statistik_page.dart';

/// Ringkasan kinerja teknisi (statistik dari tugas miliknya).
class TeknisiKinerjaPage extends StatelessWidget {
  final LaporanProvider provider;
  final AppUser user;

  const TeknisiKinerjaPage({super.key, required this.provider, required this.user});

  @override
  Widget build(BuildContext context) {
    return StatistikPage(provider: provider, user: user);
  }
}
