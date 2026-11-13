import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/app_user.dart';
import '../../services/akun_service.dart';

/// Admin: form untuk membuat akun teknisi baru.
class TambahTeknisiPage extends StatefulWidget {
  final AppUser admin;

  const TambahTeknisiPage({super.key, required this.admin});

  @override
  State<TambahTeknisiPage> createState() => _TambahTeknisiPageState();
}

class _TambahTeknisiPageState extends State<TambahTeknisiPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _passwordTersembunyi = true;
  bool _sedangMenyimpan = false;

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Password acak 10 karakter (tanpa karakter yang mudah tertukar: 0/O, 1/l/I).
  void _buatPasswordAcak() {
    const huruf = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
    final acak = Random.secure();
    final sandi =
        List.generate(10, (_) => huruf[acak.nextInt(huruf.length)]).join();
    setState(() {
      _passwordController.text = sandi;
      _passwordTersembunyi = false; // tampilkan agar admin bisa mencatatnya
    });
  }

  void _snack(String pesan, {bool error = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor:
            error ? Colors.red.shade700 : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sedangMenyimpan = true);

    final nama = _namaController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final telepon = _phoneController.text.trim();
    final password = _passwordController.text;

    try {
      await AkunService.buatAkunTeknisi(
        pembuat: widget.admin,
        nama: nama,
        email: email,
        telepon: telepon,
        password: password,
      );
      if (!mounted) return;
      await _tampilkanKredensial(nama: nama, email: email, password: password);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      switch (e.code) {
        case 'email-already-in-use':
          _snack('Email ini sudah terdaftar. Gunakan email lain.');
          break;
        case 'invalid-email':
          _snack('Format email tidak valid.');
          break;
        case 'weak-password':
          _snack('Password terlalu lemah (minimal 6 karakter).');
          break;
        case 'network-request-failed':
          _snack('Tidak ada koneksi internet.');
          break;
        default:
          _snack('Gagal membuat akun: ${e.message ?? e.code}');
      }
    } on FirebaseException catch (e) {
      if (!mounted) return;
      if (e.code == 'permission-denied') {
        _snack('Akun gagal disimpan: izin Firestore ditolak. Pastikan Rules '
            'mengizinkan admin menulis ke koleksi "users".');
      } else {
        _snack('Gagal menyimpan data teknisi: ${e.message ?? e.code}');
      }
    } catch (e) {
      if (!mounted) return;
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _sedangMenyimpan = false);
    }
  }

  Future<void> _tampilkanKredensial({
    required String nama,
    required String email,
    required String password,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Akun teknisi dibuat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Berikan data login berikut kepada $nama:'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(
                'Email    : $email\nPassword : $password',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Password hanya ditampilkan sekarang. Teknisi dapat '
              'menggantinya lewat Profil \u2192 Ubah Password.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: 'Email: $email\nPassword: $password'),
              );
              if (!ctx.mounted) return;
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text('Data login disalin.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Salin'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Teknisi'),
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 20, color: scheme.primary),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Akun teknisi dibuat langsung oleh admin. Setelah '
                          'tersimpan, teknisi masuk dengan email dan '
                          'password di bawah ini.',
                          style: TextStyle(fontSize: 12.5, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _namaController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    hintText: 'Contoh: Rudi Hartono',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nama lengkap wajib diisi'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'teknisi@kampus.ac.id',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    final nilai = v?.trim() ?? '';
                    if (nilai.isEmpty) return 'Email wajib diisi';
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(nilai)) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Nomor HP / WhatsApp',
                    hintText: 'Contoh: 081234567890',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) {
                    final nilai = v?.trim() ?? '';
                    if (nilai.isEmpty) return 'Nomor HP wajib diisi';
                    if (!RegExp(r'^[0-9]+$').hasMatch(nilai)) {
                      return 'Nomor HP hanya boleh berisi angka';
                    }
                    if (nilai.length < 10 || nilai.length > 13) {
                      return 'Nomor HP tidak valid (10-13 digit)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _passwordTersembunyi,
                  decoration: InputDecoration(
                    labelText: 'Password Awal',
                    hintText: 'Minimal 6 karakter',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordTersembunyi
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () => setState(
                          () => _passwordTersembunyi = !_passwordTersembunyi),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password wajib diisi';
                    if (v.length < 6) return 'Password minimal 6 karakter';
                    return null;
                  },
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _sedangMenyimpan ? null : _buatPasswordAcak,
                    icon: const Icon(Icons.casino_outlined, size: 18),
                    label: const Text('Buat password acak'),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _sedangMenyimpan ? null : _simpan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _sedangMenyimpan
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Buat Akun Teknisi',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
