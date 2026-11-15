import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../theme/app_theme.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  // Controller Input Field
  final _namaController = TextEditingController();
  final _nimController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordHidden = true;
  bool _isLoading = false;

  // Jenis pengguna (akun admin & teknisi dibuat oleh admin, bukan lewat form ini)
  PeranPengguna _peran = PeranPengguna.mahasiswa;

  @override
  void dispose() {
    _namaController.dispose();
    _nimController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final nim = _nimController.text.trim();
      final nama = _namaController.text.trim();
      final phone = _phoneController.text.trim();

      // 1. Buat Akun di Firebase Auth menggunakan Email & Password
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user?.uid;

      // Update Display Name di profil Firebase Auth
      await userCredential.user?.updateDisplayName(nama);

      // 2. Simpan Data Lengkap ke Cloud Firestore (Collection: users)
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'uid': uid,
          'name': nama,
          'nim': nim,
          'email': email,
          'phone': phone,
          'role': _peran.kode,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registrasi berhasil! Silakan masuk dengan akun Anda.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Kembali ke Halaman Login
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = 'Registrasi gagal.';
      if (e.code == 'email-already-in-use') {
        message = 'Email ini sudah terdaftar. Silakan gunakan email lain.';
      } else if (e.code == 'weak-password') {
        message = 'Password terlalu lemah (minimal 6 karakter).';
      } else if (e.code == 'invalid-email') {
        message = 'Format email tidak valid.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Registrasi Akun Baru'),
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Form(
            key: _formKey,
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderSubtle, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.deepForest.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Lengkapi Data Diri',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.deepForest,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Daftarkan akun untuk membuat dan memantau laporan kampus.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // 1. Input Nama Lengkap
                  TextFormField(
                    controller: _namaController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      hintText: 'Masukkan nama sesuai KTM / KTP',
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: AppColors.sageGreen,
                        size: 20,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Nama lengkap wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Jenis pengguna selector
                  const Text(
                    'Daftar sebagai',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.deepForest,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<PeranPengguna>(
                      showSelectedIcon: false,
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith((
                          states,
                        ) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.forestGreen;
                          }
                          return AppColors.surfaceContainerLow;
                        }),
                        foregroundColor: WidgetStateProperty.resolveWith((
                          states,
                        ) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.white;
                          }
                          return AppColors.deepForest;
                        }),
                        side: WidgetStateProperty.all(
                          const BorderSide(color: AppColors.borderSubtle),
                        ),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      segments: const [
                        ButtonSegment(
                          value: PeranPengguna.mahasiswa,
                          label: Text(
                            'Mahasiswa',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        ButtonSegment(
                          value: PeranPengguna.dosen,
                          label: Text(
                            'Dosen',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        ButtonSegment(
                          value: PeranPengguna.staf,
                          label: Text(
                            'Staf',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                      selected: {_peran},
                      onSelectionChanged: (v) =>
                          setState(() => _peran = v.first),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Input NIM (mahasiswa: tepat 9 digit) / NIP-ID (dosen, staf)
                  TextFormField(
                    controller: _nimController,
                    keyboardType: TextInputType.number,
                    maxLength: _peran == PeranPengguna.mahasiswa ? 9 : 20,
                    decoration: InputDecoration(
                      labelText: _peran == PeranPengguna.mahasiswa
                          ? 'NIM (9 Digit)'
                          : 'NIP / ID Pegawai',
                      hintText: _peran == PeranPengguna.mahasiswa
                          ? 'Contoh: 241402101'
                          : 'Contoh: 198501012010011001',
                      prefixIcon: const Icon(
                        Icons.badge_outlined,
                        color: AppColors.sageGreen,
                        size: 20,
                      ),
                      counterText: "",
                    ),
                    validator: (v) {
                      final nilai = v?.trim() ?? '';
                      final mahasiswa = _peran == PeranPengguna.mahasiswa;
                      if (nilai.isEmpty) {
                        return mahasiswa
                            ? 'NIM wajib diisi'
                            : 'NIP / ID wajib diisi';
                      }
                      if (mahasiswa && nilai.length != 9) {
                        return 'NIM harus terdiri dari 9 digit angka';
                      }
                      if (!mahasiswa && nilai.length < 5) {
                        return 'NIP / ID minimal 5 digit';
                      }
                      if (!RegExp(r'^[0-9]+$').hasMatch(nilai)) {
                        return mahasiswa
                            ? 'NIM hanya boleh berisi angka'
                            : 'NIP / ID hanya boleh berisi angka';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 3. Input Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Contoh: nama@students.usu.ac.id / email aktif',
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: AppColors.sageGreen,
                        size: 20,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Email wajib diisi';
                      }
                      if (!v.contains('@') || !v.contains('.')) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 4. Input Nomor HP
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Nomor HP / WhatsApp',
                      hintText: 'Contoh: 081234567890',
                      prefixIcon: Icon(
                        Icons.phone_outlined,
                        color: AppColors.sageGreen,
                        size: 20,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Nomor HP wajib diisi';
                      }
                      if (v.trim().length < 10 || v.trim().length > 13) {
                        return 'Nomor HP tidak valid (10-13 digit)';
                      }
                      if (!RegExp(r'^[0-9]+$').hasMatch(v.trim())) {
                        return 'Nomor HP hanya boleh berisi angka';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 5. Input Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _isPasswordHidden,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Minimal 6 karakter',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: AppColors.sageGreen,
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordHidden
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        onPressed: () => setState(
                          () => _isPasswordHidden = !_isPasswordHidden,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password wajib diisi';
                      if (v.length < 6) return 'Password minimal 6 karakter';
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Tombol Register
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _register(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forestGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
                        : const Text(
                            'Daftar Sekarang',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
