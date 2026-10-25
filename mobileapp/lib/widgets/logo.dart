import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The Forkcast mark: a map pin with a fork cut out of it. Drawn from the
/// same paths as design/forkcast-mark.svg (viewBox 14 10 72 80).
class ForkcastMark extends StatelessWidget {
  const ForkcastMark({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size(size * 72 / 80, size),
        painter: _MarkPainter(pin: c.accent, fork: c.bg),
      ),
    );
  }
}

/// Mark + "Forkcast" wordmark, at app-bar size by default.
class ForkcastWordmark extends StatelessWidget {
  const ForkcastWordmark({super.key, this.large = false, this.vertical = false});

  final bool large;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final style = large ? context.text.displaySmall : context.text.titleLarge;
    final mark = ForkcastMark(size: large ? 56 : 28);
    final word = Text('Forkcast', style: style);
    return Semantics(
      label: 'Forkcast',
      excludeSemantics: true,
      child: vertical
          ? Column(mainAxisSize: MainAxisSize.min, children: [
              mark,
              const SizedBox(height: FcSpace.s3),
              word,
            ])
          : Row(mainAxisSize: MainAxisSize.min, children: [
              mark,
              const SizedBox(width: FcSpace.s2),
              word,
            ]),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter({required this.pin, required this.fork});

  final Color pin;
  final Color fork;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 72, size.height / 80);
    canvas.translate(-14, -10);

    final pinPath = Path()
      ..moveTo(50, 14)
      ..cubicTo(34.5, 14, 22, 26.3, 22, 41.6)
      ..cubicTo(22, 61.6, 50, 84, 50, 84)
      ..cubicTo(50, 84, 78, 61.6, 78, 41.6)
      ..cubicTo(78, 26.3, 65.5, 14, 50, 14)
      ..close();
    canvas.drawPath(pinPath, Paint()..color = pin);

    final p = Paint()..color = fork;
    for (final x in [41.5, 48.4, 55.3]) {
      canvas.drawRRect(
        RRect.fromLTRBR(x, 27, x + 3.2, 38, const Radius.circular(1.6)),
        p,
      );
    }
    // Fork head: a bar that rounds off at the bottom.
    final head = Path()
      ..moveTo(41.5, 36)
      ..lineTo(58.5, 36)
      ..lineTo(58.5, 38.8)
      ..arcToPoint(const Offset(41.5, 38.8),
          radius: const Radius.circular(8.5))
      ..close();
    canvas.drawPath(head, p);
    canvas.drawRRect(
      RRect.fromLTRBR(47.9, 45, 52.1, 65, const Radius.circular(2.1)),
      p,
    );
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.pin != pin || old.fork != fork;
}
