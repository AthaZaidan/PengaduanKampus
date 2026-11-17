# Pengaduan Kampus 

Aplikasi mobile berbasis Flutter untuk sistem pelaporan dan pengaduan fasilitas atau layanan di lingkungan kampus.
 Fitur Utama (Rencana Pengembangan)
- **Autentikasi**: Login & Registrasi mahasiswa/staf
- **Buat Laporan**: Form pengaduan dengan deskripsi, kategori, dan lampiran foto
- **Status Laporan**: Pemantauan progres penanganan pengaduan (Diajukan, Diproses, Selesai)
- **Riwayat Pengaduan**: Riwayat laporan yang telah diajukan pengguna

Persyaratan Sistem
- Flutter SDK `^3.13.2` / `^3.47.2`
- Dart SDK
- Android Studio / VS Code dengan ekstensi Flutter & Dart

Menjalankan Aplikasi

1. Clone repositori ini:
   ```bash
   git clone https://github.com/AthaZaidan/PengaduanKampus.git
   ```
2. Masuk ke folder proyek:
   ```bash
   cd PengaduanKampus
   ```
3. Unduh dependencies:
   ```bash
   flutter pub get
   ```
4. Jalankan aplikasi:
   ```bash
   flutter run
   ```

## Struktur Folder

```
lib/
├── main.dart
├── firebase_options.dart
├── models/            app_user, laporan, statistik_laporan
├── providers/         laporan_provider
├── services/          akun_service (admin membuat akun teknisi)
├── theme/             tema_aksen
├── widgets/           komponen kecil yang dipakai ulang
└── screens/
    ├── main_shell.dart        router: baca peran -> pilih shell di bawah
    ├── authentication/        login_page, register_page
    ├── user/                  pelapor (mahasiswa, dosen, staf)
    │   ├── user_shell.dart
    │   ├── home_page.dart
    │   ├── user_laporan_page.dart
    │   └── buat_laporan_page.dart
    ├── teknisi/               teknisi
    │   ├── teknisi_shell.dart
    │   ├── teknisi_tugas_page.dart
    │   └── teknisi_kinerja_page.dart
    ├── admin/                 admin fasilitas
    │   ├── admin_shell.dart
    │   ├── admin_dashboard_page.dart
    │   ├── admin_laporan_page.dart
    │   ├── kelola_teknisi_page.dart
    │   └── tambah_teknisi_page.dart
    └── shared/                dipakai lebih dari satu peran
        ├── kerangka_navigasi.dart
        ├── detail_laporan_page.dart
        ├── riwayat_page.dart
        ├── statistik_page.dart
        ├── notifikasi_page.dart
        └── profile_page.dart
```

## Menambah Akun Teknisi

1. Masuk sebagai admin, buka tab **Teknisi**.
2. Ketuk **Tambah Teknisi**, isi nama, email, nomor HP, dan password awal
   (atau pakai tombol *Buat password acak*).
3. Salin data login yang tampil, lalu berikan ke teknisi. Teknisi yang baru
   dibuat otomatis muncul di daftar pilihan saat admin menugaskan laporan.

Akun dibuat lewat instance Firebase sekunder (`AkunService`), jadi sesi admin
tetap login. Dokumen `users/{uid}` ditulis dengan sesi admin, sehingga
**Firestore Rules harus mengizinkan admin menulis ke koleksi `users`**.
