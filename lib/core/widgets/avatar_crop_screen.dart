import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AvatarCropScreen extends StatefulWidget {
  final String imagePath;

  const AvatarCropScreen({super.key, required this.imagePath});

  @override
  State<AvatarCropScreen> createState() => _AvatarCropScreenState();
}

class _AvatarCropScreenState extends State<AvatarCropScreen> {
  ui.Image? _image;
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  double _startScale = 1.0;
  Offset _startOffset = Offset.zero;
  Offset _startFocalPoint = Offset.zero;
  double _viewportSize = 0.0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (mounted) setState(() => _image = frame.image);
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Výřez fotky'),
        actions: [
          TextButton(
            onPressed: image == null || _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Uložit'),
          ),
        ],
      ),
      body: image == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final viewportSize = math.min(
                  constraints.maxWidth - 32,
                  constraints.maxHeight - 96,
                );
                if (_viewportSize != viewportSize) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => setState(() => _viewportSize = viewportSize),
                  );
                }
                final size = Size(viewportSize, viewportSize);
                return Column(
                  children: [
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onScaleStart: (details) {
                          _startScale = _scale;
                          _startOffset = _offset;
                          _startFocalPoint = details.localFocalPoint;
                        },
                        onScaleUpdate: (details) {
                          setState(() {
                            final newScale =
                                (_startScale * details.scale).clamp(1.0, 4.0);
                            final vp = _viewportSize;
                            final center = Offset(vp / 2, vp / 2);
                            // zoom around start focal point, plus pan delta
                            final fp = _startFocalPoint - center;
                            final pan =
                                details.localFocalPoint - _startFocalPoint;
                            _scale = newScale;
                            _offset = fp +
                                (_startOffset - fp) *
                                    (newScale / _startScale) +
                                pan;
                            // clamp so image always covers the crop circle
                            final maxPan = vp * (_scale - 1) / 2;
                            _offset = Offset(
                              _offset.dx.clamp(-maxPan, maxPan),
                              _offset.dy.clamp(-maxPan, maxPan),
                            );
                          });
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CustomPaint(
                            size: size,
                            painter: _AvatarCropPainter(
                              image: image,
                              offset: _offset,
                              scale: _scale,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Posuňte prstem nebo přibližte dvěma prsty, aby obličej seděl ve výřezu.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Future<void> _save() async {
    final image = _image;
    if (image == null) return;
    setState(() => _saving = true);
    try {
      final bytes = await _cropImage(
        image: image,
        offset: _offset,
        scale: _scale,
        viewportSize: _viewportSize,
      );
      final file = File(
        '${Directory.systemTemp.path}/czechbmx-avatar-${DateTime.now().microsecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes, flush: true);
      if (mounted) Navigator.pop(context, file.path);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _AvatarCropPainter extends CustomPainter {
  final ui.Image image;
  final Offset offset;
  final double scale;

  const _AvatarCropPainter({
    required this.image,
    required this.offset,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawImage(canvas, size, image, offset, scale);

    final overlay = Paint()..color = Colors.black.withValues(alpha: 0.42);
    final full = Path()..addRect(Offset.zero & size);
    final circle = Path()
      ..addOval(
        Rect.fromCircle(
          center: size.center(Offset.zero),
          radius: size.width / 2 - 12,
        ),
      );
    canvas.drawPath(
      Path.combine(PathOperation.difference, full, circle),
      overlay,
    );
    canvas.drawCircle(
      size.center(Offset.zero),
      size.width / 2 - 12,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _AvatarCropPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.offset != offset ||
        oldDelegate.scale != scale;
  }
}

void _drawImage(
  Canvas canvas,
  Size size,
  ui.Image image,
  Offset offset,
  double userScale,
) {
  final imageSize = Size(image.width.toDouble(), image.height.toDouble());
  final baseScale = math.max(
    size.width / imageSize.width,
    size.height / imageSize.height,
  );
  final drawSize = imageSize * baseScale * userScale;
  final topLeft =
      size.center(Offset.zero) - drawSize.center(Offset.zero) + offset;
  canvas.drawImageRect(
    image,
    Offset.zero & imageSize,
    topLeft & drawSize,
    Paint()..filterQuality = FilterQuality.high,
  );
}

const _cropMargin = 12.0;
const _outputSize = 512;

Future<Uint8List> _cropImage({
  required ui.Image image,
  required Offset offset,
  required double scale,
  required double viewportSize,
}) async {
  // Reproduce the same geometry as _drawImage to find where the image sits
  // on the preview canvas, then compute the corresponding src rect.
  final imageSize = Size(image.width.toDouble(), image.height.toDouble());
  final baseScale = math.max(
    viewportSize / imageSize.width,
    viewportSize / imageSize.height,
  );
  final totalScale = baseScale * scale;
  final drawSize = imageSize * baseScale * scale;
  final center = Offset(viewportSize / 2, viewportSize / 2);
  final topLeft = center - drawSize.center(Offset.zero) + offset;

  // The circle sits at [_cropMargin .. viewportSize - _cropMargin] on the canvas.
  final circleCanvasSize = viewportSize - _cropMargin * 2;

  // Map circle edges back to image pixel coordinates.
  final srcLeft = (_cropMargin - topLeft.dx) / totalScale;
  final srcTop = (_cropMargin - topLeft.dy) / totalScale;
  final srcSize = circleCanvasSize / totalScale;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawImageRect(
    image,
    Rect.fromLTWH(srcLeft, srcTop, srcSize, srcSize),
    Rect.fromLTWH(0, 0, _outputSize.toDouble(), _outputSize.toDouble()),
    Paint()..filterQuality = FilterQuality.high,
  );
  final picture = recorder.endRecording();
  final cropped = await picture.toImage(_outputSize, _outputSize);
  final byteData = await cropped.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}
