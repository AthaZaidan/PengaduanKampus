import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/laporan.dart';
import '../providers/laporan_provider.dart';
import '../widgets/foto_viewer.dart';

class BuatLaporanPage extends StatefulWidget {
  final LaporanProvider provider;

  const BuatLaporanPage({super.key, required this.provider});

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
                _ambilFoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.of(ctx).pop();
                _ambilFoto(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
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
          backgroundColor: const Color(0xFFEF4444),
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    await Future.delayed(const Duration(milliseconds: 800));

    final laporan = Laporan(
      id: widget.provider.generateId(),
      judul: _judulController.text.trim(),
      deskripsi: _deskripsiController.text.trim(),
      lokasi: _lokasiController.text.trim(),
      kategori: _kategori,
      prioritas: _prioritas,
      pelapor: 'Ahmad Fauzi',
      tanggalLapor: DateTime.now(),
      foto: List<Uint8List>.of(_foto),
    );

    widget.provider.tambahLaporan(laporan);

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF10B981),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'Laporan berhasil dikirim!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Buat Laporan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: scheme.primary,
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
                  color: scheme.primary.withValues(alpha: 0.08),
                  border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: scheme.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Isi form dengan lengkap dan jelas agar laporan dapat segera ditindaklanjuti.',
                        style: TextStyle(
                            color: scheme.primary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Judul
              _buildSectionLabel('Judul Laporan *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _judulController,
                decoration: const InputDecoration(
                  hintText: 'Contoh: AC Rusak di Ruang 3.2',
                  filled: true,
                  fillColor: Colors.white,
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
              const SizedBox(height: 16),

              // Kategori
              _buildSectionLabel('Kategori Kerusakan *'),
              const SizedBox(height: 6),
              _KategoriPicker(
                selected: _kategori,
                onSelected: (k) => setState(() => _kategori = k),
              ),
              const SizedBox(height: 16),

              // Lokasi
              _buildSectionLabel('Lokasi *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _lokasiController,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Gedung B - Lantai 3, Ruang 3.2',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Lokasi tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Deskripsi
              _buildSectionLabel('Deskripsi Kerusakan *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _deskripsiController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText:
                      'Jelaskan kerusakan secara detail: kapan terjadi, kondisi saat ini, dampak yang dirasakan...',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Deskripsi tidak boleh kosong';
                  }
                  if (v.trim().length < 20) {
                    return 'Deskripsi minimal 20 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Foto Lampiran
              _buildSectionLabel('Foto Lampiran (opsional)'),
              const SizedBox(height: 2),
              Text(
                'Tambahkan hingga $_maxFoto foto agar kerusakan lebih jelas.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              _FotoPicker(
                foto: _foto,
                maxFoto: _maxFoto,
                onTambah: _pilihSumberFoto,
                onHapus: _hapusFoto,
                onLihat: _lihatFoto,
              ),
              const SizedBox(height: 16),

              // Prioritas
              _buildSectionLabel('Tingkat Prioritas *'),
              const SizedBox(height: 6),
              _PrioritasPicker(
                selected: _prioritas,
                onSelected: (p) => setState(() => _prioritas = p),
              ),
              const SizedBox(height: 28),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Kirim Laporan',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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

  static const double _ukuran = 92;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: _ukuran,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < foto.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () => onLihat(i),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        foto[i],
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
                      onTap: () => onHapus(i),
                      customBorder: const CircleBorder(),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 14,
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
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: _ukuran,
                height: _ukuran,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: scheme.primary.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined,
                        color: scheme.primary, size: 26),
                    const SizedBox(height: 4),
                    Text(
                      '${foto.length}/$maxFoto',
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

class _KategoriPicker extends StatelessWidget {
  final KategoriKerusakan selected;
  final ValueChanged<KategoriKerusakan> onSelected;

  const _KategoriPicker({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: KategoriKerusakan.values.map((k) {
        final isSelected = k == selected;
        return InkWell(
          onTap: () => onSelected(k),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? scheme.primary
                  : Colors.white,
              border: Border.all(
                color: isSelected
                    ? scheme.primary
                    : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  k.icon,
                  size: 16,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  k.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
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
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? p.color.withValues(alpha: 0.12)
                      : Colors.white,
                  border: Border.all(
                    color: isSelected ? p.color : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.flag_rounded
                          : Icons.flag_outlined,
                      size: 20,
                      color: isSelected ? p.color : Colors.grey.shade400,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? p.color : Colors.grey.shade500,
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