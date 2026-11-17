import 'dart:typed_data';

import '../services/foto_firestore_service.dart';
import '../services/foto_lokal_service.dart';

import 'package:flutter/material.dart';

/// Menampilkan lampiran: foto laporan dibaca dari Firestore (base64 → gambar),
/// sedangkan foto draf yang belum dikirim dibaca dari penyimpanan perangkat.
class FotoLokal extends StatefulWidget {
  final String path;
  final BoxFit fit;
  const FotoLokal({super.key, required this.path, this.fit = BoxFit.contain});

  @override
  State<FotoLokal> createState() => _FotoLokalState();
}

class _FotoLokalState extends State<FotoLokal> {
  late Future<Uint8List?> _foto;
  @override
  void initState() {
    super.initState();
    _muat();
  }

  void _muat() {
    _foto = FotoFirestoreService.adalahPathFirestore(widget.path)
        ? FotoFirestoreService.instance.baca(widget.path)
        : FotoLokalService.instance.baca(widget.path);
  }

  @override
  void didUpdateWidget(covariant FotoLokal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _muat();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: _foto,
    builder: (context, snap) {
      if (snap.hasError ||
          (snap.connectionState == ConnectionState.done && snap.data == null)) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.photo_outlined),
                SizedBox(height: 4),
                Text(
                  'Foto tidak tersedia',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10),
                ),
              ],
            ),
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
