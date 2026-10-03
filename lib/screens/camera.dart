import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Fotoğrafı küçültür (en uzun kenar 1080 px) ve JPEG olarak sıkıştırır.
/// Firestore belgesine sığması için 700 KB altında tutar.
Uint8List compressPhoto(Uint8List raw) {
  final decoded = img.decodeImage(raw);
  if (decoded == null) return raw;
  var image = img.bakeOrientation(decoded);
  const maxSide = 1080;
  if (image.width > maxSide || image.height > maxSide) {
    image = image.width >= image.height
        ? img.copyResize(image, width: maxSide)
        : img.copyResize(image, height: maxSide);
  }
  var quality = 78;
  var out = img.encodeJpg(image, quality: quality);
  while (out.length > 700 * 1024 && quality > 40) {
    quality -= 10;
    out = img.encodeJpg(image, quality: quality);
  }
  return out;
}

Uint8List _mirror(Uint8List raw) {
  final decoded = img.decodeImage(raw);
  if (decoded == null) return raw;
  return img.encodeJpg(img.flipHorizontal(img.bakeOrientation(decoded)), quality: 90);
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  int _index = 0;
  CameraController? _controller;
  String? _error;
  bool _taking = false;
  bool _sending = false;
  Uint8List? _shot;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _setup();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tick?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (c != null) {
        _controller = null;
        c.dispose();
        if (mounted) setState(() {});
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_controller == null && _cameras.isNotEmpty) _start(_cameras[_index]);
    }
  }

  Future<void> _setup() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _error = 'Bu telefonda kamera bulunamadı.');
        return;
      }
      _index = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.back);
      if (_index < 0) _index = 0;
      await _start(_cameras[_index]);
    } catch (e) {
      if (mounted) setState(() => _error = 'Kamera açılamadı. Ayarlardan Şipşak\'a kamera izni ver.');
    }
  }

  bool _starting = false;

  Future<void> _start(CameraDescription cam) async {
    if (_starting) return;
    _starting = true;
    try {
      final old = _controller;
      _controller = null;
      if (mounted) setState(() {});
      await old?.dispose();
      final c = CameraController(cam, ResolutionPreset.high, enableAudio: false, imageFormatGroup: ImageFormatGroup.jpeg);
      try {
        await c.initialize();
        if (!mounted) {
          await c.dispose();
          return;
        }
        setState(() {
          _controller = c;
          _error = null;
        });
      } on CameraException catch (e) {
        await c.dispose();
        if (mounted) {
          setState(() => _error = e.code == 'CameraAccessDenied'
              ? 'Kamera izni verilmedi. Ayarlardan Şipşak\'a kamera izni ver.'
              : 'Kamera açılamadı (${e.code}).');
        }
      }
    } finally {
      _starting = false;
    }
  }

  Future<void> _flip() async {
    if (_cameras.length < 2) return;
    _index = (_index + 1) % _cameras.length;
    await _start(_cameras[_index]);
  }

  Future<void> _take() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || _taking) return;
    setState(() => _taking = true);
    try {
      final file = await c.takePicture();
      var bytes = await file.readAsBytes();
      if (c.description.lensDirection == CameraLensDirection.front) {
        bytes = await compute(_mirror, bytes);
      }
      final small = await compute(compressPhoto, bytes);
      if (mounted) setState(() => _shot = small);
    } catch (e) {
      if (mounted) showError(context, 'Fotoğraf çekilemedi.');
    } finally {
      if (mounted) setState(() => _taking = false);
    }
  }

  Future<void> _send() async {
    final shot = _shot;
    if (shot == null) return;
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      await app.submitPhoto(shot);
      nav.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Kareni attın! Şimdi arkadaşlarınınkine bak.')));
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = app.today;
    final left = app.timeLeft;
    final shot = _shot;
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0D),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  RoundIconButton(
                    icon: Icons.close,
                    tooltip: 'Kapat',
                    bg: const Color(0xFF1F1F25),
                    onPressed: _sending ? null : () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(color: const Color(0xFF1F1F25), borderRadius: BorderRadius.circular(999)),
                        child: Text(s.theme, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(13, weight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: C.flash, borderRadius: BorderRadius.circular(999)),
                    child: Text(left == null ? 'DEMO' : countdownTextShort(left), style: mono(14, color: C.ink)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    color: C.surface,
                    child: shot != null ? Image.memory(shot, fit: BoxFit.cover, width: double.infinity, height: double.infinity) : _preview(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (shot == null) _shutterRow() else _confirmRow(),
            const SizedBox(height: 12),
            Text(
              shot == null ? 'Sadece canlı çekim. Galeri yok, hile yok.' : 'Gönderince tüm gruplarına gider.',
              style: body(13, color: C.muted),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _preview() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_outlined, color: C.muted, size: 40),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: body(15, color: C.muted)),
              const SizedBox(height: 16),
              TextButton(onPressed: _setup, child: Text('Tekrar dene', style: body(15, color: C.flash, weight: FontWeight.w700))),
            ],
          ),
        ),
      );
    }
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    final size = c.value.previewSize;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (size == null)
          CameraPreview(c)
        else
          FittedBox(
            fit: BoxFit.cover,
            // Telefonda önizleme boyutu yatay gelir, web'de olduğu gibi gelir.
            child: SizedBox(
              width: kIsWeb ? size.width : size.height,
              height: kIsWeb ? size.height : size.width,
              child: CameraPreview(c),
            ),
          ),
        IgnorePointer(child: CustomPaint(painter: _GridPainter())),
      ],
    );
  }

  Widget _shutterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 64,
            child: Column(
              children: [
                const Icon(Icons.lock_outline, color: C.muted, size: 22),
                const SizedBox(height: 4),
                Text('Galeri yok', style: body(11, color: C.muted, weight: FontWeight.w600)),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: 'Fotoğrafı çek',
            child: GestureDetector(
              onTap: _take,
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: C.flash, width: 4)),
                alignment: Alignment.center,
                child: _taking
                    ? const SizedBox(width: 30, height: 30, child: CircularProgressIndicator(strokeWidth: 3))
                    : Container(width: 64, height: 64, decoration: const BoxDecoration(color: C.flash, shape: BoxShape.circle)),
              ),
            ),
          ),
          SizedBox(
            width: 64,
            child: Center(
              child: RoundIconButton(
                icon: Icons.cameraswitch_outlined,
                tooltip: 'Kamerayı çevir',
                bg: const Color(0xFF1F1F25),
                size: 56,
                onPressed: _cameras.length > 1 ? _flip : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _confirmRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: GhostButton(
              label: 'Tekrar çek',
              icon: Icons.refresh,
              onPressed: _sending ? null : () => setState(() => _shot = null),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: BigButton(label: 'Gönder', icon: Icons.send_rounded, busy: _sending, height: 52, onPressed: _send),
          ),
        ],
      ),
    );
  }
}

String countdownTextShort(Duration d) {
  if (d.isNegative) return '00:00';
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x59FFFFFF)
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      final x = size.width * i / 3;
      final y = size.height * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
