import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../models/laporan.dart';
import '../../providers/laporan_provider.dart';
import '../../widgets/foto_picker_field.dart';
import '../../widgets/foto_viewer.dart';

class DetailLaporanPage extends StatefulWidget {
  final Laporan laporan;
  final LaporanProvider provider;

  /// Pengguna yang sedang melihat; menentukan tombol aksi yang muncul.
  final AppUser user;

  const DetailLaporanPage({
    super.key,
    required this.laporan,
    required this.provider,
    required this.user,
  });

  @override
  State<DetailLaporanPage> createState() => _DetailLaporanPageState();
}

class _DetailLaporanPageState extends State<DetailLaporanPage> {
  Laporan get _laporan => widget.laporan;

  AppUser get _user => widget.user;

  void _snack(String pesan, Color warna) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: warna,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(pesan, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  /// Dialog catatan. Mengembalikan null bila dibatalkan, '' bila catatan
  /// opsional dikosongkan.
  Future<String?> _mintaCatatan({
    required String judul,
    required String hint,
    required String tombol,
    required Color warna,
    String? deskripsi,
    bool wajib = false,
  }) {
    final controller = TextEditingController();
    String? galat;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(judul),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (deskripsi != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    deskripsi,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: hint,
                  errorText: galat,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final teks = controller.text.trim();
                if (wajib && teks.isEmpty) {
                  setDialog(() => galat = 'Wajib diisi');
                  return;
                }
                Navigator.of(ctx).pop(teks);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: warna,
                foregroundColor: Colors.white,
              ),
              child: Text(tombol),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifikasi() async {
    final catatan = await _mintaCatatan(
      judul: 'Verifikasi Laporan',
      deskripsi: 'Pastikan laporan valid sebelum ditugaskan ke teknisi.',
      hint: 'Catatan (opsional)...',
      tombol: 'Verifikasi',
      warna: StatusLaporan.diverifikasi.color,
    );
    if (catatan == null) return;
    final ok = widget.provider
        .verifikasi(_laporan.id, oleh: _user.nama, catatan: catatan);
    if (ok) _snack('Laporan terverifikasi', StatusLaporan.diverifikasi.color);
  }

  Future<void> _tolak() async {
    final alasan = await _mintaCatatan(
      judul: 'Tolak Laporan',
      deskripsi: 'Alasan penolakan akan terlihat oleh pelapor.',
      hint: 'Alasan penolakan...',
      tombol: 'Tolak',
      warna: StatusLaporan.ditolak.color,
      wajib: true,
    );
    if (alasan == null) return;
    final ok =
        widget.provider.tolak(_laporan.id, oleh: _user.nama, alasan: alasan);
    if (ok) _snack('Laporan ditolak', StatusLaporan.ditolak.color);
  }

  Future<void> _tugaskan() async {
    final hasil = await showDialog<_HasilTugas>(
      context: context,
      builder: (_) => _DialogTugaskan(
        admin: _user,
        ganti: _laporan.status == StatusLaporan.ditugaskan,
        teknisiSekarang: _laporan.teknisiId,
      ),
    );
    if (hasil == null) return;
    final ok = widget.provider.tugaskan(
      _laporan.id,
      teknisiId: hasil.id,
      teknisiNama: hasil.nama,
      oleh: _user.nama,
      catatan: hasil.catatan,
    );
    if (ok) {
      _snack('Ditugaskan kepada ${hasil.nama}', StatusLaporan.ditugaskan.color);
    }
  }

  Future<void> _mulaiKerja() async {
    final catatan = await _mintaCatatan(
      judul: 'Mulai Pengerjaan',
      deskripsi: 'Status laporan akan berubah menjadi "Dikerjakan".',
      hint: 'Catatan (opsional)...',
      tombol: 'Mulai',
      warna: StatusLaporan.diproses.color,
    );
    if (catatan == null) return;
    final ok = widget.provider
        .mulaiKerja(_laporan.id, oleh: _user.nama, catatan: catatan);
    if (ok) _snack('Pengerjaan dimulai', StatusLaporan.diproses.color);
  }

  Future<void> _selesaikan() async {
    final controller = TextEditingController();
    var fotoSesudah = <Uint8List>[];

    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tandai Selesai'),
        // Lebar eksplisit: FotoPickerField berisi ListView horizontal yang
        // tidak mendukung intrinsic width, sehingga tanpa ini AlertDialog
        // gagal dirender (layar hanya tampak redup).
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Yang sudah dikerjakan...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Foto sesudah penanganan (opsional)',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                FotoPickerField(onChanged: (f) => fotoSesudah = f),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: StatusLaporan.selesai.color,
              foregroundColor: Colors.white,
            ),
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
    if (yakin != true) return;

    final ok = widget.provider.selesaikan(
      _laporan.id,
      oleh: _user.nama,
      catatan: controller.text,
      fotoSesudah: fotoSesudah,
    );
    if (ok) _snack('Pekerjaan ditandai selesai', StatusLaporan.selesai.color);
  }

  /// Tombol aksi yang boleh dipakai pengguna ini pada status saat ini.
  List<Widget> _tombolAksi() {
    final l = _laporan;
    final hasil = <Widget>[];

    Widget isi(String label, IconData ikon, Color warna, VoidCallback onTap) {
      return FilledButton.icon(
        onPressed: onTap,
        icon: Icon(ikon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(backgroundColor: warna),
      );
    }

    Widget garis(String label, IconData ikon, Color warna, VoidCallback onTap) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(ikon, size: 18, color: warna),
        label: Text(label, style: TextStyle(color: warna)),
        style: OutlinedButton.styleFrom(side: BorderSide(color: warna)),
      );
    }

    if (_user.peran.isAdmin) {
      switch (l.status) {
        case StatusLaporan.menunggu:
          hasil.add(isi('Verifikasi', StatusLaporan.diverifikasi.icon,
              StatusLaporan.diverifikasi.color, _verifikasi));
          hasil.add(garis('Tolak', StatusLaporan.ditolak.icon,
              StatusLaporan.ditolak.color, _tolak));
        case StatusLaporan.diverifikasi:
          hasil.add(isi('Tugaskan Teknisi', StatusLaporan.ditugaskan.icon,
              StatusLaporan.ditugaskan.color, _tugaskan));
          hasil.add(garis('Tolak', StatusLaporan.ditolak.icon,
              StatusLaporan.ditolak.color, _tolak));
        case StatusLaporan.ditugaskan:
          hasil.add(garis('Ganti Teknisi', Icons.swap_horiz_rounded,
              StatusLaporan.ditugaskan.color, _tugaskan));
        case StatusLaporan.diproses:
        case StatusLaporan.selesai:
        case StatusLaporan.ditolak:
          break;
      }
    } else if (_user.peran.isTeknisi && l.teknisiId == _user.uid) {
      switch (l.status) {
        case StatusLaporan.ditugaskan:
          hasil.add(isi('Mulai Pengerjaan', StatusLaporan.diproses.icon,
              StatusLaporan.diproses.color, _mulaiKerja));
        case StatusLaporan.diproses:
          hasil.add(isi('Tandai Selesai', StatusLaporan.selesai.icon,
              StatusLaporan.selesai.color, _selesaikan));
        case StatusLaporan.menunggu:
        case StatusLaporan.diverifikasi:
        case StatusLaporan.selesai:
        case StatusLaporan.ditolak:
          break;
      }
    }
    return hasil;
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild otomatis setiap provider memanggil notifyListeners().
    return ListenableBuilder(
      listenable: widget.provider,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          _laporan.id,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontFamily: 'monospace'),
        ),
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Banner
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: _laporan.status.color.withValues(alpha: 0.1),
                border: Border.all(
                    color: _laporan.status.color.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(_laporan.status.icon,
                      color: _laporan.status.color, size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status Laporan',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                      Text(
                        _laporan.status.label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: _laporan.status.color,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _laporan.prioritas.color.withValues(alpha: 0.1),
                      border: Border.all(
                          color:
                              _laporan.prioritas.color.withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag_rounded,
                            size: 14, color: _laporan.prioritas.color),
                        const SizedBox(width: 4),
                        Text(
                          _laporan.prioritas.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _laporan.prioritas.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Info Laporan
            _InfoCard(
              title: 'Informasi Laporan',
              children: [
                _InfoRow(
                  icon: Icons.title_rounded,
                  label: 'Judul',
                  value: _laporan.judul,
                  isBold: true,
                ),
                _InfoRow(
                  icon: _laporan.kategori.icon,
                  label: 'Kategori',
                  value: _laporan.kategori.label,
                ),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Lokasi',
                  value: _laporan.lokasi,
                ),
                _InfoRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Pelapor',
                  value: _laporan.pelapor,
                ),
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Tanggal Lapor',
                  value: _formatTanggalLengkap(_laporan.tanggalLapor),
                ),
                if (_laporan.teknisiNama != null)
                  _InfoRow(
                    icon: Icons.engineering_outlined,
                    label: 'Teknisi',
                    value: _laporan.teknisiNama!,
                  ),
                if (!_user.peran.isPelapor)
                  _InfoRow(
                    icon: Icons.timer_outlined,
                    label: 'Batas SLA (${_laporan.prioritas.label})',
                    value: _formatTanggalLengkap(_laporan.batasSla),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Deskripsi
            Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.description_outlined,
                            size: 18, color: scheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Deskripsi Kerusakan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: scheme.primary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _laporan.deskripsi,
                      style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                          height: 1.5),
                    ),
                  ],
                ),
              ),
            ),

            // Foto Sebelum (lampiran pelapor)
            if (_laporan.foto.isNotEmpty) ...[
              const SizedBox(height: 12),
              _FotoCard(
                judul: 'Foto Sebelum',
                foto: _laporan.foto,
                onTap: (i) => _bukaFoto(_laporan.foto, i),
              ),
            ],

            // Foto Sesudah (dari teknisi)
            if (_laporan.fotoSesudah.isNotEmpty) ...[
              const SizedBox(height: 12),
              _FotoCard(
                judul: 'Foto Sesudah',
                foto: _laporan.fotoSesudah,
                onTap: (i) => _bukaFoto(_laporan.fotoSesudah, i),
              ),
            ],

            // Catatan Admin
            if (_laporan.catatanAdmin != null &&
                _laporan.catatanAdmin!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                color: const Color(0xFF10B981).withValues(alpha: 0.06),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.comment_outlined,
                              size: 18, color: Color(0xFF10B981)),
                          const SizedBox(width: 8),
                          const Text(
                            'Catatan Penanganan',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _laporan.catatanAdmin!,
                        style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                            height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Timeline Status
            _StatusTimeline(
              riwayat: _laporan.riwayat,
              formatWaktu: _formatTanggalLengkap,
            ),

            const SizedBox(height: 12),

            // Tindakan sesuai peran
            if (!_user.peran.isPelapor)
              _PanelAksi(
                peran: _user.peran,
                tombol: _tombolAksi(),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _bukaFoto(List<Uint8List> foto, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FotoViewerPage(foto: foto, initialIndex: index),
      ),
    );
  }

  String _formatTanggalLengkap(DateTime date) {
    final bulan = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${bulan[date.month]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _PanelAksi extends StatelessWidget {
  final PeranPengguna peran;
  final List<Widget> tombol;

  const _PanelAksi({required this.peran, required this.tombol});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(peran.icon, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Tindakan ${peran.label}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (tombol.isEmpty)
              Text(
                'Tidak ada tindakan yang tersedia untuk laporan ini.',
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
              )
            else
              Wrap(spacing: 10, runSpacing: 10, children: tombol),
          ],
        ),
      ),
    );
  }
}

class _Teknisi {
  final String id;
  final String nama;

  const _Teknisi(this.id, this.nama);
}

class _HasilTugas {
  final String id;
  final String nama;
  final String? catatan;

  const _HasilTugas(this.id, this.nama, this.catatan);
}

/// Dialog memilih teknisi (dibaca dari Firestore: users dengan role teknisi).
class _DialogTugaskan extends StatefulWidget {
  final AppUser admin;
  final bool ganti;
  final String? teknisiSekarang;

  const _DialogTugaskan({
    required this.admin,
    required this.ganti,
    this.teknisiSekarang,
  });

  @override
  State<_DialogTugaskan> createState() => _DialogTugaskanState();
}

class _DialogTugaskanState extends State<_DialogTugaskan> {
  late final Future<List<_Teknisi>> _future = _muat();
  final TextEditingController _catatan = TextEditingController();
  _Teknisi? _terpilih;

  Future<List<_Teknisi>> _muat() async {
    final hasil = <_Teknisi>[];
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'teknisi')
          .get();
      for (final d in snap.docs) {
        final data = d.data();
        final nama = (data['name'] ?? '').toString().trim();
        final email = (data['email'] ?? '').toString().trim();
        hasil.add(_Teknisi(d.id, nama.isNotEmpty ? nama : email));
      }
    } catch (_) {
      // Gagal membaca daftar teknisi: tetap tampilkan opsi lain bila ada.
    }
    hasil.removeWhere((t) => t.id == widget.teknisiSekarang);
    return hasil;
  }

  @override
  void dispose() {
    _catatan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.ganti ? 'Ganti Teknisi' : 'Tugaskan Teknisi'),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<List<_Teknisi>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final daftar = snap.data ?? const <_Teknisi>[];
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (daftar.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Belum ada akun teknisi. Tambahkan lewat tab '
                        '"Teknisi" di menu admin.',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ),
                  for (final t in daftar)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      selected: _terpilih?.id == t.id,
                      selectedColor: scheme.primary,
                      leading: Icon(_terpilih?.id == t.id
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off),
                      title: Text(t.nama),
                      onTap: () => setState(() => _terpilih = t),
                    ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _catatan,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Catatan untuk teknisi (opsional)...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _terpilih == null
              ? null
              : () => Navigator.of(context).pop(
                    _HasilTugas(
                      _terpilih!.id,
                      _terpilih!.nama,
                      _catatan.text.trim().isEmpty ? null : _catatan.text,
                    ),
                  ),
          child: const Text('Tugaskan'),
        ),
      ],
    );
  }
}

class _FotoCard extends StatelessWidget {
  final String judul;
  final List<Uint8List> foto;
  final ValueChanged<int> onTap;

  const _FotoCard({
    required this.judul,
    required this.foto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo_library_outlined,
                    size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  '$judul (${foto.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: foto.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => onTap(i),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      foto[i],
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Timeline perubahan status; entri terbaru ada di paling atas.
class _StatusTimeline extends StatelessWidget {
  final List<RiwayatStatus> riwayat;
  final String Function(DateTime) formatWaktu;

  const _StatusTimeline({required this.riwayat, required this.formatWaktu});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = riwayat.reversed.toList();

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Riwayat Status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            for (var i = 0; i < items.length; i++)
              _TimelineItem(
                item: items[i],
                isLatest: i == 0,
                isLast: i == items.length - 1,
                formatWaktu: formatWaktu,
              ),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final RiwayatStatus item;
  final bool isLatest;
  final bool isLast;
  final String Function(DateTime) formatWaktu;

  const _TimelineItem({
    required this.item,
    required this.isLatest,
    required this.isLast,
    required this.formatWaktu,
  });

  @override
  Widget build(BuildContext context) {
    final color = item.status.color;
    final catatan = item.catatan;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isLatest ? color : color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 1.5),
                  ),
                  child: Icon(
                    item.status.icon,
                    size: 15,
                    color: isLatest ? Colors.white : color,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: Colors.grey.shade300),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.status.label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatWaktu(item.waktu)} \u2022 ${item.oleh}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  if (catatan != null && catatan.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        catatan,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isBold;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
