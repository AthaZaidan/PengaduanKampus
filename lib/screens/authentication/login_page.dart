import 'package:flutter/material.dart';

import '../../widgets/identitas_kampus.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../main_shell.dart';
import '../../providers/laporan_provider.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordHidden = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  static final _polaNim = RegExp(r'^[0-9]{9}$');

  Future<String> _selesaikanEmail(String input) async {
    final bersih = input.trim();
    if (!_polaNim.hasMatch(bersih)) return bersih;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('nim', isEqualTo: bersih)
          .limit(1)
          .get();
      final email = snap.docs.firstOrNull?.data()['email']?.toString().trim();
      if (email != null && email.isNotEmpty) return email;
    } catch (_) {
      // Aturan Firestore membatasi baca profil sebelum masuk; gunakan domain kampus.
    }
    return '$bersih@students.usu.ac.id';
  }

  void _snack(String pesan, {bool error = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: error
            ? const Color(0xFFB84A4A)
            : const Color(0xFF406E49),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 1. LOGIKALOGIN MANUAL (Bisa NIM 9 Digit ATAU Email)
  Future<void> _loginManual() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final password = _passwordController.text.trim();
      final emailToAuth = await _selesaikanEmail(_identifierController.text);

      // Autentikasi ke Firebase Auth
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailToAuth,
        password: password,
      );

      if (!mounted) return;
      _navigateToMainShell();
    } on FirebaseAuthException catch (e) {
      String message = 'Login gagal.';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        message = 'NIM/Email atau Password salah.';
      } else if (e.code == 'wrong-password') {
        message = 'Password salah.';
      } else if (e.code == 'invalid-email') {
        message = 'Format NIM/Email tidak valid.';
      }
      _snack(message);
    } catch (e) {
      _snack('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _lupaPassword() async {
    final input = await showDialog<String>(
      context: context,
      builder: (_) => _DialogLupaPassword(
        awal: _identifierController.text.trim(),
      ),
    );
    if (input == null || input.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final email = await _selesaikanEmail(input);
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _snack('Tautan reset kata sandi dikirim ke $email.', error: false);
    } on FirebaseAuthException catch (e) {
      final pesan = switch (e.code) {
        'invalid-email' => 'Format NIM/Email tidak valid.',
        'user-not-found' => 'Akun tidak ditemukan.',
        'too-many-requests' => 'Terlalu banyak percobaan. Coba lagi nanti.',
        _ => 'Gagal mengirim tautan reset kata sandi.',
      };
      _snack(pesan);
    } catch (_) {
      _snack('Gagal mengirim tautan reset kata sandi. Coba lagi nanti.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. LOGIKA LOGIN GOOGLE
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; // User membatalkan login
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // Cek / Simpan data user ke Firestore jika baru pertama kali login
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'uid': user.uid,
                'name': user.displayName ?? '',
                'email': user.email ?? '',
                'nim': '-',
                'phone': '-',
                'role': 'student',
                'createdAt': FieldValue.serverTimestamp(),
              });
        }
      }

      if (!mounted) return;
      _navigateToMainShell();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login Google Gagal: ${e.toString()}'),
          backgroundColor: const Color(0xFFB84A4A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToMainShell() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MainShell(provider: LaporanProvider.shared),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const LambangKampus(ukuran: 48),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pengaduan Kampus',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'LAYANAN FASILITAS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    letterSpacing: 1.3,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Text(
                        'Masuk ke akun Anda',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Sampaikan kendala fasilitas dan pantau proses penanganannya dalam satu layanan.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _identifierController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        decoration: const InputDecoration(
                          labelText: 'NIM atau email',
                          hintText: 'Masukkan NIM atau alamat email',
                          helperText: 'NIM untuk email students.usu.ac.id. Email lain: gunakan alamat lengkap.',
                          helperMaxLines: 2,
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'NIM atau email wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _isPasswordHidden,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) {
                          if (!_isLoading) _loginManual();
                        },
                        decoration: InputDecoration(
                          labelText: 'Kata sandi',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _isPasswordHidden
                                ? 'Tampilkan kata sandi'
                                : 'Sembunyikan kata sandi',
                            icon: Icon(
                              _isPasswordHidden
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () => setState(
                              () => _isPasswordHidden = !_isPasswordHidden,
                            ),
                          ),
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Kata sandi wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isLoading ? null : _lupaPassword,
                          child: const Text('Lupa kata sandi?'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _isLoading ? null : _loginManual,
                        child: _isLoading
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Masuk'),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'atau',
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton(
                        onPressed: _isLoading ? null : _signInWithGoogle,
                        child: const Text('Masuk dengan Google'),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Belum memiliki akun?',
                            style: TextStyle(
                              fontSize: 13,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterPage(),
                                    ),
                                  ),
                            child: const Text('Daftar akun'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Untuk mahasiswa, dosen, dan staf kampus.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogLupaPassword extends StatefulWidget {
  final String awal;

  const _DialogLupaPassword({required this.awal});

  @override
  State<_DialogLupaPassword> createState() => _DialogLupaPasswordState();
}

class _DialogLupaPasswordState extends State<_DialogLupaPassword> {
  final _formKey = GlobalKey<FormState>();
  late final _kontrol = TextEditingController(text: widget.awal);

  @override
  void dispose() {
    _kontrol.dispose();
    super.dispose();
  }

  void _kirim() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _kontrol.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset Kata Sandi'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Masukkan NIM atau email terdaftar untuk menerima tautan reset kata sandi.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _kontrol,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'NIM atau email',
                  hintText: 'Contoh: 241402101 atau email@kampus.ac.id',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                onFieldSubmitted: (_) => _kirim(),
                validator: (v) {
                  final nilai = v?.trim() ?? '';
                  if (nilai.isEmpty) return 'NIM atau email wajib diisi';
                  final isNim = RegExp(r'^[0-9]{9}$').hasMatch(nilai);
                  final isEmail = nilai.contains('@') && nilai.contains('.');
                  if (!isNim && !isEmail) {
                    return 'Masukkan NIM 9 digit atau email yang valid';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _kirim,
          child: const Text('Kirim Tautan'),
        ),
      ],
    );
  }
}
