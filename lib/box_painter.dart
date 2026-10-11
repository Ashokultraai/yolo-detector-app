import 'package:flutter/material.dart';
import 'models.dart';

/// Draws detection boxes + labels over the displayed image.
///
/// Boxes come from the backend in ORIGINAL image pixels, so we scale them to
/// the widget size using the original image dimensions.
class BoxPainter extends CustomPainter {
  final List<Detection> detections;
  final int imageWidth;
  final int imageHeight;

  BoxPainter(this.detections, this.imageWidth, this.imageHeight);

  @override
  void paint(Canvas canvas, Size size) {
    if (imageWidth == 0 || imageHeight == 0) return;
    final sx = size.width / imageWidth;
    final sy = size.height / imageHeight;

    for (final d in detections) {
      final color = Color(kLabelColors[d.label] ?? 0xFF00E5FF);
      final rect = Rect.fromLTRB(
        d.box[0] * sx,
        d.box[1] * sy,
        d.box[2] * sx,
        d.box[3] * sy,
      );
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = color;
      canvas.drawRect(rect, stroke);

      final text = '${d.label} ${(d.confidence * 100).toStringAsFixed(0)}%';
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelRect = Rect.fromLTWH(
        rect.left,
        (rect.top - 18).clamp(0, size.height),
        tp.width + 8,
        18,
      );
      canvas.drawRect(labelRect, Paint()..color = color);
      tp.paint(canvas, Offset(labelRect.left + 4, labelRect.top + 2));
    }
  }

  @override
  bool shouldRepaint(covariant BoxPainter old) =>
      old.detections != detections;
}
