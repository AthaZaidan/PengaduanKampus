import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'foto_viewer.dart';

/// Kotak pemilih foto (kamera / galeri) yang berdiri sendiri.
/// Daftar foto dilaporkan ke luar lewat [onChanged].
class FotoPickerField extends StatefulWidget {
  final int maxFoto;
  final ValueChanged<List<Uint8List>> onChanged;

  const FotoPickerField({
    super.key,
    required this.onChanged,
    this.maxFoto = 3,
  });

  @override
  State<FotoPickerField> createState() => _FotoPickerFieldState();
}

class _FotoPickerFieldState extends State<FotoPickerField> {
  static const double _ukuran = 88;

  final ImagePicker _picker = ImagePicker();
  final List<Uint8List> _foto = [];

  void _pilihSumber() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Ambil dari Kamera'),
              onTap: () {
                Navigator.of(ctx).pop();
                _ambil(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.of(ctx).pop();
                _ambil(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _ambil(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 75,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() => _foto.add(bytes));
      widget.onChanged(List<Uint8List>.of(_foto));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengambil foto. Periksa izin kamera/galeri.'),
        ),
      );
    }
  }

  void _hapus(int i) {
    setState(() => _foto.removeAt(i));
    widget.onChanged(List<Uint8List>.of(_foto));
  }

  void _lihat(int i) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            FotoViewerPage(foto: List<Uint8List>.of(_foto), initialIndex: i),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: _ukuran,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < _foto.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () => _lihat(i),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _foto[i],
                        width: _ukuran,
                        height: _ukuran,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: InkWell(
                      onTap: () => _hapus(i),
                      customBorder: const CircleBorder(),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_foto.length < widget.maxFoto)
            InkWell(
              onTap: _pilihSumber,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: _ukuran,
                height: _ukuran,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border:
                      Border.all(color: scheme.primary.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined,
                        color: scheme.primary, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      '${_foto.length}/${widget.maxFoto}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
