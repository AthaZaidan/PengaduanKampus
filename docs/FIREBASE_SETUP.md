# Tahap 1 — penyimpanan Firebase

Implementasi ini memakai project `lapor-in-372dc` sesuai `lib/firebase_options.dart`.
Push Git hanya mengirim source code. Push tidak menerapkan Firestore/Storage Rules.
Belum ada deploy atau perubahan data di project Firebase asli yang dilakukan pada tahap ini.

## Perubahan

- Laporan produksi berasal dari Firestore, tanpa data contoh yang dibuat ulang saat aplikasi dibuka.
- Laporan baru, verifikasi, penolakan, penugasan/ganti teknisi, mulai kerja, dan penyelesaian disimpan ke server.
- Status, catatan, riwayat, UID pelaku, waktu pembaruan server, dan revisi disimpan dalam satu transaksi.
- Revisi diperiksa ulang untuk menolak pembaruan dari status yang sudah usang.
- Layar daftar, statistik, detail, dan notifikasi dalam aplikasi mengikuti snapshot laporan sesuai hak akses.
- Foto sebelum/sesudah ada di Storage. Firestore menyimpan path privat, bukan bytes/base64 atau URL publik.
- Foto dibaca melalui SDK Firebase Storage agar akses diperiksa oleh Rules.
- Tombol simpan menunggu konfirmasi server, mencegah pengiriman ganda, dan menampilkan kegagalan.
- Form menggunakan ID yang tetap selama halaman terbuka agar retry tidak membuat laporan ganda.
- Data yang ditampilkan dibersihkan saat sesi berganti. Hasil permintaan sesi lama diabaikan.
- Ubah nama profil menunggu transaksi Firestore. Nama Firebase Auth diselaraskan setelahnya.
- Login NIM memakai alamat `NIM@students.usu.ac.id`. Akun email lain harus memakai email lengkap.
  Koleksi profil tidak lagi dicari sebelum autentikasi.

## Aktivasi manual pada project asli

1. Buka Firebase Console untuk project `lapor-in-372dc`.
2. Pastikan Firebase Authentication untuk Email/Password dan Google yang digunakan aplikasi aktif.
3. Pastikan Cloud Firestore database `(default)` sudah dibuat.
4. Pastikan bucket Storage `lapor-in-372dc.firebasestorage.app` tersedia dan dapat dipakai.
   Periksa persyaratan paket/billing yang ditampilkan Console sebelum mengaktifkan layanan berbayar.
5. Pastikan setiap akun memiliki dokumen `users/{uid}`. Field minimal: `uid`, `name`, `email`, `role`.
   Nilai peran: `mahasiswa`/`student`, `dosen`, `staf`/`staff`, `admin`, atau `teknisi`.
   Admin pertama ditetapkan oleh pengelola project melalui Console, bukan registrasi publik.
6. Bandingkan dan simpan salinan Rules lama jika project sudah digunakan aplikasi lain.
   Rules dalam repo ini memberi akses pada `users`, `laporan`, dan path foto laporan; path lain ditolak.
7. Dari folder proyek, jalankan sendiri:

   ```powershell
   firebase login
   firebase deploy --only firestore:rules,storage --project lapor-in-372dc
   ```

   Ini menerapkan `firestore.rules` dan `storage.rules`. Jika Console/CLI meminta izin
   agar Storage Rules dapat membaca Firestore, selesaikan pengaturan akses lintas layanan tersebut.

8. Jalankan `flutter run` lalu uji dengan akun pelapor, admin, dan teknisi.

## Uji penerimaan pada perangkat

1. Pelapor membuat laporan dengan foto. Tunggu pesan berhasil, tutup aplikasi sepenuhnya,
   lalu masuk lagi: laporan dan foto harus tetap ada.
2. Pada perangkat lain, admin melihat laporan itu, memverifikasi, lalu menugaskan teknisi.
3. Pelapor melihat perubahan status tanpa membuat ulang laporan.
4. Teknisi yang ditugaskan mulai bekerja lalu menyelesaikan dengan foto sesudah dan catatan.
5. Pelapor melihat status akhir, foto, catatan, dan timeline yang sama setelah aplikasi dibuka ulang.
6. Akun pelapor lain tidak bisa membaca laporan/foto tersebut; teknisi lain tidak melihat tugasnya.
7. Matikan koneksi lalu coba kirim/perbarui: aplikasi tidak boleh mengumumkan sukses server.
   Sambungkan kembali dan coba lagi. Pastikan tidak ada laporan ganda.
8. Buka laporan yang sama pada dua sesi admin. Setelah sesi pertama mengubahnya,
   tindakan berdasarkan revisi lama harus ditolak atau meminta pemeriksaan status terbaru.

## Pengujian lokal

```powershell
flutter analyze --no-pub
flutter test --no-pub
```

Pengujian Rules menggunakan REST emulator dan Node bawaan tanpa dependency npm tambahan:

```powershell
# Jika Java belum ada di PATH, sesuaikan lokasi JDK berikut.
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
firebase emulators:exec --only firestore,storage --project demo-pengaduan-kampus "node --test test/firebase_rules_test.cjs"
```

ID `demo-pengaduan-kampus` sengaja berbeda dari project asli. Pengujian tidak deploy Rules
dan tidak memakai akun/data asli.

## Batas tahap 1

- Pengajuan/perubahan resmi memerlukan koneksi server. Cache tetap bisa ditampilkan, dengan penanda
  bahwa data belum dikonfirmasi server. Belum ada antrean pengiriman foto saat offline.
- Form yang gagal dikirim tetap berada di halaman yang sama. Penyimpanan draf setelah aplikasi
  ditutup masuk tahap fitur tambahan, bukan tahap ini.
- Notifikasi yang tersedia adalah daftar perubahan di dalam aplikasi. Push notification belum ditambahkan.
- Maksimal 3 foto per kelompok sebelum/sesudah, masing-masing maksimal 5 MB; JPEG, PNG, atau WebP.
- Upload dan dokumen Firestore merupakan dua layanan terpisah. Jika transaksi gagal, aplikasi berusaha
  membersihkan foto yang belum direferensikan. Koneksi yang terputus mendadak bisa menyisakan berkas
  tanpa laporan; pembersihan terjadwal dapat ditambahkan saat tersedia backend terkelola.
- Laporan contoh lama hanya berada di memori dan tidak dimigrasikan otomatis menjadi laporan asli.
- Pengujian pada project Firebase asli/perangkat tetap perlu dijalankan setelah aktivasi manual.

## Push manual pertama

Saat pengerjaan dimulai branch aktif adalah `main`. Untuk membuat satu branch pengembangan
yang dipakai untuk ketiga update, jalankan sendiri (atau gunakan nama branch pilihan Anda):

```powershell
git switch -c pengembangan-aplikasi
git add lib test docs README.md firebase.json firestore.rules storage.rules
git diff --cached --stat
git commit -m "feat: simpan laporan dan foto ke Firebase"
git push -u origin pengembangan-aplikasi
```

File generated Linux/macOS sudah memiliki perubahan sebelum tahap ini. Perintah `git add`
di atas sengaja tidak menyertakan direktori tersebut; tinjau perubahan itu secara terpisah.
Setelah push pertama, konfirmasikan sebelum tahap tampilan/ikon dimulai agar batas ketiga update jelas.
