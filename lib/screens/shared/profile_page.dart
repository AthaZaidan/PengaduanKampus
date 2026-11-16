import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../models/app_user.dart';
import '../../models/laporan.dart';
import '../../providers/laporan_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/tema_aksen.dart';
import '../authentication/login_page.dart';

class ProfilePage extends StatefulWidget {
  final LaporanProvider provider;

  /// Pengguna yang sedang login (peran dibaca dari Firestore).
  final AppUser user;

  const ProfilePage({super.key, required this.provider, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
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
        backgroundColor: error ? AppColors.error : AppColors.success,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(
          pesan,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
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
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Keluar dari akun?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.deepForest,
          ),
        ),
        content: const Text(
          'Anda perlu masuk lagi untuk memakai aplikasi Pengaduan Kampus.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
    TemaAksen.warna.value = null;

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _ubahNama(User user, String namaSekarang) async {
    final controller = TextEditingController(text: namaSekarang);
    final nama = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Ubah Nama',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.deepForest,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nama lengkap'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.forestGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (nama == null || nama.isEmpty || nama == namaSekarang) return;

    try {
      await user.updateDisplayName(nama);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': nama,
      }, SetOptions(merge: true));
      await user.reload();
      if (!mounted) return;
      setState(() {});
      _snack('Nama berhasil diperbarui');
    } catch (_) {
      if (!mounted) return;
      _snack('Gagal memperbarui nama. Coba lagi.', error: true);
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
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.softSage.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.campaign_rounded,
          size: 32,
          color: AppColors.forestGreen,
        ),
      ),
      children: const [
        SizedBox(height: 10),
        Text(
          'Aplikasi modern untuk melaporkan kerusakan fasilitas kampus dan memantau alur penanganan teknisi secara transparan.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Profil Saya',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? const Center(child: Text('Tidak ada pengguna yang masuk.'))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
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
        Container(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.forestGreen,
            boxShadow: [
              BoxShadow(
                color: AppColors.forestGreen.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.softSage.withValues(alpha: 0.6),
                    width: 2.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 37,
                    backgroundColor: AppColors.softSage.withValues(alpha: 0.45),
                    backgroundImage: user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : null,
                    child: user.photoURL == null
                        ? Text(
                            _inisial(nama),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.forestGreen,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                nama,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                email,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  peran.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

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
                    warna: AppColors.forestGreen,
                    latar: AppColors.statusSelesaiBg,
                  ),
                  _AngkaRingkas(
                    nilai: hitung({
                      StatusLaporan.menunggu,
                      StatusLaporan.diverifikasi,
                      StatusLaporan.ditugaskan,
                    }),
                    label: 'Menunggu',
                    warna: AppColors.statusMenunggu,
                    latar: AppColors.statusMenungguBg,
                  ),
                  _AngkaRingkas(
                    nilai: hitung({StatusLaporan.diproses}),
                    label: 'Dikerjakan',
                    warna: AppColors.statusDiproses,
                    latar: AppColors.statusDiprosesBg,
                  ),
                  _AngkaRingkas(
                    nilai: hitung({StatusLaporan.selesai}),
                    label: 'Selesai',
                    warna: AppColors.statusSelesai,
                    latar: AppColors.statusSelesaiBg,
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 14),

        // ------------------------------------------------- informasi akun
        _Kartu(
          judul: 'Informasi Akun',
          ikon: Icons.badge_outlined,
          child: Column(
            children: [
              _BarisInfo(
                ikon: peran.icon,
                label: 'Peran Akun',
                nilai: peran.label,
              ),
              _BarisInfo(
                ikon: Icons.numbers_rounded,
                label: 'NIM / ID',
                nilai: nim ?? 'Belum diisi',
                redup: nim == null,
              ),
              _BarisInfo(
                ikon: Icons.phone_outlined,
                label: 'No. HP / WhatsApp',
                nilai: telepon ?? 'Belum diisi',
                redup: telepon == null,
              ),
              _BarisInfo(
                ikon: Icons.email_outlined,
                label: 'Alamat Email',
                nilai: email,
              ),
              _BarisInfo(
                ikon: Icons.security_rounded,
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
        const SizedBox(height: 14),

        // ------------------------------------------------------ pengaturan
        _Kartu(
          judul: 'Pengaturan & Keamanan',
          ikon: Icons.settings_outlined,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              _MenuTile(
                ikon: Icons.edit_outlined,
                judul: 'Ubah Nama',
                onTap: () => _ubahNama(user, nama),
              ),
              const Divider(height: 1, indent: 56),
              _MenuTile(
                ikon: Icons.lock_reset_rounded,
                judul: 'Ubah Password',
                subjudul: 'Kirim tautan reset ke email',
                onTap: () => _ubahPassword(user),
              ),
              const Divider(height: 1, indent: 56),
              _MenuTile(
                ikon: Icons.info_outline_rounded,
                judul: 'Tentang Aplikasi',
                onTap: _tentangAplikasi,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ---------------------------------------------------------- logout
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: const Text(
              'Keluar dari Akun',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
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
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(ikon, size: 18, color: AppColors.forestGreen),
                const SizedBox(width: 8),
                Text(
                  judul,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepForest,
                    fontSize: 14.5,
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
  final Color latar;

  const _AngkaRingkas({
    required this.nilai,
    required this.label,
    required this.warna,
    required this.latar,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: latar, shape: BoxShape.circle),
            child: Center(
              child: Text(
                '$nilai',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: warna,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
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
              Icon(ikon, size: 18, color: AppColors.sageGreen),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nilai,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: redup
                            ? AppColors.textMuted
                            : AppColors.deepForest,
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
    return ListTile(
      onTap: onTap,
      leading: Icon(ikon, color: AppColors.forestGreen, size: 22),
      title: Text(
        judul,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: AppColors.deepForest,
        ),
      ),
      subtitle: subjudul == null
          ? null
          : Text(
              subjudul!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textMuted,
        size: 20,
      ),
    );
  }
}
