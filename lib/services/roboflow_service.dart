import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class SegmentationResult {
  final String label;
  final double confidence;
  final List<Map<String, double>> points; // koordinat polygon

  SegmentationResult({
    required this.label,
    required this.confidence,
    required this.points,
  });
}

class RoboflowService {
  static const String _apiKey = "p1BjPT4nxNstNUX2esus"; // ganti ini
  static const String _modelId = "menu-mbg-mbkm-ylkbs-lu5tb-wnrie/1";
  static const double _confidence = 0.40;

  static Future<List<SegmentationResult>> detectWithMask(
      File imageFile) async {
    try {
      // Convert gambar ke base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Kirim ke Roboflow API
      final response = await http.post(
        Uri.parse(
          'https://detect.roboflow.com/$_modelId'
          '?api_key=$_apiKey'
          '&confidence=$_confidence'
          '&stroke=2',
        ),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: base64Image,
      );

      if (response.statusCode != 200) {
        debugPrint('Roboflow error: ${response.body}');
        return [];
      }

      final data = jsonDecode(response.body);
      final predictions = data['predictions'] as List<dynamic>?;
      if (predictions == null || predictions.isEmpty) return [];

      return predictions.map((pred) {
        final points = (pred['points'] as List<dynamic>? ?? [])
            .map((p) => {
                  'x': (p['x'] as num).toDouble(),
                  'y': (p['y'] as num).toDouble(),
                })
            .toList();

        return SegmentationResult(
          label: pred['class'] as String,
          confidence: (pred['confidence'] as num).toDouble(),
          points: points,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error Roboflow: $e');
      return [];
    }
  }
}
