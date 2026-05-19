import 'package:flutter/material.dart';
import '../services/roboflow_service.dart';

class MaskPainter extends CustomPainter {
  final List<SegmentationResult> detections;
  final Size imageSize;

  // Warna berbeda per kelas
  static const List<Color> _colors = [
    Color(0xFFE53935), // merah
    Color(0xFF43A047), // hijau
    Color(0xFF1E88E5), // biru
    Color(0xFFFF8F00), // oranye
    Color(0xFF8E24AA), // ungu
    Color(0xFF00ACC1), // cyan
  ];

  MaskPainter({required this.detections, required this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;

    for (int i = 0; i < detections.length; i++) {
      final det = detections[i];
      final color = _colors[i % _colors.length];

      if (det.points.isEmpty) continue;

      // Buat path dari polygon points
      final path = Path();
      final firstPoint = det.points.first;
      path.moveTo(
        firstPoint['x']! * scaleX,
        firstPoint['y']! * scaleY,
      );

      for (final point in det.points.skip(1)) {
        path.lineTo(
          point['x']! * scaleX,
          point['y']! * scaleY,
        );
      }
      path.close();

      // Gambar fill transparan
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withOpacity(0.25)
          ..style = PaintingStyle.fill,
      );

      // Gambar garis tepi
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0,
      );

      // Gambar label makanan
      if (det.points.isNotEmpty) {
        final labelX = det.points
                .map((p) => p['x']!)
                .reduce((a, b) => a + b) /
            det.points.length *
            scaleX;
        final labelY = det.points
                .map((p) => p['y']!)
                .reduce((a, b) => a + b) /
            det.points.length *
            scaleY;

        // Background label
        final textPainter = TextPainter(
          text: TextSpan(
            text:
                '${det.label} ${(det.confidence * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: color,
                  blurRadius: 4,
                  offset: const Offset(1, 1),
                )
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        // Background kotak label
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              labelX - 4,
              labelY - textPainter.height / 2 - 4,
              textPainter.width + 8,
              textPainter.height + 8,
            ),
            const Radius.circular(6),
          ),
          Paint()..color = color.withOpacity(0.85),
        );

        textPainter.paint(
          canvas,
          Offset(labelX, labelY - textPainter.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(MaskPainter old) => old.detections != detections;
}
