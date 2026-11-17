import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Berkas browser disimpan pada IndexedDB lokal, tanpa upload ke server.
class FotoLokalService {
  static final instance = FotoLokalService();

  void _validasi(String path) {
    if (!RegExp(r'^(draf|laporan)/[A-Za-z0-9_/-]+$').hasMatch(path) ||
        path.split('/').any((p) => p.isEmpty)) {
      throw StateError('Lokasi foto tidak valid.');
    }
  }

  Future<web.IDBDatabase> _buka() {
    final result = Completer<web.IDBDatabase>();
    final request = web.window.indexedDB.open('pengaduan_kampus_foto', 1);
    request.onupgradeneeded = ((web.Event _) {
      (request.result as web.IDBDatabase).createObjectStore('foto');
    }).toJS;
    request.onsuccess = ((web.Event _) {
      final db = request.result as web.IDBDatabase;
      if (result.isCompleted) {
        db.close();
      } else {
        result.complete(db);
      }
    }).toJS;
    request.onerror = ((web.Event _) {
      if (!result.isCompleted) {
        result.completeError(
          StateError('Penyimpanan foto browser tidak tersedia.'),
        );
      }
    }).toJS;
    request.onblocked = ((web.Event _) {
      if (!result.isCompleted) {
        result.completeError(
          StateError('Tutup tab aplikasi lain lalu coba kembali.'),
        );
      }
    }).toJS;
    return result.future;
  }

  Future<Uint8List?> baca(String path) async {
    _validasi(path);
    final db = await _buka();
    try {
      final result = Completer<Uint8List?>();
      final request = db
          .transaction('foto'.toJS, 'readonly')
          .objectStore('foto')
          .get(path.toJS);
      request.onsuccess = ((web.Event _) {
        final value = request.result;
        result.complete(value == null ? null : (value as JSUint8Array).toDart);
      }).toJS;
      request.onerror = ((web.Event _) {
        result.completeError(StateError('Foto lokal belum dapat dibaca.'));
      }).toJS;
      return await result.future;
    } finally {
      db.close();
    }
  }

  Future<void> _ubah(String path, Uint8List? bytes) async {
    _validasi(path);
    final db = await _buka();
    try {
      final result = Completer<void>();
      final tx = db.transaction('foto'.toJS, 'readwrite');
      final store = tx.objectStore('foto');
      if (bytes == null) {
        store.delete(path.toJS);
      } else {
        store.put(bytes.toJS, path.toJS);
      }
      tx.oncomplete = ((web.Event _) {
        result.complete();
      }).toJS;
      void gagal(web.Event _) {
        if (!result.isCompleted) {
          result.completeError(
            StateError(
              'Foto belum tersimpan. Periksa ruang penyimpanan atau izin browser.',
            ),
          );
        }
      }

      tx.onerror = gagal.toJS;
      tx.onabort = gagal.toJS;
      await result.future;
    } finally {
      db.close();
    }
  }

  Future<void> simpan(String path, Uint8List bytes) async {
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      throw StateError('Foto harus berisi data dan maksimal 5 MB.');
    }
    await _ubah(path, bytes);
  }

  Future<void> hapus(String path) => _ubah(path, null);
}
