import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

/// Hasil pengambilan koordinat GPS pengguna.
class HasilLokasiGps {
  final double latitude;
  final double longitude;
  final double? akurasi;

  const HasilLokasiGps({
    required this.latitude,
    required this.longitude,
    this.akurasi,
  });

  String get teksKoordinat =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  String get googleMapsUrl =>
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
}

/// Layanan untuk mengelola izin dan pengambilan koordinat GPS perangkat.
class LokasiService {
  /// Memeriksa status izin lokasi dan mengambil titik koordinat terkini.
  static Future<HasilLokasiGps> ambilKoordinatSaatIni() async {
    // 1. Cek apakah layanan GPS pada perangkat aktif
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw StateError(
        'Layanan GPS perangkat belum aktif. Mohon aktifkan GPS/Lokasi di pengaturan ponsel.',
      );
    }

    // 2. Cek & minta izin lokasi
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw StateError(
          'Izin akses lokasi ditolak. Aplikasi memerlukan izin lokasi untuk menandai titik kerusakan.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw StateError(
        'Izin lokasi ditolak secara permanen. Mohon izinkan melalui Pengaturan Aplikasi di ponsel Anda.',
      );
    }

    // 3. Ambil posisi dengan timeout dan akurasi tinggi
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    return HasilLokasiGps(
      latitude: position.latitude,
      longitude: position.longitude,
      akurasi: position.accuracy,
    );
  }

  /// Membuka titik koordinat di Google Maps.
  static Future<bool> bukaGoogleMaps(double latitude, double longitude) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
