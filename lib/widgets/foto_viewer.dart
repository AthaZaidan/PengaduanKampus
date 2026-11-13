import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Halaman layar penuh untuk melihat foto lampiran (geser & zoom).
class FotoViewerPage extends StatefulWidget {
  final List<Uint8List> foto;
  final int initialIndex;

  const FotoViewerPage({
    super.key,
    required this.foto,
    this.initialIndex = 0,
  });

  @override
  State<FotoViewerPage> createState() => _FotoViewerPageState();
}

class _FotoViewerPageState extends State<FotoViewerPage> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Foto ${_index + 1} dari ${widget.foto.length}',
          style: const TextStyle(fontSize: 15),
        ),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.foto.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) => InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: Image.memory(widget.foto[i], fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
