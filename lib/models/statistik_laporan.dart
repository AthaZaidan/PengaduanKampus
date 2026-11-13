import 'laporan.dart';

/// Ringkasan statistik dari daftar laporan (tanpa dependensi UI / Firebase).
class StatistikLaporan {
  final int total;
  final Map<StatusLaporan, int> perStatus;
  final Map<KategoriKerusakan, int> perKategori;
  final Map<PrioritasLaporan, int> perPrioritas;

  /// Jumlah laporan per hari, urut dari 6 hari lalu sampai hari ini.
  final List<MapEntry<DateTime, int>> tujuhHari;

  /// Rata-rata durasi dari laporan dibuat sampai berstatus selesai.
  /// `null` jika belum ada laporan yang selesai.
  final Duration? rataRataPenyelesaian;

  const StatistikLaporan({
    required this.total,
    required this.perStatus,
    required this.perKategori,
    required this.perPrioritas,
    required this.tujuhHari,
    required this.rataRataPenyelesaian,
  });

  int get selesai => perStatus[StatusLaporan.selesai] ?? 0;
  int get menunggu => perStatus[StatusLaporan.menunggu] ?? 0;

  /// 0.0 sampai 1.0
  double get tingkatPenyelesaian => total == 0 ? 0 : selesai / total;

  factory StatistikLaporan.dari(List<Laporan> daftar, {DateTime? sekarang}) {
    final perStatus = <StatusLaporan, int>{
      for (final s in StatusLaporan.values) s: 0,
    };
    final perKategori = <KategoriKerusakan, int>{
      for (final k in KategoriKerusakan.values) k: 0,
    };
    final perPrioritas = <PrioritasLaporan, int>{
      for (final p in PrioritasLaporan.values) p: 0,
    };

    var totalDurasi = Duration.zero;
    var jumlahDurasi = 0;

    for (final l in daftar) {
      perStatus[l.status] = perStatus[l.status]! + 1;
      perKategori[l.kategori] = perKategori[l.kategori]! + 1;
      perPrioritas[l.prioritas] = perPrioritas[l.prioritas]! + 1;

      if (l.status == StatusLaporan.selesai) {
        RiwayatStatus? entriSelesai;
        for (final r in l.riwayat) {
          if (r.status == StatusLaporan.selesai) entriSelesai = r;
        }
        if (entriSelesai != null) {
          final durasi = entriSelesai.waktu.difference(l.tanggalLapor);
          if (!durasi.isNegative) {
            totalDurasi += durasi;
            jumlahDurasi++;
          }
        }
      }
    }

    final now = sekarang ?? DateTime.now();
    final hariIni = DateTime(now.year, now.month, now.day);
    final tujuhHari = <MapEntry<DateTime, int>>[];
    for (var i = 6; i >= 0; i--) {
      final hari = DateTime(hariIni.year, hariIni.month, hariIni.day - i);
      final jumlah = daftar
          .where((l) =>
              l.tanggalLapor.year == hari.year &&
              l.tanggalLapor.month == hari.month &&
              l.tanggalLapor.day == hari.day)
          .length;
      tujuhHari.add(MapEntry(hari, jumlah));
    }

    return StatistikLaporan(
      total: daftar.length,
      perStatus: perStatus,
      perKategori: perKategori,
      perPrioritas: perPrioritas,
      tujuhHari: tujuhHari,
      rataRataPenyelesaian: jumlahDurasi == 0
          ? null
          : Duration(microseconds: totalDurasi.inMicroseconds ~/ jumlahDurasi),
    );
  }

  /// Format durasi singkat: "45 menit", "3 jam", "1 hari 3 jam", atau "-".
  static String formatDurasi(Duration? d) {
    if (d == null) return '-';
    if (d.inMinutes < 1) return '< 1 menit';
    if (d.inHours < 1) return '${d.inMinutes} menit';
    if (d.inDays < 1) return '${d.inHours} jam';
    final sisaJam = d.inHours % 24;
    return sisaJam == 0 ? '${d.inDays} hari' : '${d.inDays} hari $sisaJam jam';
  }
}
