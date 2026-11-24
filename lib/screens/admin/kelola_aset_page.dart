import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/aset_kampus.dart';
import '../../models/laporan.dart';
import '../../services/aset_service.dart';
import '../../services/laporan_repository.dart';
import '../../theme/palet_kampus.dart';
import '../../widgets/pilihan_lokasi.dart';

/// Halaman manajemen aset kampus & generator QR Code untuk Admin Fasilitas.
class KelolaAsetPage extends StatefulWidget {
  final AsetService? asetService;

  const KelolaAsetPage({super.key, this.asetService});

  @override
  State<KelolaAsetPage> createState() => _KelolaAsetPageState();
}

class _KelolaAsetPageState extends State<KelolaAsetPage> {
  late final AsetService _service;
  final TextEditingController _pencarianController = TextEditingController();
  String _kataKunci = '';

  @override
  void initState() {
    super.initState();
    _service = widget.asetService ?? AsetService();
    _pencarianController.addListener(() {
      setState(() => _kataKunci = _pencarianController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _pencarianController.dispose();
    super.dispose();
  }

  void _tampilkanModalQr(AsetKampus aset) {
    final foto = aset.fotoBytes;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        actionsPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            const Icon(Icons.qr_code_2, color: AppColors.forestGreen, size: 28),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'QR Code Aset',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
        content: SizedBox(
          width: 280,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Arahkan kamera aplikasi mahasiswa ke QR Code ini untuk membuat laporan otomatis.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (foto != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      foto,
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderMedium),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: aset.kode,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.deepForest,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.deepForest,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        aset.kode,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: AppColors.deepForest,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        aset.nama,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.forestGreen,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        aset.lokasi,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: aset.kode));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Kode aset "${aset.kode}" disalin ke clipboard.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Salin Kode'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.forestGreen),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _bukaFormTambahAset() async {
    final asetBaru = await showModalBottomSheet<AsetKampus>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SheetTambahAset(service: _service),
    );
    if (!mounted || asetBaru == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Aset ${asetBaru.nama} berhasil didaftarkan!'),
        backgroundColor: AppColors.forestGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _konfirmasiHapusAset(AsetKampus aset) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Aset?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus data aset "${aset.nama}" (${aset.kode})? Data yang dihapus tidak dapat dipulihkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.statusDitolak),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (yakin == true) {
      try {
        await _service.hapusAset(aset.kode);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aset ${aset.kode} berhasil dihapus.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pesanGalatFirebase(e)),
            backgroundColor: AppColors.statusDitolak,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Aset Kampus'),
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        onPressed: _bukaFormTambahAset,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Aset'),
      ),
      body: Column(
        children: [
          // Banner Pengantar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.statusDiverifikasiBg,
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.forestGreen, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Daftarkan inventaris kampus untuk menghasilkan QR Code yang dapat dipindai mahasiswa saat membuat laporan.',
                    style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),

          // Kotak Pencarian
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _pencarianController,
              decoration: InputDecoration(
                hintText: 'Cari kode aset, nama, atau lokasi...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _kataKunci.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _pencarianController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderMedium),
                ),
              ),
            ),
          ),

          // Daftar Aset dari Firestore
          Expanded(
            child: StreamBuilder<List<AsetKampus>>(
              stream: _service.streamSemuaAset(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Terjadi kendala saat memuat aset: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.statusDitolak),
                      ),
                    ),
                  );
                }

                final semua = snapshot.data ?? [];
                final daftar = semua.where((a) {
                  if (_kataKunci.isEmpty) return true;
                  return a.kode.toLowerCase().contains(_kataKunci) ||
                      a.nama.toLowerCase().contains(_kataKunci) ||
                      a.lokasi.toLowerCase().contains(_kataKunci);
                }).toList();

                if (daftar.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_2,
                          size: 64,
                          color: AppColors.softSage,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _kataKunci.isEmpty
                              ? 'Belum ada aset terdaftar'
                              : 'Tidak ada aset yang cocok dengan "$_kataKunci"',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (_kataKunci.isEmpty)
                          const Text(
                            'Klik tombol "Tambah Aset" untuk mendaftarkan barang baru.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: daftar.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final aset = daftar[index];
                    final foto = aset.fotoBytes;

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: AppColors.borderSubtle),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    aset.kode,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.deepForest,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.statusDiverifikasiBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        aset.kategori.icon,
                                        size: 13,
                                        color: AppColors.forestGreen,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        aset.kategori.label,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.forestGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (foto != null) ...[
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(
                                  foto,
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              aset.nama,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 15,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    aset.lokasi,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (aset.deskripsi != null &&
                                aset.deskripsi!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                aset.deskripsi!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  tooltip: 'Hapus Aset',
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.statusDitolak,
                                    size: 20,
                                  ),
                                  onPressed: () => _konfirmasiHapusAset(aset),
                                ),
                                const SizedBox(width: 8),
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.forestGreen,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () => _tampilkanModalQr(aset),
                                  icon: const Icon(Icons.qr_code_2, size: 18),
                                  label: const Text(
                                    'Lihat QR Code',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetTambahAset extends StatefulWidget {
  final AsetService service;

  const _SheetTambahAset({required this.service});

  @override
  State<_SheetTambahAset> createState() => _SheetTambahAsetState();
}

class _SheetTambahAsetState extends State<_SheetTambahAset> {
  static const int _maxFotoBytes = 650 * 1024;

  final _formKey = GlobalKey<FormState>();
  final _kodeCtrl = TextEditingController();
  final _namaCtrl = TextEditingController();
  final _lokasiCtrl = TextEditingController();
  final _deskripsiCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  KategoriKerusakan _kategori = KategoriKerusakan.fasilitas;
  Uint8List? _fotoBytes;
  bool _menyimpan = false;

  @override
  void dispose() {
    _kodeCtrl.dispose();
    _namaCtrl.dispose();
    _lokasiCtrl.dispose();
    _deskripsiCtrl.dispose();
    super.dispose();
  }

  void _pilihSumberFoto() {
    if (_menyimpan) return;
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
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 65,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (bytes.lengthInBytes > _maxFotoBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ukuran foto terlalu besar untuk disimpan di Firestore. Pilih foto dengan resolusi lebih kecil.',
            ),
            backgroundColor: AppColors.statusDitolak,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (!mounted) return;
      setState(() => _fotoBytes = bytes);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengambil foto aset. Periksa izin kamera atau galeri.'),
          backgroundColor: AppColors.statusDitolak,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _simpan() async {
    if (_menyimpan || !_formKey.currentState!.validate()) return;
    setState(() => _menyimpan = true);

    final asetBaru = AsetKampus(
      kode: _kodeCtrl.text.trim().toUpperCase(),
      nama: _namaCtrl.text.trim(),
      lokasi: _lokasiCtrl.text.trim(),
      kategori: _kategori,
      deskripsi: _deskripsiCtrl.text.trim().isEmpty
          ? null
          : _deskripsiCtrl.text.trim(),
      fotoBase64: _fotoBytes != null ? base64Encode(_fotoBytes!) : null,
    );

    try {
      await widget.service.simpanAset(asetBaru);
      if (!mounted) return;
      Navigator.of(context).pop(asetBaru);
    } catch (e) {
      if (!mounted) return;
      setState(() => _menyimpan = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pesanGalatFirebase(e)),
          backgroundColor: AppColors.statusDitolak,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daftarkan Aset Baru',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepForest,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Kode Aset
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _kodeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Kode Aset *',
                        hintText: 'Contoh: AST-2-3-PROYEKTOR-01',
                        prefixIcon: Icon(Icons.qr_code_2),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Kode aset tidak boleh kosong';
                        }
                        if (v.trim().length < 3) {
                          return 'Minimal 3 karakter';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Buat Kode Otomatis',
                    icon: const Icon(Icons.auto_awesome),
                    onPressed: () {
                      final acak =
                          DateTime.now().millisecondsSinceEpoch % 1000;
                      setState(() {
                        _kodeCtrl.text = 'AST-GD-RUANG-$acak';
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Nama Aset
              TextFormField(
                controller: _namaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Aset *',
                  hintText: 'Contoh: Proyektor Epson EB-X400',
                  prefixIcon: Icon(Icons.devices_other),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Nama aset tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Kategori Kerusakan
              DropdownButtonFormField<KategoriKerusakan>(
                initialValue: _kategori,
                decoration: const InputDecoration(
                  labelText: 'Kategori Fasilitas',
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
                items: KategoriKerusakan.values.map((k) {
                  return DropdownMenuItem(
                    value: k,
                    child: Row(
                      children: [
                        Icon(k.icon, size: 18),
                        const SizedBox(width: 8),
                        Text(k.label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (k) {
                  if (k != null) setState(() => _kategori = k);
                },
              ),
              const SizedBox(height: 12),

              // Lokasi Aset
              PilihanLokasi(
                onPilih: (pilihan) {
                  setState(() => _lokasiCtrl.text = pilihan);
                },
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _lokasiCtrl,
                decoration: const InputDecoration(
                  labelText: 'Lokasi Lengkap *',
                  hintText: 'Gedung — Lantai — Ruang',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Lokasi tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Deskripsi (opsional)
              TextFormField(
                controller: _deskripsiCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Catatan / Spesifikasi (opsional)',
                  hintText: 'Keterangan tambahan barang...',
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Foto Aset (opsional)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Foto Aset (opsional)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  if (_fotoBytes != null)
                    TextButton.icon(
                      onPressed: _menyimpan
                          ? null
                          : () => setState(() => _fotoBytes = null),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppColors.statusDitolak,
                      ),
                      label: const Text(
                        'Hapus Foto',
                        style: TextStyle(color: AppColors.statusDitolak),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              if (_fotoBytes != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _fotoBytes!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: FilledButton.tonalIcon(
                        onPressed: _menyimpan ? null : _pilihSumberFoto,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Ganti'),
                      ),
                    ),
                  ],
                )
              else
                OutlinedButton.icon(
                  onPressed: _menyimpan ? null : _pilihSumberFoto,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Pilih / Ambil Foto Aset'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.forestGreen,
                  ),
                  onPressed: _menyimpan ? null : _simpan,
                  icon: _menyimpan
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    _menyimpan ? 'Menyimpan...' : 'Simpan & Buat QR',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}