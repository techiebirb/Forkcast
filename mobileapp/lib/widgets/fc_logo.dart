import 'package:flutter/material.dart';

import '../theme/fc_tokens.dart';

/// The Forkcast mark: a map pin with a fork inside. Drawn from the design's
/// logo paths (viewBox 14 10 72 80), so it follows the theme in both modes.
class FcLogoMark extends StatelessWidget {
  const FcLogoMark({super.key, this.size = 56, this.color, this.cutout});

  final double size;

  /// Pin fill. Defaults to the accent color.
  final Color? color;

  /// Fork color. Defaults to the page background.
  final Color? cutout;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _LogoPainter(color ?? c.accent, cutout ?? c.bg),
        ),
      ),
    );
  }
}

/// Mark plus the wordmark, for the startup screen and the Home app bar.
class FcWordmark extends StatelessWidget {
  const FcWordmark({
    super.key,
    this.markSize = 28,
    this.style = FcText.wordmark,
    this.gap = 8,
  });

  final double markSize;
  final TextStyle style;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FcLogoMark(size: markSize),
        SizedBox(width: gap),
        Text('Forkcast', style: style.copyWith(color: context.fc.textPrimary)),
      ],
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter(this.pin, this.fork);

  final Color pin;
  final Color fork;

  static const _vbX = 14.0, _vbY = 10.0, _vbW = 72.0, _vbH = 80.0;

  @override
  void paint(Canvas canvas, Size size) {
    // preserveAspectRatio "xMidYMid meet".
    final scale = (size.width / _vbW) < (size.height / _vbH)
        ? size.width / _vbW
        : size.height / _vbH;
    final dx = (size.width - _vbW * scale) / 2;
    final dy = (size.height - _vbH * scale) / 2;
    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale);
    canvas.translate(-_vbX, -_vbY);

    final pinPath = Path()
      ..moveTo(50, 14)
      ..cubicTo(34.5, 14, 22, 26.3, 22, 41.6)
      ..cubicTo(22, 61.6, 50, 84, 50, 84)
      ..cubicTo(50, 84, 78, 61.6, 78, 41.6)
      ..cubicTo(78, 26.3, 65.5, 14, 50, 14)
      ..close();
    canvas.drawPath(pinPath, Paint()..color = pin);

    final forkPaint = Paint()..color = fork;
    for (final x in const [41.5, 48.4, 55.3]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 27, 3.2, 11),
          const Radius.circular(1.6),
        ),
        forkPaint,
      );
    }
    final cup = Path()
      ..moveTo(41.5, 36)
      ..lineTo(58.5, 36)
      ..lineTo(58.5, 38.8)
      ..cubicTo(58.5, 43.5, 54.7, 47.3, 50, 47.3)
      ..cubicTo(45.3, 47.3, 41.5, 43.5, 41.5, 38.8)
      ..close();
    canvas.drawPath(cup, forkPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(47.9, 45, 4.2, 20),
        const Radius.circular(2.1),
      ),
      forkPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.pin != pin || old.fork != fork;
}
