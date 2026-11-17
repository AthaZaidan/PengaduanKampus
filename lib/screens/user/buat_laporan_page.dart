import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/app_user.dart';
import '../../models/laporan.dart';
import '../../providers/laporan_provider.dart';
import '../../widgets/foto_viewer.dart';
import '../../widgets/foto_lokal.dart';
import '../../widgets/pilihan_lokasi.dart';
import '../../services/fitur_laporan_service.dart';
import '../../services/laporan_repository.dart';

class BuatLaporanPage extends StatefulWidget {
  final LaporanProvider provider;

  /// Pelapor yang membuat laporan (nama dan uid dicatat di laporan).
  final AppUser user;
  final FiturLaporanService? drafService;

  const BuatLaporanPage({
    super.key,
    required this.provider,
    required this.user,
    this.drafService,
  });

  @override
  State<BuatLaporanPage> createState() => _BuatLaporanPageState();
}

class _BuatLaporanPageState extends State<BuatLaporanPage>
    with WidgetsBindingObserver {
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
  late String _laporanId = widget.provider.generateId();

  final List<String> _fotoPaths = [];
  FiturLaporanService? _draf;
  Timer? _timerDraf;
  bool _memuatDraf = false;
  bool _drafGagal = false;
  bool _unggahFoto = false;
  bool _terkirim = false;
  String? _pesanDraf;
  int _versiDraf = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.provider.menggunakanFirebase || widget.drafService != null) {
      _draf = widget.drafService ?? FiturLaporanService(widget.user.uid);
      _memuatDraf = true;
      _muatDraf();
    }
    for (final c in [
      _judulController,
      _deskripsiController,
      _lokasiController,
    ]) {
      c.addListener(_jadwalkanDraf);
    }
  }

  Future<void> _muatDraf() async {
    try {
      final data = await _draf!.muatDraf();
      if (!mounted) return;
      if (data != null) {
        _laporanId = data['laporanId'] as String;
        _judulController.text = data['judul'] as String? ?? '';
        _deskripsiController.text = data['deskripsi'] as String? ?? '';
        _lokasiController.text = data['lokasi'] as String? ?? '';
        _kategori = KategoriKerusakan.values.byName(data['kategori'] as String);
        _prioritas = PrioritasLaporan.values.byName(
          data['prioritas'] as String,
        );
        _fotoPaths.addAll(List<String>.from(data['fotoPaths'] as List? ?? []));
        _pesanDraf = 'Draf sebelumnya dipulihkan.';
      }
    } catch (_) {
      _drafGagal = true;
      _pesanDraf = 'Draf belum dapat dimuat. Coba buka form kembali sebelum membuat laporan baru.';
    } finally {
      if (mounted) setState(() => _memuatDraf = false);
    }
  }

  void _jadwalkanDraf() {
    if (_draf == null || _drafGagal || _memuatDraf || _terkirim || _isLoading) {
      return;
    }
    _timerDraf?.cancel();
    _timerDraf = Timer(const Duration(milliseconds: 600), () => _simpanDraf());
  }

  void _simpanDraf({bool tampilkan = true}) {
    if (_draf == null || _drafGagal || _memuatDraf || _terkirim) return;
    _timerDraf?.cancel();
    final versi = ++_versiDraf;
    if (tampilkan && mounted) {
      setState(() => _pesanDraf = 'Draf sedang disinkronkan ke Firebase.');
    }
    final data = <String, dynamic>{
      'laporanId': _laporanId,
      'judul': _judulController.text,
      'deskripsi': _deskripsiController.text,
      'lokasi': _lokasiController.text,
      'kategori': _kategori.name,
      'prioritas': _prioritas.name,
      'fotoPaths': List<String>.of(_fotoPaths),
    };
    unawaited(
      _draf!
          .simpanDraf(data)
          .then((_) {
            if (mounted && versi == _versiDraf && !_terkirim) {
              setState(
                () => _pesanDraf = 'Draf teks tersimpan di Firebase; foto tersimpan di perangkat.',
              );
            }
          })
          .catchError((Object e) {
            if (mounted && versi == _versiDraf) {
              setState(() => _pesanDraf = pesanGalatFirebase(e));
            }
          }),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _simpanDraf(tampilkan: false);
    }
  }

  @override
  void dispose() {
    _timerDraf?.cancel();
    _simpanDraf(tampilkan: false);
    WidgetsBinding.instance.removeObserver(this);
    _judulController.dispose();
    _deskripsiController.dispose();
    _lokasiController.dispose();
    super.dispose();
  }

  void _pilihSumberFoto() {
    if (_memuatDraf || _drafGagal || _unggahFoto || _isLoading) return;
    if (_foto.length + _fotoPaths.length >= _maxFoto) return;

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
      if (_draf != null) {
        setState(() => _unggahFoto = true);
        final path = await _draf!.simpanFotoDraf(bytes);
        if (!mounted) return;
        setState(() {
          _fotoPaths.add(path);
          _unggahFoto = false;
        });
        _simpanDraf();
      } else {
        setState(() => _foto.add(bytes));
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _unggahFoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFAC3838),
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(
            _draf == null
                ? 'Gagal mengambil foto. Periksa izin kamera/galeri.'
                : pesanGalatFirebase(error),
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  void _hapusFoto(int index) {
    setState(() {
      if (index < _foto.length) {
        _foto.removeAt(index);
      } else {
        final path = _fotoPaths.removeAt(index - _foto.length);
        unawaited(_draf!.hapusFotoDraf(path).catchError((Object _) {}));
      }
    });
    _simpanDraf();
  }

  void _lihatFoto(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FotoViewerPage(
          foto: List<Uint8List>.of(_foto),
          paths: List<String>.of(_fotoPaths),
          initialIndex: index,
        ),
      ),
    );
  }

  Future<void> _buangDraf() async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus draf?'),
        content: const Text(
          'Isi form dan foto draf akan dihapus. Laporan yang sudah dikirim tetap tersimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus draf'),
          ),
        ],
      ),
    );
    if (yakin != true || !mounted) return;
    _timerDraf?.cancel();
    setState(() => _isLoading = true);
    try {
      await _draf!.hapusDraf(laporanId: _laporanId);
      if (!mounted) return;
      _judulController.clear();
      _deskripsiController.clear();
      _lokasiController.clear();
      setState(() {
        _fotoPaths.clear();
        _foto.clear();
        _laporanId = widget.provider.generateId();
        _kategori = KategoriKerusakan.fasilitas;
        _prioritas = PrioritasLaporan.sedang;
        _pesanDraf = 'Draf dihapus. Anda dapat membuat laporan baru.';
      });
    } catch (e) {
      if (mounted) setState(() => _pesanDraf = pesanGalatFirebase(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (_isLoading ||
        _unggahFoto ||
        _drafGagal ||
        _memuatDraf ||
        !_formKey.currentState!.validate()) {
      return;
    }

    _timerDraf?.cancel();
    setState(() => _isLoading = true);

    final laporan = Laporan(
      id: _laporanId,
      judul: _judulController.text.trim(),
      deskripsi: _deskripsiController.text.trim(),
      lokasi: _lokasiController.text.trim(),
      kategori: _kategori,
      prioritas: _prioritas,
      pelapor: widget.user.nama,
      pelaporId: widget.user.uid,
      tanggalLapor: DateTime.now(),
      foto: List<Uint8List>.of(_foto),
      fotoPaths: List<String>.of(_fotoPaths),
    );

    try {
      await widget.provider.tambahLaporan(laporan);
      _terkirim = true;
      if (_draf != null) {
        unawaited(
          _draf!.hapusDraf(laporanId: _laporanId).catchError((Object _) {}),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(pesanGalatFirebase(error))));
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF257054),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: const [
            Icon(Icons.check_circle_outline, color: Colors.white),
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
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !_isLoading && !_unggahFoto && !_memuatDraf,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text(
            'Buat Laporan',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_memuatDraf || _unggahFoto) const LinearProgressIndicator(),
                if (_draf != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _unggahFoto
                          ? 'Menyimpan foto di perangkat...'
                          : _pesanDraf ??
                                'Isi form disimpan otomatis sebagai draf.',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                if (_drafGagal)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _drafGagal = false;
                        _memuatDraf = true;
                      });
                      _muatDraf();
                    },
                    child: const Text('Coba pulihkan draf lagi'),
                  ),
                if (_draf != null && !_drafGagal)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _isLoading || _memuatDraf || _unggahFoto
                          ? null
                          : _buangDraf,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Hapus draf'),
                    ),
                  ),
                // Info banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.08),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: scheme.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Isi form dengan lengkap dan jelas agar laporan dapat segera ditindaklanjuti.',
                          style: TextStyle(color: scheme.primary, fontSize: 12),
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
                  enabled: !_memuatDraf && !_drafGagal && !_isLoading,
                  maxLength: 150,
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
                  onSelected: (k) {
                    setState(() => _kategori = k);
                    _jadwalkanDraf();
                  },
                ),
                const SizedBox(height: 16),

                // Lokasi
                _buildSectionLabel('Lokasi *'),
                if (widget.provider.menggunakanFirebase)
                  PilihanLokasi(
                    onPilih: (nama) => _lokasiController.text = nama,
                  ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _lokasiController,
                  enabled: !_memuatDraf && !_drafGagal && !_isLoading,
                  maxLength: 200,
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
                  enabled: !_memuatDraf && !_drafGagal && !_isLoading,
                  maxLength: 5000,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Jelaskan kerusakan secara detail: kapan terjadi, kondisi saat ini, dampak yang dirasakan...',
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
                  'Maksimal $_maxFoto foto. Foto hanya tersimpan di perangkat ini dan tidak dikirim ke perangkat admin/teknisi.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                _FotoPicker(
                  foto: _foto,
                  paths: _fotoPaths,
                  maxFoto: _maxFoto,
                  onTambah: _unggahFoto ? () {} : _pilihSumberFoto,
                  onHapus: _hapusFoto,
                  onLihat: _lihatFoto,
                ),
                const SizedBox(height: 16),

                // Prioritas
                _buildSectionLabel('Tingkat Prioritas *'),
                const SizedBox(height: 6),
                _PrioritasPicker(
                  selected: _prioritas,
                  onSelected: (p) {
                    setState(() => _prioritas = p);
                    _jadwalkanDraf();
                  },
                ),
                const SizedBox(height: 28),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Simpan laporan ke Firebase? Foto tetap disimpan di perangkat ini.',
                    ),
                  ),
                // Submit Button
                ElevatedButton(
                  onPressed:
                      _isLoading || _unggahFoto || _drafGagal || _memuatDraf
                      ? null
                      : _submit,
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
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_outlined, size: 18),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Kirim Laporan',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 40),
              ],
            ),
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
  final List<String> paths;
  final int maxFoto;
  final VoidCallback onTambah;
  final ValueChanged<int> onHapus;
  final ValueChanged<int> onLihat;

  const _FotoPicker({
    required this.foto,
    this.paths = const [],
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
          for (var i = 0; i < foto.length + paths.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () => onLihat(i),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: _ukuran,
                        height: _ukuran,
                        child: i < foto.length
                            ? Image.memory(foto[i], fit: BoxFit.cover)
                            : FotoLokal(
                                path: paths[i - foto.length],
                                fit: BoxFit.cover,
                              ),
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
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (foto.length + paths.length < maxFoto)
            InkWell(
              onTap: onTambah,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: _ukuran,
                height: _ukuran,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.4),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      color: scheme.primary,
                      size: 26,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${foto.length + paths.length}/$maxFoto',
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
              color: isSelected ? scheme.primary : Colors.white,
              border: Border.all(
                color: isSelected ? scheme.primary : Colors.grey.shade300,
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
                Flexible(
                  child: Text(
                    k.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
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
                      isSelected ? Icons.flag_outlined : Icons.flag_outlined,
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
