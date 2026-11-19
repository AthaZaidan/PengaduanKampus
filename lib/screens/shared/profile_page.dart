import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../models/app_user.dart';
import '../../widgets/identitas_kampus.dart';
import '../../models/laporan.dart';
import '../../providers/laporan_provider.dart';
import '../authentication/login_page.dart';
import '../admin/kelola_aset_page.dart';
import '../admin/kelola_lokasi_page.dart';

class ProfilePage extends StatefulWidget {
  final LaporanProvider provider;

  /// Pengguna yang sedang login (peran dibaca dari Firestore).
  final AppUser user;

  const ProfilePage({super.key, required this.provider, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _menyimpanProfil = false;
  static const _bulan = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  // ---------------------------------------------------------------- helpers

  void _snack(String pesan, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: error
            ? const Color(0xFFB84A4A)
            : const Color(0xFF406E49),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(pesan, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  static String _inisial(String nama) {
    final kata = nama
        .trim()
        .split(RegExp(r'\s+'))
        .where((k) => k.isNotEmpty)
        .toList();
    if (kata.isEmpty) return 'M';
    if (kata.length == 1) return kata.first[0].toUpperCase();
    return (kata.first[0] + kata[1][0]).toUpperCase();
  }

  static String? _ambil(Map<String, dynamic> data, String kunci) {
    final nilai = data[kunci];
    if (nilai == null) return null;
    final teks = nilai.toString().trim();
    if (teks.isEmpty || teks == '-') return null;
    return teks;
  }

  String _formatTanggal(DateTime? t) {
    if (t == null) return '-';
    final lokal = t.toLocal();
    return '${lokal.day} ${_bulan[lokal.month - 1]} ${lokal.year}';
  }

  // ---------------------------------------------------------------- actions

  Future<void> _logout() async {
    if (_menyimpanProfil || widget.provider.menyimpan) {
      _snack('Tunggu penyimpanan selesai sebelum keluar.', error: true);
      return;
    }
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Anda perlu masuk lagi untuk memakai aplikasi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB84A4A)),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (yakin != true) return;

    // Logout dari Google Sign-In (jika dipakai) dan Firebase Auth
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _ubahProfil(
    User user, {
    required String namaSekarang,
    required String? nimSekarang,
    required String? teleponSekarang,
  }) async {
    if (_menyimpanProfil) return;
    final hasil = await showDialog<_DataProfil>(
      context: context,
      builder: (_) => _DialogEditProfil(
        peran: widget.user.peran,
        namaAwal: namaSekarang,
        nimAwal: nimSekarang ?? '',
        teleponAwal: teleponSekarang ?? '',
      ),
    );
    if (hasil == null) return;

    final nimSimpan = hasil.nim.isEmpty ? '-' : hasil.nim;
    final teleponSimpan = hasil.telepon.isEmpty ? '-' : hasil.telepon;
    if (hasil.nama == namaSekarang &&
        nimSimpan == (nimSekarang ?? '-') &&
        teleponSimpan == (teleponSekarang ?? '-')) {
      return;
    }

    setState(() => _menyimpanProfil = true);
    try {
      final db = FirebaseFirestore.instance;
      await db.runTransaction((tx) async {
        final ref = db.collection('users').doc(user.uid);
        final doc = await tx.get(ref);
        if (!doc.exists) throw StateError('Profil belum tersedia.');
        tx.update(ref, {
          'name': hasil.nama,
          'nim': nimSimpan,
          'phone': teleponSimpan,
        });
      });
      if (hasil.nama != namaSekarang) {
        try {
          await user.updateDisplayName(hasil.nama);
          await user.reload();
        } catch (_) {
          // Firestore adalah sumber profil utama; nama Auth dapat diselaraskan kemudian.
        }
      }
      if (!mounted) return;
      setState(() {});
      _snack('Profil berhasil diperbarui');
    } catch (_) {
      if (!mounted) return;
      _snack(
        'Profil belum tersimpan. Periksa koneksi dan coba lagi.',
        error: true,
      );
    } finally {
      if (mounted) setState(() => _menyimpanProfil = false);
    }
  }

  Future<void> _ubahPassword(User user) async {
    final pakaiPassword = user.providerData.any(
      (p) => p.providerId == 'password',
    );
    final email = user.email;

    if (!pakaiPassword) {
      _snack(
        'Akun ini masuk dengan Google, jadi tidak memiliki password.',
        error: true,
      );
      return;
    }
    if (email == null || email.isEmpty) {
      _snack('Email akun tidak tersedia.', error: true);
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      _snack('Tautan ubah password dikirim ke $email');
    } catch (_) {
      if (!mounted) return;
      _snack('Gagal mengirim email. Coba lagi nanti.', error: true);
    }
  }

  void _tentangAplikasi() {
    showAboutDialog(
      context: context,
      applicationName: 'Pengaduan Kampus',
      applicationVersion: '1.0.0',
      applicationIcon: const LambangKampus(ukuran: 48),
      children: const [
        SizedBox(height: 8),
        Text(
          'Aplikasi untuk melaporkan kerusakan fasilitas kampus dan '
          'memantau penanganannya.',
        ),
      ],
    );
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        bottom: _menyimpanProfil
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
        title: const Text(
          'Profil Saya',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      body: user == null
          ? const Center(child: Text('Tidak ada pengguna yang masuk.'))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                // Jika Firestore gagal / dokumen belum ada, tetap tampil
                // memakai data dari Firebase Auth.
                final data = snapshot.data?.data() ?? <String, dynamic>{};
                return _buildBody(context, user, data);
              },
            ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    User user,
    Map<String, dynamic> data,
  ) {
    final scheme = Theme.of(context).colorScheme;

    final nama = _ambil(data, 'name') ?? user.displayName ?? 'Mahasiswa';
    final email = _ambil(data, 'email') ?? user.email ?? '-';
    final nim = _ambil(data, 'nim');
    final telepon = _ambil(data, 'phone');
    final peran = widget.user.peran;
    final lewatGoogle = user.providerData.any(
      (p) => p.providerId == 'google.com',
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ---------------------------------------------------------- header
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: scheme.primary.withValues(alpha: 0.08),
                  backgroundImage: user.photoURL != null
                      ? NetworkImage(user.photoURL!)
                      : null,
                  child: user.photoURL == null
                      ? Text(
                          _inisial(nama),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: scheme.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  nama,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    peran.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ------------------------------------------------ ringkasan laporan
        _Kartu(
          judul: 'Ringkasan Laporan',
          ikon: Icons.assignment_outlined,
          child: ListenableBuilder(
            listenable: widget.provider,
            builder: (context, _) {
              final daftar = widget.provider.untuk(widget.user);
              int hitung(Set<StatusLaporan> st) =>
                  daftar.where((l) => st.contains(l.status)).length;
              return Row(
                children: [
                  _AngkaRingkas(
                    nilai: daftar.length,
                    label: 'Total',
                    warna: scheme.primary,
                  ),
                  _AngkaRingkas(
                    nilai: hitung({
                      StatusLaporan.menunggu,
                      StatusLaporan.diverifikasi,
                      StatusLaporan.ditugaskan,
                    }),
                    label: 'Menunggu',
                    warna: StatusLaporan.menunggu.color,
                  ),
                  _AngkaRingkas(
                    nilai: hitung({StatusLaporan.diproses}),
                    label: 'Dikerjakan',
                    warna: StatusLaporan.diproses.color,
                  ),
                  _AngkaRingkas(
                    nilai: hitung({StatusLaporan.selesai}),
                    label: 'Selesai',
                    warna: StatusLaporan.selesai.color,
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // ------------------------------------------------- informasi akun
        _Kartu(
          judul: 'Informasi Akun',
          ikon: Icons.badge_outlined,
          child: Column(
            children: [
              _BarisInfo(ikon: peran.icon, label: 'Peran', nilai: peran.label),
              _BarisInfo(
                ikon: Icons.numbers,
                label: 'NIM / ID',
                nilai: nim ?? 'Belum diisi',
                redup: nim == null,
              ),
              _BarisInfo(
                ikon: Icons.phone_outlined,
                label: 'No. HP',
                nilai: telepon ?? 'Belum diisi',
                redup: telepon == null,
              ),
              _BarisInfo(
                ikon: Icons.email_outlined,
                label: 'Email',
                nilai: email,
              ),
              _BarisInfo(
                ikon: Icons.security_outlined,
                label: 'Metode Masuk',
                nilai: lewatGoogle ? 'Akun Google' : 'Email / NIM',
              ),
              _BarisInfo(
                ikon: Icons.calendar_month_outlined,
                label: 'Bergabung Sejak',
                nilai: _formatTanggal(user.metadata.creationTime),
                terakhir: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ------------------------------------------------------ pengaturan
        _Kartu(
          judul: 'Pengaturan',
          ikon: Icons.settings_outlined,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              if (widget.user.peran.isAdmin) ...[
                _MenuTile(
                  ikon: Icons.qr_code_2,
                  judul: 'Kelola aset & QR kampus',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const KelolaAsetPage()),
                  ),
                ),
                const Divider(height: 1, indent: 56),
                _MenuTile(
                  ikon: Icons.location_on_outlined,
                  judul: 'Kelola lokasi kampus',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const KelolaLokasiPage()),
                  ),
                ),
                const Divider(height: 1, indent: 56),
              ],
              _MenuTile(
                ikon: Icons.edit_outlined,
                judul: 'Edit Profil',
                subjudul: 'Ubah nama, NIM/ID, dan nomor HP',
                onTap: () => _ubahProfil(
                  user,
                  namaSekarang: nama,
                  nimSekarang: nim,
                  teleponSekarang: telepon,
                ),
              ),
              const Divider(height: 1, indent: 56),
              _MenuTile(
                ikon: Icons.lock_reset,
                judul: 'Ubah Password',
                subjudul: 'Kirim tautan reset ke email',
                onTap: () => _ubahPassword(user),
              ),
              const Divider(height: 1, indent: 56),
              _MenuTile(
                ikon: Icons.info_outline,
                judul: 'Tentang Aplikasi',
                onTap: _tentangAplikasi,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ---------------------------------------------------------- logout
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text(
              'Keluar dari Akun',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB84A4A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Komponen kecil
// ---------------------------------------------------------------------------

class _Kartu extends StatelessWidget {
  final String judul;
  final IconData ikon;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _Kartu({
    required this.judul,
    required this.ikon,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 4, 16, 8),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(ikon, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  judul,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

class _AngkaRingkas extends StatelessWidget {
  final int nilai;
  final String label;
  final Color warna;

  const _AngkaRingkas({
    required this.nilai,
    required this.label,
    required this.warna,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$nilai',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: warna,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _BarisInfo extends StatelessWidget {
  final IconData ikon;
  final String label;
  final String nilai;
  final bool redup;
  final bool terakhir;

  const _BarisInfo({
    required this.ikon,
    required this.label,
    required this.nilai,
    this.redup = false,
    this.terakhir = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(ikon, size: 20, color: Colors.grey.shade600),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nilai,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: redup ? Colors.grey.shade400 : null,
                        fontStyle: redup ? FontStyle.italic : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!terakhir) const Divider(height: 1),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData ikon;
  final String judul;
  final String? subjudul;
  final VoidCallback onTap;

  const _MenuTile({
    required this.ikon,
    required this.judul,
    required this.onTap,
    this.subjudul,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      leading: Icon(ikon, color: scheme.primary),
      title: Text(judul, style: const TextStyle(fontSize: 14)),
      subtitle: subjudul == null
          ? null
          : Text(subjudul!, style: const TextStyle(fontSize: 12)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
    );
  }
}

class _DataProfil {
  final String nama;
  final String nim;
  final String telepon;

  const _DataProfil({
    required this.nama,
    required this.nim,
    required this.telepon,
  });
}

class _DialogEditProfil extends StatefulWidget {
  final PeranPengguna peran;
  final String namaAwal;
  final String nimAwal;
  final String teleponAwal;

  const _DialogEditProfil({
    required this.peran,
    required this.namaAwal,
    required this.nimAwal,
    required this.teleponAwal,
  });

  @override
  State<_DialogEditProfil> createState() => _DialogEditProfilState();
}

class _DialogEditProfilState extends State<_DialogEditProfil> {
  final _formKey = GlobalKey<FormState>();
  late final _namaCtrl = TextEditingController(text: widget.namaAwal);
  late final _nimCtrl = TextEditingController(text: widget.nimAwal);
  late final _teleponCtrl = TextEditingController(text: widget.teleponAwal);

  @override
  void dispose() {
    _namaCtrl.dispose();
    _nimCtrl.dispose();
    _teleponCtrl.dispose();
    super.dispose();
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _DataProfil(
        nama: _namaCtrl.text.trim(),
        nim: _nimCtrl.text.trim(),
        telepon: _teleponCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mahasiswa = widget.peran == PeranPengguna.mahasiswa;
    return AlertDialog(
      title: const Text('Edit Profil'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _namaCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nama lengkap',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nama lengkap wajib diisi'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nimCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: mahasiswa ? 9 : 20,
                  decoration: InputDecoration(
                    labelText: mahasiswa ? 'NIM (opsional)' : 'NIP / ID (opsional)',
                    hintText: mahasiswa ? '9 digit angka' : '5-20 digit angka',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    counterText: '',
                  ),
                  validator: (v) {
                    final nilai = v?.trim() ?? '';
                    if (nilai.isEmpty) return null;
                    if (!RegExp(r'^[0-9]+$').hasMatch(nilai)) {
                      return 'NIM / ID hanya boleh berisi angka';
                    }
                    if (mahasiswa && nilai.length != 9) {
                      return 'NIM mahasiswa harus 9 digit angka';
                    }
                    if (!mahasiswa && (nilai.length < 5 || nilai.length > 20)) {
                      return 'NIP / ID harus 5-20 digit';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _teleponCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 13,
                  decoration: const InputDecoration(
                    labelText: 'Nomor HP (opsional)',
                    hintText: 'Contoh: 081234567890',
                    prefixIcon: Icon(Icons.phone_outlined),
                    counterText: '',
                  ),
                  validator: (v) {
                    final nilai = v?.trim() ?? '';
                    if (nilai.isEmpty) return null;
                    if (!RegExp(r'^[0-9]+$').hasMatch(nilai)) {
                      return 'Nomor HP hanya boleh berisi angka';
                    }
                    if (nilai.length < 10 || nilai.length > 13) {
                      return 'Nomor HP tidak valid (10-13 digit)';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _simpan, child: const Text('Simpan')),
      ],
    );
  }
}
