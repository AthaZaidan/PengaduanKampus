import 'laporan.dart';

enum UrutanLaporan { terbaru, terlama, prioritas }

class FilterLaporan {
  final KategoriKerusakan? kategori;
  final PrioritasLaporan? prioritas;
  final DateTime? mulai;
  final DateTime? sampai;
  final UrutanLaporan urutan;
  const FilterLaporan({
    this.kategori,
    this.prioritas,
    this.mulai,
    this.sampai,
    this.urutan = UrutanLaporan.terbaru,
  });
  bool get aktif =>
      kategori != null ||
      prioritas != null ||
      mulai != null ||
      sampai != null ||
      urutan != UrutanLaporan.terbaru;
  List<Laporan> terapkan(Iterable<Laporan> sumber, String query) {
    final q = query.trim().toLowerCase();
    final batas = sampai == null
        ? null
        : DateTime(sampai!.year, sampai!.month, sampai!.day + 1);
    final hasil = sumber
        .where(
          (l) =>
              (kategori == null || l.kategori == kategori) &&
              (prioritas == null || l.prioritas == prioritas) &&
              (mulai == null || !l.tanggalLapor.isBefore(mulai!)) &&
              (batas == null || l.tanggalLapor.isBefore(batas)) &&
              (q.isEmpty ||
                  [
                    l.judul,
                    l.lokasi,
                    l.id,
                  ].any((s) => s.toLowerCase().contains(q))),
        )
        .toList();
    hasil.sort((a, b) {
      if (urutan == UrutanLaporan.prioritas) {
        final beda = b.prioritas.index.compareTo(a.prioritas.index);
        if (beda != 0) return beda;
      }
      return urutan == UrutanLaporan.terlama
          ? a.tanggalLapor.compareTo(b.tanggalLapor)
          : b.tanggalLapor.compareTo(a.tanggalLapor);
    });
    return hasil;
  }
}
