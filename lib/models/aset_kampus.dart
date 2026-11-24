import 'dart:convert';
import 'dart:typed_data';
import 'laporan.dart';

class AsetKampus {
  final String kode;
  final String nama;
  final String lokasi;
  final String? gedung;
  final String? ruangan;
  final KategoriKerusakan kategori;
  final String? deskripsi;
  final String? fotoBase64;

  const AsetKampus({
    required this.kode,
    required this.nama,
    required this.lokasi,
    this.gedung,
    this.ruangan,
    this.kategori = KategoriKerusakan.fasilitas,
    this.deskripsi,
    this.fotoBase64,
  });

  Uint8List? get fotoBytes {
    final raw = fotoBase64;
    if (raw == null || raw.isEmpty) return null;
    try {
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  factory AsetKampus.fromFirestore(String id, Map<String, dynamic> data) {
    KategoriKerusakan kat = KategoriKerusakan.fasilitas;
    final katStr = data['kategori'] as String?;
    if (katStr != null) {
      try {
        kat = KategoriKerusakan.values.byName(katStr);
      } catch (_) {
        kat = KategoriKerusakan.fasilitas;
      }
    }

    return AsetKampus(
      kode: id,
      nama: (data['nama'] as String?) ?? id,
      lokasi: (data['lokasi'] as String?) ?? 'Lokasi kampus',
      gedung: data['gedung'] as String?,
      ruangan: data['ruangan'] as String?,
      kategori: kat,
      deskripsi: data['deskripsi'] as String?,
      fotoBase64: data['fotoBase64'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'kode': kode,
    'nama': nama,
    'lokasi': lokasi,
    'gedung': gedung,
    'ruangan': ruangan,
    'kategori': kategori.name,
    'deskripsi': deskripsi,
    'fotoBase64': fotoBase64,
  };

  /// Parser cerdas untuk membaca kode QR mentah (offline/fallback jika belum di Firestore).
  /// Mendukung JSON, format standar "AST-GEDUNG-RUANG-NAMA-NOMOR", atau teks bebas.
  factory AsetKampus.dariKodeMentah(String raw) {
    final clean = raw.trim();

    // 1. Coba format JSON: {"kode":"AST-01", "nama":"Proyektor", "lokasi":"Gedung A - Ruang 101"}
    if (clean.startsWith('{') && clean.endsWith('}')) {
      try {
        final Map<String, dynamic> json = jsonDecode(clean);
        final nama = (json['nama'] as String?) ?? 'Aset Kampus';
        KategoriKerusakan kategori = _tebakKategori(nama);
        final katStr = json['kategori'] as String?;
        if (katStr != null) {
          try {
            kategori = KategoriKerusakan.values.byName(katStr);
          } catch (_) {
            kategori = _tebakKategori(nama);
          }
        }
        return AsetKampus(
          kode: (json['kode'] as String?) ?? clean,
          nama: nama,
          lokasi: (json['lokasi'] as String?) ?? 'Kampus',
          gedung: json['gedung'] as String?,
          ruangan: json['ruangan'] as String?,
          kategori: kategori,
          deskripsi: json['deskripsi'] as String?,
        );
      } catch (_) {
        // Fallback jika jsonDecode gagal
      }
    }

    // 2. Format berpola: misal "AST-2-3-PROYEKTOR-01" atau "AST-A-102-AC-01"
    final parts = clean.split(RegExp(r'[-_/]'));
    if (parts.length >= 4 && parts[0].toUpperCase() == 'AST') {
      final gedung = 'Gedung ${parts[1]}';
      final ruang = 'Ruang ${parts[2]}';
      final namaBarang = parts.sublist(3).join(' ');
      return AsetKampus(
        kode: clean,
        nama: namaBarang.toUpperCase(),
        lokasi: '$gedung — $ruang',
        gedung: gedung,
        ruangan: ruang,
        kategori: _tebakKategori(namaBarang),
      );
    }

    // 3. Fallback teks bebas
    return AsetKampus(
      kode: clean,
      nama: clean,
      lokasi: 'Terdeteksi dari QR ($clean)',
      kategori: _tebakKategori(clean),
    );
  }

  static KategoriKerusakan _tebakKategori(String kata) {
    final k = kata.toLowerCase();
    if (k.contains('proyektor') ||
        k.contains('ac') ||
        k.contains('komputer') ||
        k.contains('pc') ||
        k.contains('meja') ||
        k.contains('kursi') ||
        k.contains('pintu') ||
        k.contains('jendela')) {
      return KategoriKerusakan.fasilitas;
    }
    if (k.contains('lampu') ||
        k.contains('listrik') ||
        k.contains('stopkontak') ||
        k.contains('kabel') ||
        k.contains('saklar')) {
      return KategoriKerusakan.listrik;
    }
    if (k.contains('air') ||
        k.contains('kran') ||
        k.contains('wastafel') ||
        k.contains('pipa') ||
        k.contains('toilet') ||
        k.contains('bocor')) {
      return KategoriKerusakan.airBersih;
    }
    if (k.contains('wifi') ||
        k.contains('router') ||
        k.contains('jaringan') ||
        k.contains('internet') ||
        k.contains('lan')) {
      return KategoriKerusakan.internet;
    }
    if (k.contains('sampah') ||
        k.contains('kotor') ||
        k.contains('debu') ||
        k.contains('bau')) {
      return KategoriKerusakan.kebersihan;
    }
    return KategoriKerusakan.fasilitas;
  }
}
