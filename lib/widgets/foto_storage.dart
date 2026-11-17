import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

/// Membaca gambar lewat SDK agar aturan akses Storage tetap diperiksa.
class FotoStorage extends StatefulWidget {
  final String path;
  final BoxFit fit;
  const FotoStorage({super.key, required this.path, this.fit = BoxFit.contain});

  @override
  State<FotoStorage> createState() => _FotoStorageState();
}

class _FotoStorageState extends State<FotoStorage> {
  late Future<Uint8List?> _foto;
  @override
  void initState() {
    super.initState();
    _muat();
  }

  void _muat() {
    _foto = FirebaseStorage.instance.ref(widget.path).getData(5 * 1024 * 1024);
  }

  @override
  void didUpdateWidget(covariant FotoStorage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _muat();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: _foto,
    builder: (context, snap) {
      if (snap.hasError ||
          (snap.connectionState == ConnectionState.done && snap.data == null)) {
        return Center(
          child: IconButton(
            tooltip: 'Foto gagal dimuat. Ketuk untuk mencoba lagi.',
            onPressed: () => setState(_muat),
            icon: const Icon(Icons.refresh),
          ),
        );
      }
      if (!snap.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      return Image.memory(
        snap.data!,
        fit: widget.fit,
        errorBuilder: (_, error, stack) =>
            const Icon(Icons.broken_image_outlined),
      );
    },
  );
}
