# Tahap 2 — tampilan dan identitas aplikasi

## Perubahan untuk review

- Satu identitas visual untuk pelapor, admin, dan teknisi: biru tua, latar netral,
  kartu sederhana, dan pembatas yang ringan. Peran dikenali dari konteks halaman dan profil.
- Tema pusat ada di `lib/theme/tema_kampus.dart`. Tema warna per peran yang lama dihapus.
- Font Roboto disertakan lokal beserta lisensi, sehingga tidak bergantung pada unduhan font.
- Login disusun lebih ringkas, mendukung autofill, urutan input, dan label aksesibilitas
  pada tombol tampil/sembunyikan kata sandi.
- Tombol Google memakai teks yang jelas; gambar SVG jaringan yang sebelumnya tidak
  didukung `Image.network` dan ikon penggantinya dihapus.
- Beranda pelapor menampilkan tindakan buat laporan, empat ringkasan, dan laporan terbaru.
  Tombol melayang hanya muncul di tab Laporan agar tidak menduplikasi tombol utama beranda.
- Beranda admin menampilkan ringkasan verifikasi, penugasan, pekerjaan aktif, dan SLA;
  antrean tetap diurutkan menurut prioritas dan tanggal.
- Kartu laporan dipakai bersama di beranda, daftar laporan, dan antrean admin.
  Lokasi, status, prioritas, tanggal, nomor laporan, jumlah foto, teknisi, dan SLA tetap tersedia
  sesuai konteks dan peran.
- Tampilan profil, navigasi, detail, form, notifikasi, dan statistik mengikuti tema yang sama.
- Label kategori, tombol kirim, status laporan, dan grafik disesuaikan untuk teks yang diperbesar.
- Penghapusan tautan tutorial dari README ikut dalam perubahan ini; tutorial tetap terpisah di `docs`.

## Ikon aplikasi

Lambang gedung kampus dan tanda centang dibuat dari bentuk geometris pada
`lib/widgets/identitas_kampus.dart`. Lambang ini merupakan identitas aplikasi,
bukan logo resmi universitas.

- Ikon antarmuka menggunakan keluarga Material yang konsisten dan sebagian besar bergaya garis.
- Ikon launcher tersedia untuk Android, iOS, macOS, dan web.
- Android memiliki adaptive icon agar mengikuti bentuk ikon perangkat.
- Nama launcher Android dan metadata web ditampilkan sebagai Pengaduan Kampus.
- Aset pratinjau ukuran besar: `assets/branding/ikon-kampus.png`.
- Untuk membuat ulang aset raster dari sumber vektor:

  ```powershell
  flutter test --no-pub tool/generate_app_icons_test.dart
  ```

## Validasi

- `flutter analyze --no-pub`: bersih.
- `flutter test --no-pub --dart-define=PREVIEW_UI=true`: 32 pengujian lulus.
- Pengujian tata letak memeriksa 11 layar pada lebar 390 piksel dengan teks 100%,
  serta lebar 320 piksel dengan teks 140%, termasuk bagian setelah digulir.
- Preview widget tersedia di `build/ui-preview/`. Data pada preview adalah data contoh pengujian.
- `flutter build apk --debug --no-pub`: berhasil.
- APK uji lokal: `build/app/outputs/flutter-apk/app-debug.apk`.
- Build iOS/macOS tidak dijalankan di Windows; aset ikonnya sudah dibuat.

Pemasangan APK pada perangkat tetap dianjurkan untuk menilai kenyamanan penggunaan dan
bentuk ikon launcher di perangkat Anda. Jika ikon launcher masih tersimpan dalam cache,
hapus lalu pasang ulang aplikasi uji setelah memastikan data penting sudah tersimpan di Firebase.

## Push manual kedua

Tetap gunakan branch `samuel/firebase-laporan`, tanpa membuat branch baru untuk update ini:

```powershell
git branch --show-current
git add lib test tool assets android/app/src/main ios/Runner/Assets.xcassets/AppIcon.appiconset macos/Runner/Assets.xcassets/AppIcon.appiconset web pubspec.yaml README.md docs/TAMPILAN_TAHAP_2.md
git diff --cached --stat
git commit -m "feat: rapikan tampilan kampus dan ikon aplikasi"
git push
```

Direktori generated Linux dan file `macos/Flutter/GeneratedPluginRegistrant.swift` memiliki
perubahan sebelum pengerjaan. Perintah stage di atas tidak menyertakannya.

Update ini tidak menambahkan draf otomatis, push notification, komentar, atau konfirmasi hasil
perbaikan. Fitur tambahan dibahas dan dikerjakan pada tahap 3 setelah push kedua dikonfirmasi.
