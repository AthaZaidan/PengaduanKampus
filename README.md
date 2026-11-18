# Pengaduan Kampus

Aplikasi berbasis Flutter untuk sistem pelaporan dan pengaduan kerusakan fasilitas atau layanan di lingkungan kampus.

## Fitur Utama

- **Splash Screen & Sesi Otomatis**: Layar pembuka dengan pengecekan status autentikasi Firebase (`SplashScreen`) yang langsung mengarahkan ke beranda sesuai peran atau ke halaman masuk.
- **Autentikasi Lengkap**:
  - Registrasi akun pelapor (**Mahasiswa**, **Dosen**, **Staf**) beserta validasi NIM/NIP, email, dan nomor HP.
  - Masuk menggunakan **NIM 9 digit** atau **Email** dan kata sandi, **Masuk dengan Google** (`google_sign_in`), serta fitur **Lupa kata sandi** (kirim tautan reset via email).
- **Akses Berbasis Peran (`MainShell`)**:
  - **Pelapor (Mahasiswa / Dosen / Staf)**: Beranda ringkasan status, pembuatan laporan dengan form tervalidasi, draf otomatis di Firestore, lampiran foto opsional, daftar & pencarian laporan, statistik pribadi, konfirmasi hasil perbaikan atau permintaan pemeriksaan ulang.
  - **Teknisi**: Daftar tugas yang ditugaskan admin, pembaruan progres pengerjaan (`Ditugaskan` → `Dikerjakan` → `Selesai`) beserta catatan dan foto bukti sesudah penanganan, serta statistik kinerja.
  - **Admin Fasilitas**: Dashboard antrean kerja & SLA, verifikasi/penolakan laporan, penugasan dan penggantian teknisi, manajemen daftar lokasi kampus (`KelolaLokasiPage`), manajemen akun teknisi (tambah & hapus teknisi dengan pengecekan tugas aktif), dan statistik menyeluruh.
- **Lampiran Foto Terkompresi & Draf Otomatis**:
  - Foto sebelum/sesudah penanganan (maksimal 3 foto per jenis) dikompres, divalidasi ukuran/formatnya (`FotoFirestoreService`), dan disimpan sebagai Base64 pada subkoleksi Firestore `laporan/{id}/foto/{fotoId}`.
  - Draf formulir disimpan otomatis ke `users/{uid}/draf/aktif` dan foto draf disimpan sementara di penyimpanan perangkat (`FotoLokalService`).
- **Pelacakan Status, SLA, Filter, Notifikasi & Klarifikasi**:
  - Timeline riwayat status lengkap dengan pencatatan revisi dan transaksi Firestore (`LaporanRepository`).
  - Penanda batas waktu SLA berdasarkan prioritas (`Tinggi` 24 jam, `Sedang` 72 jam, `Rendah` 7 hari) melalui `SlaChip`.
  - Pencarian kata kunci dan filter lanjutan (`FilterLaporan`: kategori, prioritas, urutan, rentang tanggal).
  - Kolom komentar/klarifikasi laporan (`KomentarLaporan`) dan halaman notifikasi perubahan status serta komentar (`NotifikasiPage`) dengan status baca per pengguna.
- **Statistik & Visualisasi**: Ringkasan angka, diagram donat status, distribusi kategori dan prioritas, serta tren laporan 7 hari terakhir (`StatistikPage`).

## Persyaratan Sistem

- Flutter SDK `^3.47.2` (Dart SDK `^3.13.2`)
- Android Studio / VS Code dengan ekstensi Flutter & Dart
- Konfigurasi Firebase (`lib/firebase_options.dart`, `firestore.rules`, `storage.rules`)

## Menjalankan Aplikasi

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
5. Jalankan analisis statis dan unit/widget test:
   ```bash
   flutter analyze
   flutter test
   ```

## Struktur Folder

```
lib/
├── main.dart
├── firebase_options.dart
├── models/
│   ├── app_user.dart              Model pengguna & peran (mahasiswa, dosen, staf, teknisi, admin)
│   ├── filter_laporan.dart        Filter kategori, prioritas, rentang tanggal, & pengurutan
│   ├── laporan.dart               Model laporan, status, kategori, prioritas, SLA, & riwayat
│   └── statistik_laporan.dart     Agregasi statistik dan tren 7 hari terakhir
├── providers/
│   └── laporan_provider.dart      State management & alur transisi status laporan
├── services/
│   ├── akun_service.dart          Pembuatan & penghapusan akun teknisi oleh admin
│   ├── fitur_laporan_service.dart Draf, status baca notifikasi, lokasi, & komentar laporan
│   ├── foto_firestore_service.dart Validasi & penyimpanan foto Base64 di Firestore
│   ├── foto_lokal_native.dart     Penyimpanan foto draf lokal (Android/iOS/Desktop)
│   ├── foto_lokal_service.dart    Export bersyarat penyimpanan foto lokal
│   ├── foto_lokal_web.dart        Penyimpanan foto draf lokal (Web)
│   └── laporan_repository.dart    Sinkronisasi & transaksi Firestore untuk laporan
├── theme/
│   ├── app_theme.dart             Konfigurasi tema aplikasi
│   ├── palet_kampus.dart          Palet warna utama (AppColors)
│   └── tema_kampus.dart           ThemeData terpusat (TemaKampus)
├── widgets/
│   ├── foto_lokal.dart            Penampil gambar dari Firestore atau penyimpanan lokal
│   ├── foto_picker_field.dart     Input pemilih foto kamera/galeri
│   ├── foto_viewer.dart           Penampil foto layar penuh (geser & zoom)
│   ├── identitas_kampus.dart      Logo & identitas visual aplikasi
│   ├── komentar_laporan.dart      Panel klarifikasi/komentar laporan
│   ├── komponen_kampus.dart       Kartu laporan, badge status, & tampilan kosong
│   ├── pilihan_lokasi.dart        Pemilih lokasi kampus dari Firestore + input manual
│   ├── sla_chip.dart              Indikator batas waktu SLA
│   └── status_sinkronisasi.dart   Banner status sinkronisasi offline/cache/error
└── screens/
    ├── main_shell.dart            Router peran pengguna ke shell masing-masing
    ├── splash_screen.dart         Layar pembuka dan pengecekan sesi awal
    ├── authentication/
    │   ├── login_page.dart        Masuk (NIM/Email, Lupa Password, & Google Sign-In)
    │   └── register_page.dart     Pendaftaran akun pelapor (Mahasiswa, Dosen, Staf)
    ├── user/
    │   ├── user_shell.dart        Navigasi pelapor
    │   ├── home_page.dart         Beranda pelapor
    │   ├── user_laporan_page.dart Daftar laporan milik pelapor
    │   └── buat_laporan_page.dart Form buat laporan dengan draf otomatis & lampiran foto
    ├── teknisi/
    │   ├── teknisi_shell.dart     Navigasi teknisi
    │   ├── teknisi_tugas_page.dart Daftar tugas perbaikan teknisi
    │   └── teknisi_kinerja_page.dart Statistik kinerja teknisi
    ├── admin/
    │   ├── admin_shell.dart       Navigasi admin fasilitas
    │   ├── admin_dashboard_page.dart Dashboard antrean, SLA, & akses lokasi
    │   ├── admin_laporan_page.dart Daftar semua laporan lintas status
    │   ├── kelola_lokasi_page.dart Manajemen pilihan lokasi kampus
    │   ├── kelola_teknisi_page.dart Daftar teknisi, reset password, & hapus teknisi
    │   └── tambah_teknisi_page.dart Form tambah akun teknisi baru
    └── shared/
        ├── kerangka_navigasi.dart Kerangka navigasi bawah seragam
        ├── detail_laporan_page.dart Detail laporan, aksi per peran, timeline, & klarifikasi
        ├── riwayat_page.dart      Daftar laporan bertab dengan pencarian & filter
        ├── statistik_page.dart    Halaman visualisasi statistik laporan
        ├── notifikasi_page.dart   Daftar notifikasi perubahan status & komentar baru
        └── profile_page.dart      Profil akun, ringkasan, edit profil, & keluar akun
```

## Manajemen Akun Teknisi oleh Admin

1. Masuk sebagai **Admin Fasilitas**, buka tab **Teknisi**.
2. Ketuk **Tambah Teknisi**, isi nama, email, nomor HP, dan password awal (atau gunakan tombol *Buat password acak*).
3. Salin kredensial yang tampil dan berikan kepada teknisi. Akun dibuat melalui instance Firebase sekunder (`AkunService`) sehingga sesi admin tetap aktif.
4. Untuk menghapus akun teknisi, pilih menu aksi pada kartu teknisi lalu konfirmasi pengetikan `HAPUS` (penghapusan ditahan bila teknisi masih memiliki laporan berstatus `Dikerjakan`).
