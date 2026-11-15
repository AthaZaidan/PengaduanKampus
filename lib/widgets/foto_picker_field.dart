import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';
import 'foto_viewer.dart';

/// Kotak pemilih foto (kamera / galeri) yang berdiri sendiri.
/// Daftar foto dilaporkan ke luar lewat [onChanged].
class FotoPickerField extends StatefulWidget {
  final int maxFoto;
  final ValueChanged<List<Uint8List>> onChanged;

  const FotoPickerField({super.key, required this.onChanged, this.maxFoto = 3});

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.borderMedium,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Text(
                'Pilih Sumber Foto',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepForest,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.softSage.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_camera_outlined,
                    color: AppColors.forestGreen,
                  ),
                ),
                title: const Text(
                  'Ambil dari Kamera',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepForest,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _ambil(ImageSource.camera);
                },
              ),
              const SizedBox(height: 6),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.softSage.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.forestGreen,
                  ),
                ),
                title: const Text(
                  'Pilih dari Galeri',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepForest,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _ambil(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
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
          backgroundColor: AppColors.error,
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
    return SizedBox(
      height: _ukuran,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < _foto.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () => _lihat(i),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.memory(
                          _foto[i],
                          width: _ukuran,
                          height: _ukuran,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: InkWell(
                      onTap: () => _hapus(i),
                      customBorder: const CircleBorder(),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.deepForest.withValues(alpha: 0.75),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_foto.length < widget.maxFoto)
            InkWell(
              onTap: _pilihSumber,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: _ukuran,
                height: _ukuran,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  border: Border.all(
                    color: AppColors.sageGreen.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_a_photo_outlined,
                      color: AppColors.forestGreen,
                      size: 24,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_foto.length}/${widget.maxFoto}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.forestGreen,
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
