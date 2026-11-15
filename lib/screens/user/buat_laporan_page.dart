import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/app_user.dart';
import '../../models/laporan.dart';
import '../../providers/laporan_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/foto_viewer.dart';

class BuatLaporanPage extends StatefulWidget {
  final LaporanProvider provider;

  /// Pelapor yang membuat laporan (nama dan uid dicatat di laporan).
  final AppUser user;

  const BuatLaporanPage({
    super.key,
    required this.provider,
    required this.user,
  });

  @override
  State<BuatLaporanPage> createState() => _BuatLaporanPageState();
}

class _BuatLaporanPageState extends State<BuatLaporanPage> {
  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _lokasiController = TextEditingController();

  static const int _maxFoto = 3;

  final ImagePicker _picker = ImagePicker();
  final List<Uint8List> _foto = [];

  KategoriKerusakan _kategori = KategoriKerusakan.fasilitas;
  PrioritasLaporan _prioritas = PrioritasLaporan.sedang;
  bool _isLoading = false;

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    _lokasiController.dispose();
    super.dispose();
  }

  void _pilihSumberFoto() {
    if (_foto.length >= _maxFoto) return;

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
                'Ambil Foto Lampiran',
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
                  _ambilFoto(ImageSource.camera);
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
                  _ambilFoto(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _ambilFoto(ImageSource source) async {
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
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: const Text(
            'Gagal mengambil foto. Periksa izin kamera/galeri.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  void _hapusFoto(int index) {
    setState(() => _foto.removeAt(index));
  }

  void _lihatFoto(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FotoViewerPage(
          foto: List<Uint8List>.of(_foto),
          initialIndex: index,
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));

    final laporan = Laporan(
      id: widget.provider.generateId(),
      judul: _judulController.text.trim(),
      deskripsi: _deskripsiController.text.trim(),
      lokasi: _lokasiController.text.trim(),
      kategori: _kategori,
      prioritas: _prioritas,
      pelapor: widget.user.nama,
      pelaporId: widget.user.uid,
      tanggalLapor: DateTime.now(),
      foto: List<Uint8List>.of(_foto),
    );

    widget.provider.tambahLaporan(laporan);

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'Laporan berhasil dikirim!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Buat Laporan Baru'),
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  border: Border.all(
                    color: AppColors.sageGreen.withValues(alpha: 0.35),
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.softSage.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.forestGreen,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Isi form dengan lengkap agar laporan Anda dapat segera diverifikasi dan ditangani oleh teknisi.',
                        style: TextStyle(
                          color: AppColors.deepForest,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Card Form Container
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderSubtle, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.deepForest.withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Judul
                    _buildSectionLabel('Judul Laporan *'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _judulController,
                      decoration: const InputDecoration(
                        hintText: 'Contoh: AC Rusak di Ruang 3.2',
                        prefixIcon: Icon(
                          Icons.title_rounded,
                          color: AppColors.sageGreen,
                          size: 20,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Judul tidak boleh kosong';
                        }
                        if (v.trim().length < 5) {
                          return 'Judul minimal 5 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Kategori
                    _buildSectionLabel('Kategori Kerusakan *'),
                    const SizedBox(height: 8),
                    _KategoriPicker(
                      selected: _kategori,
                      onSelected: (k) => setState(() => _kategori = k),
                    ),
                    const SizedBox(height: 18),

                    // Lokasi
                    _buildSectionLabel('Lokasi Kerusakan *'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _lokasiController,
                      decoration: const InputDecoration(
                        hintText: 'Contoh: Gedung B - Lantai 3, Ruang 3.2',
                        prefixIcon: Icon(
                          Icons.location_on_outlined,
                          color: AppColors.sageGreen,
                          size: 20,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Lokasi tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Deskripsi
                    _buildSectionLabel('Deskripsi Kerusakan *'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _deskripsiController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Jelaskan kerusakan secara detail: kondisi saat ini, kendala, atau dampak yang dirasakan...',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Deskripsi tidak boleh kosong';
                        }
                        if (v.trim().length < 15) {
                          return 'Deskripsi minimal 15 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Foto Lampiran
                    _buildSectionLabel('Foto Lampiran (opsional)'),
                    const SizedBox(height: 2),
                    const Text(
                      'Tambahkan hingga 3 foto bukti fisik agar lebih jelas.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _FotoPicker(
                      foto: _foto,
                      maxFoto: _maxFoto,
                      onTambah: _pilihSumberFoto,
                      onHapus: _hapusFoto,
                      onLihat: _lihatFoto,
                    ),
                    const SizedBox(height: 20),

                    // Prioritas
                    _buildSectionLabel('Tingkat Prioritas *'),
                    const SizedBox(height: 8),
                    _PrioritasPicker(
                      selected: _prioritas,
                      onSelected: (p) => setState(() => _prioritas = p),
                    ),
                    const SizedBox(height: 28),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.forestGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send_rounded, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Kirim Laporan',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: AppColors.deepForest,
      ),
    );
  }
}

class _FotoPicker extends StatelessWidget {
  final List<Uint8List> foto;
  final int maxFoto;
  final VoidCallback onTambah;
  final ValueChanged<int> onHapus;
  final ValueChanged<int> onLihat;

  const _FotoPicker({
    required this.foto,
    required this.maxFoto,
    required this.onTambah,
    required this.onHapus,
    required this.onLihat,
  });

  static const double _ukuran = 88;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _ukuran,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < foto.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () => onLihat(i),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.memory(
                          foto[i],
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
                      onTap: () => onHapus(i),
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
          if (foto.length < maxFoto)
            InkWell(
              onTap: onTambah,
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
                      '${foto.length}/$maxFoto',
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

class _KategoriPicker extends StatelessWidget {
  final KategoriKerusakan selected;
  final ValueChanged<KategoriKerusakan> onSelected;

  const _KategoriPicker({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: KategoriKerusakan.values.map((k) {
        final isSelected = k == selected;
        return InkWell(
          onTap: () => onSelected(k),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.forestGreen
                  : AppColors.surfaceContainerLow,
              border: Border.all(
                color: isSelected
                    ? AppColors.forestGreen
                    : AppColors.borderSubtle,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  k.icon,
                  size: 16,
                  color: isSelected ? Colors.white : AppColors.sageGreen,
                ),
                const SizedBox(width: 6),
                Text(
                  k.label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.deepForest,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PrioritasPicker extends StatelessWidget {
  final PrioritasLaporan selected;
  final ValueChanged<PrioritasLaporan> onSelected;

  const _PrioritasPicker({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: PrioritasLaporan.values.map((p) {
        final isSelected = p == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: p != PrioritasLaporan.values.last ? 8.0 : 0,
            ),
            child: InkWell(
              onTap: () => onSelected(p),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? p.backgroundColor : Colors.white,
                  border: Border.all(
                    color: isSelected ? p.color : AppColors.borderSubtle,
                    width: isSelected ? 1.8 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      isSelected ? Icons.flag_rounded : Icons.flag_outlined,
                      size: 20,
                      color: isSelected ? p.color : AppColors.textMuted,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      p.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected ? p.color : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
