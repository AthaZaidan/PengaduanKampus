import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../models/aset_kampus.dart';
import '../../services/aset_service.dart';
import '../../theme/palet_kampus.dart';

/// Halaman pemindai QR Code untuk identifikasi aset dan lokasi kampus.
class ScanQrPage extends StatefulWidget {
  final AsetService? asetService;

  const ScanQrPage({super.key, this.asetService});

  @override
  State<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends State<ScanQrPage> {
  late final MobileScannerController _controller;
  late final AsetService _asetService;
  bool _sudahScan = false;
  bool _memuat = false;

  @override
  void initState() {
    super.initState();
    _asetService = widget.asetService ?? AsetService();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _prosesKode(String kodeMentah) async {
    if (_sudahScan || _memuat) return;
    setState(() {
      _sudahScan = true;
      _memuat = true;
    });

    try {
      final aset = await _asetService.cariAset(kodeMentah);
      if (!mounted) return;
      Navigator.of(context).pop(aset);
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pop(AsetKampus.dariKodeMentah(kodeMentah));
    }
  }

  Future<void> _bukaInputManual() async {
    final val = await showDialog<String>(
      context: context,
      builder: (_) => const _DialogInputKodeManual(),
    );
    if (!mounted || val == null || val.isEmpty) return;
    _prosesKode(val);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanAreaSize = (size.width * 0.72).clamp(240.0, 320.0);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan QR Aset Kampus'),
        actions: [
          IconButton(
            tooltip: 'Lampu Kilat',
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (context, state, _) {
                final on = state.torchState == TorchState.on;
                return Icon(
                  on ? Icons.flash_on : Icons.flash_off,
                  color: on ? Colors.amber : Colors.white,
                );
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            tooltip: 'Ganti Kamera',
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_sudahScan) return;
              final barcode = capture.barcodes.firstOrNull;
              final code = barcode?.rawValue;
              if (code != null && code.trim().isNotEmpty) {
                _prosesKode(code.trim());
              }
            },
          ),

          // Overlay gelap dengan lubang bidik kotak
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.65),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: scanAreaSize,
                    height: scanAreaSize,
                    decoration: BoxDecoration(
                      color: Colors.red, // Target lubang tembus pandang
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bingkai sudut kotak bidik
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: scanAreaSize,
              height: scanAreaSize,
              child: CustomPaint(
                painter: _QrCornerPainter(color: AppColors.sageGreen),
              ),
            ),
          ),

          // Teks petunjuk dan tombol manual di bawah
          Positioned(
            left: 24,
            right: 24,
            bottom: 36,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code_scanner, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Arahkan kamera ke stiker QR aset kampus',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _bukaInputManual,
                  icon: const Icon(Icons.keyboard_outlined),
                  label: const Text('Ketik Kode Manual'),
                ),
              ],
            ),
          ),

          // Loading overlay jika sedang memproses data
          if (_memuat)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Memuat data aset...',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Gambar 4 sudut siku-siku penanda area scan QR
class _QrCornerPainter extends CustomPainter {
  final Color color;
  _QrCornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 28.0;

    // Kiri atas
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLength), paint);

    // Kanan atas
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLength, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    // Kiri bawah
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLength), paint);

    // Kanan bawah
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerLength, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DialogInputKodeManual extends StatefulWidget {
  const _DialogInputKodeManual();

  @override
  State<_DialogInputKodeManual> createState() => _DialogInputKodeManualState();
}

class _DialogInputKodeManualState extends State<_DialogInputKodeManual> {
  final _manualController = TextEditingController();

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  void _gunakan() {
    final val = _manualController.text.trim();
    if (val.isNotEmpty) {
      Navigator.of(context).pop(val);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Input Kode Aset Manual'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Masukkan kode aset yang tertera pada stiker fisik (contoh: AST-2-3-PROYEKTOR-01):',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _manualController,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) => _gunakan(),
            decoration: const InputDecoration(
              hintText: 'Kode aset...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.qr_code),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _gunakan, child: const Text('Gunakan')),
      ],
    );
  }
}
