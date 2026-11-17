# Tahap 3 — fitur tambahan

Source code disiapkan untuk review pada branch `samuel/firebase-laporan`.
Belum ada commit, push, deploy Rules/Functions, pengaktifan billing, atau pengiriman push
ke perangkat asli yang dilakukan oleh agen.

## Fitur dan cara mencoba

### Draf otomatis

- Teks, kategori, prioritas, dan lokasi disimpan otomatis setelah jeda mengetik 600 ms.
- Draf aktif ada di `users/{uid}/draf/aktif`; hanya pemilik akun boleh mengaksesnya.
- Foto diunggah terlebih dahulu ke Storage `draf/{uid}/...`. Status unggah ditampilkan;
  foto yang belum selesai diunggah belum menjadi lampiran draf.
- Form berikutnya memulihkan draf. Jika pemulihan gagal, pengiriman diblokir agar draf lama
  tidak tertimpa form kosong. Gunakan tombol coba pulihkan.
- Tombol Hapus draf membuang isi form dan lampirannya setelah konfirmasi pengguna.
- Saat laporan resmi dikirim, foto disalin ke path laporan dan draf dibersihkan sesudahnya.
  Pembersihan memeriksa ID laporan di dalam transaksi agar tidak menghapus draf baru.
- Draf yang laporannya sudah terkirim diperiksa dan dibersihkan saat form dibuka kembali.
  Pengiriman ulang ID yang sama ditolak dengan informasi bahwa laporan sudah terkirim.
- Satu akun memiliki satu draf aktif. Jika diedit bersamaan pada beberapa perangkat,
  isi terakhir yang disinkronkan akan menjadi draf akun tersebut.
- Cache Firestore pada Android/iOS dapat membantu pemulihan ketika offline; pesan tersimpan
  di Firebase baru ditampilkan setelah server mengonfirmasi. Foto tetap memerlukan koneksi.
- Keluar aplikasi secara paksa sebelum jeda simpan selesai dapat kehilangan ketikan terakhir.
  Menutup halaman atau aplikasi secara normal juga memicu penyimpanan draf.

### Filter laporan

Buka ikon filter pada Laporan Saya, Semua Laporan, atau Tugas Saya. Pilih kategori,
prioritas, rentang tanggal, dan urutan terbaru/terlama/prioritas. Filter bekerja bersama
pencarian dan tab status. Tanggal akhir mencakup seluruh hari yang dipilih. Tombol Reset
menghapus filter tambahan.

### Konfirmasi hasil perbaikan

- Pada laporan Selesai, pemilik laporan dapat memilih Perbaikan sudah sesuai.
- Pemilik juga dapat meminta pemeriksaan ulang dengan alasan wajib sebelum mengonfirmasi.
  Laporan kembali Dikerjakan oleh teknisi yang sama; admin dapat memantaunya.
- Foto dan riwayat sebelumnya tetap ada. Batas tiga foto sesudah berlaku secara kumulatif
  per laporan. Jika sudah penuh, pemeriksaan berikutnya tetap dapat dicatat tanpa foto baru.
- Setelah dikonfirmasi, laporan tidak dapat dibuka ulang melalui alur ini.
- Waktu konfirmasi tidak menimpa waktu pekerjaan selesai untuk perhitungan statistik/SLA.
- Rules server membatasi tindakan ini pada UID pemilik laporan.

### Lokasi kampus

Admin membuka Profil → Kelola lokasi kampus, lalu memasukkan nama gedung/lantai/ruang
yang benar-benar tersedia. Lokasi otomatis menjadi pilihan pada form laporan. Input
manual tetap tersedia untuk lokasi yang belum terdaftar. Menghapus pilihan lokasi tidak
mengubah lokasi yang sudah disimpan pada laporan lama.

### Klarifikasi

Bagian Klarifikasi laporan di detail menyediakan komentar teks untuk pelapor, admin,
dan teknisi yang ditugaskan. Komentar tersimpan di `laporan/{id}/komentar`, bersifat
tetap (tidak diedit/dihapus), maksimal 2000 karakter. Layar menampilkan 100 komentar terakhir.
Kegagalan kirim mempertahankan teks supaya dapat dicoba lagi.

### Notifikasi

- Daftar perubahan status tetap berasal dari timeline laporan, dengan penanda Belum dibaca.
- Opsi Tandai semua dibaca dan ketukan pada pemberitahuan menyimpan status baca per akun.
- Admin juga menerima entri laporan baru di dalam aplikasi.
- Pemberitahuan komentar di pusat notifikasi dibuat oleh backend Functions.
- Android/iOS dapat mendaftarkan push lewat Notifikasi → menu opsi → Aktifkan notifikasi push.
- Saat aplikasi aktif, push ditampilkan sebagai pesan di dalam aplikasi. Saat di latar,
  payload notification ditampilkan oleh sistem operasi. Ketukan membuka pusat notifikasi.
- Isi push sengaja umum; judul, lokasi, dan uraian masalah tidak ditampilkan pada layar kunci.
- Backend mengirim ke pelapor, teknisi yang berhak, dan admin, dengan mengecualikan pelaku.
  Token tidak valid dibersihkan. Maksimal 20 perangkat terbaru per akun diperiksa;
  perangkat yang tidak memperbarui registrasi selama 60 hari tidak dikirimi push.
- Web/macOS tetap dapat memakai daftar notifikasi. Aktivasi push pada platform itu
  belum ditambahkan dalam tahap ini.

## Aktivasi manual Firebase

Terapkan aturan baru sebelum mencoba APK tahap ini. Dengan Rules lama, draf/komentar/
lokasi/status baca akan ditolak dan form draf dapat terkunci pada kegagalan pemulihan.

```powershell
firebase login
firebase deploy --only "firestore:rules,storage" --project lapor-in-372dc
```

Fitur draf, filter, lokasi, konfirmasi, komentar, dan penanda baca dapat dipakai setelah
Rules aktif. Pengiriman push serta pemberitahuan komentar di pusat notifikasi memerlukan
dua Functions berikut:

```powershell
npm --prefix functions ci
firebase deploy --only "functions:perubahanLaporan,functions:komentarLaporan" --project lapor-in-372dc
```

Deploy Functions ke produksi memerlukan paket Blaze/billing. Pengaturan itu tidak diubah
otomatis. Lihat [panduan Cloud Functions Firebase](https://firebase.google.com/docs/functions/get-started).
Runtime backend diatur ke Node.js 22, region `asia-southeast2`, dan maksimal 3 instance
per fungsi. Sesuaikan region sebelum deploy jika pengelola project memerlukan lokasi lain.

Pada Android, gunakan perangkat/emulator dengan Google Play services dan berikan izin
notifikasi. Pada iOS, pengelola perlu menyiapkan APNs key di Firebase dan capability Push
Notifications/Background Modes di Xcode. Lihat [penyiapan FCM Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/get-started).
Build dan pengiriman push iOS belum diuji dari Windows.

## Pengujian

```powershell
flutter analyze --no-pub
flutter test --no-pub
node --test functions/test/notifikasi.test.cjs
# Gunakan konfigurasi Java seperti pada FIREBASE_SETUP.md jika diperlukan.
firebase emulators:exec --only firestore,storage --project demo-pengaduan-kampus "node --test test/firebase_rules_test.cjs"
flutter build apk --debug --no-pub
```

Pengujian lokal mencakup filter, pemulihan/simpan draf, kegagalan pemulihan, alur
pemeriksaan ulang/konfirmasi, ketepatan waktu selesai, akses Rules, dan pemilihan
penerima/payload push. Pengiriman FCM ke perangkat asli belum diuji; lakukan setelah
deploy backend dan registrasi perangkat. APK uji ada di
`build/app/outputs/flutter-apk/app-debug.apk`.

Untuk uji manual, gunakan tiga akun pada pelapor/admin/teknisi. Buat draf dan buka ulang
form; kirim laporan; tugaskan dan selesaikan; ajukan pemeriksaan ulang; selesaikan lagi;
konfirmasikan. Coba komentar dan status baca dari akun berbeda. Letakkan aplikasi di
latar melalui tombol Home saat menguji push, lalu ubah laporan dari akun lain.

## Push manual ketiga

```powershell
git branch --show-current
git add .gitignore firebase.json firestore.rules storage.rules pubspec.yaml pubspec.lock lib test functions android/app/src/main docs/FITUR_TAHAP_3.md
git diff --cached --stat
git commit -m "feat: tambah draf filter klarifikasi dan notifikasi"
git push origin samuel/firebase-laporan
```

Perintah ini tidak menyertakan berkas generated Linux/macOS dan berkas asing di root
yang sudah ada sebelum tahap ini. `functions/node_modules` juga tidak ikut karena
diabaikan oleh `.gitignore`. Tidak perlu memakai `git add .`.
