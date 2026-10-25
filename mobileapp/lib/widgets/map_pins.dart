import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../theme/fc_tokens.dart';
import 'fc_icons.dart';

String _hex(Color color) =>
    '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// Google Maps style JSON built from the design's `map-*` tokens, so the real
/// map matches the illustrated basemap in both themes. Our own pins stand in
/// for business labels, so point-of-interest labels are hidden.
String forkcastMapStyle(FcColors c) {
  return jsonEncode([
    {
      'elementType': 'geometry',
      'stylers': [
        {'color': _hex(c.mapLand)},
      ],
    },
    {
      'elementType': 'labels.text.fill',
      'stylers': [
        {'color': _hex(c.textSecondary)},
      ],
    },
    {
      'elementType': 'labels.text.stroke',
      'stylers': [
        {'color': _hex(c.mapLand)},
      ],
    },
    {
      'featureType': 'road',
      'elementType': 'geometry',
      'stylers': [
        {'color': _hex(c.mapRoad)},
      ],
    },
    {
      'featureType': 'road',
      'elementType': 'geometry.stroke',
      'stylers': [
        {'color': _hex(c.mapLand)},
      ],
    },
    {
      'featureType': 'poi.park',
      'elementType': 'geometry',
      'stylers': [
        {'color': _hex(c.mapPark)},
      ],
    },
    {
      'featureType': 'water',
      'elementType': 'geometry',
      'stylers': [
        {'color': _hex(c.mapWater)},
      ],
    },
    {
      'featureType': 'poi',
      'elementType': 'labels',
      'stylers': [
        {'visibility': 'off'},
      ],
    },
    {
      'featureType': 'transit',
      'stylers': [
        {'visibility': 'off'},
      ],
    },
  ]);
}

/// Draws the numbered pill pin (fork-and-knife glyph, the number, and a tip)
/// and wraps it as a map marker icon. Selected pins use the accent fill and
/// are a little larger.
Future<BitmapDescriptor> buildPinDescriptor({
  required int number,
  required bool selected,
  required FcColors colors,
  required double devicePixelRatio,
}) async {
  const margin = 4.0;
  final fill = selected ? colors.accent : colors.surfaceRaised;
  final edge = selected ? colors.accent : colors.borderStrong;
  final ink = selected ? colors.onAccent : colors.textPrimary;
  final bodyHeight = selected ? 40.0 : 32.0;
  final fontSize = selected ? 16.0 : 14.0;
  const tipHeight = 7.0;

  final glyph = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(FcIcons.forkKnife.codePoint),
      style: TextStyle(
        fontFamily: FcIcons.forkKnife.fontFamily,
        fontSize: 16,
        color: ink,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final label = TextPainter(
    text: TextSpan(
      text: '$number',
      style: TextStyle(
        fontFamily: kFcFontFamily,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: ink,
        fontFeatures: const [ui.FontFeature.tabularFigures()],
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  final padLeft = selected ? 12.0 : 8.0;
  final padRight = selected ? 12.0 : 10.0;
  final bodyWidth = padLeft + glyph.width + 4 + label.width + padRight;
  final width = bodyWidth + margin * 2;
  final height = bodyHeight + tipHeight + margin * 2;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(devicePixelRatio);

  final body = RRect.fromRectAndRadius(
    Rect.fromLTWH(margin, margin, bodyWidth, bodyHeight),
    Radius.circular(bodyHeight / 2),
  );
  final tip = Path()
    ..moveTo(width / 2 - 5, margin + bodyHeight - 1)
    ..lineTo(width / 2 + 5, margin + bodyHeight - 1)
    ..lineTo(width / 2, margin + bodyHeight + tipHeight)
    ..close();
  final shape = Path()
    ..addRRect(body)
    ..addPath(tip, Offset.zero);

  canvas.drawShadow(shape, const Color(0xFF000000), 3, true);
  final edgePaint = Paint()
    ..color = edge
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  final fillPaint = Paint()..color = fill;
  canvas
    ..drawPath(tip, fillPaint)
    ..drawRRect(body, fillPaint)
    ..drawRRect(body.deflate(0.5), edgePaint);
  // Tip outline, open at the top so it joins the body.
  canvas.drawPath(
    Path()
      ..moveTo(width / 2 - 5, margin + bodyHeight - 0.5)
      ..lineTo(width / 2, margin + bodyHeight + tipHeight - 0.5)
      ..lineTo(width / 2 + 5, margin + bodyHeight - 0.5),
    edgePaint,
  );
  // Cover the seam between body and tip.
  canvas.drawRect(
    Rect.fromLTWH(width / 2 - 4.2, margin + bodyHeight - 1.5, 8.4, 2),
    fillPaint,
  );

  final centerY = margin + bodyHeight / 2;
  glyph.paint(canvas, Offset(margin + padLeft, centerY - glyph.height / 2));
  label.paint(
    canvas,
    Offset(margin + padLeft + glyph.width + 4, centerY - label.height / 2),
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(
    (width * devicePixelRatio).ceil(),
    (height * devicePixelRatio).ceil(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.bytes(
    bytes!.buffer.asUint8List(),
    imagePixelRatio: devicePixelRatio,
  );
}
