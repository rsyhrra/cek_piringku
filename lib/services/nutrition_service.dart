import 'package:flutter/material.dart';
import '../models/nutrition_model.dart';
import 'database_service.dart';
import 'ml_service.dart';

class NutritionService extends ChangeNotifier {
  List<NutritionModel> _scans = [];
  bool _isAnalyzing = false;
  final DatabaseService _db = DatabaseService();
  final MlService _ml = MlService();

  List<NutritionModel> get scans => _scans;
  bool get isAnalyzing => _isAnalyzing;

  NutritionService() {
    _init();
  }

  Future<void> _init() async {
    // Muat scan dari DB
    _scans = await _db.getScans();
    notifyListeners();

    // Inisialisasi ML di background (lazy, tidak blocking UI)
    _ml.initialize().catchError((e) {
      debugPrint('[NutritionService] ML init warning: $e');
    });
  }

  // ─── Aggregasi harian ───────────────────────────────────────────────────

  int get todayCalories {
    final today = DateTime.now();
    return _scans
        .where((s) =>
            s.timestamp.year == today.year &&
            s.timestamp.month == today.month &&
            s.timestamp.day == today.day)
        .fold(0, (sum, s) => sum + s.calories);
  }

  int get todayProtein {
    final today = DateTime.now();
    return _scans
        .where((s) =>
            s.timestamp.year == today.year &&
            s.timestamp.month == today.month &&
            s.timestamp.day == today.day)
        .fold(0, (sum, s) => sum + s.protein);
  }

  int get todayCarbs {
    final today = DateTime.now();
    return _scans
        .where((s) =>
            s.timestamp.year == today.year &&
            s.timestamp.month == today.month &&
            s.timestamp.day == today.day)
        .fold(0, (sum, s) => sum + s.carbs);
  }

  int get todayFats {
    final today = DateTime.now();
    return _scans
        .where((s) =>
            s.timestamp.year == today.year &&
            s.timestamp.month == today.month &&
            s.timestamp.day == today.day)
        .fold(0, (sum, s) => sum + s.fats);
  }

  // ─── Analisis Makanan (real TFLite) ────────────────────────────────────

  /// [imagePath] : path file gambar dari kamera, atau 'simulated_path' untuk fallback
  Future<NutritionModel> analyzeMeal(String imagePath) async {
    _isAnalyzing = true;
    notifyListeners();

    try {
      // Jalankan inferensi TFLite + lookup CSV
      final result = await _ml.analyzeFoodImage(imagePath);

      final newScan = NutritionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        calories: result.totalCalories,
        protein: result.totalProteins,
        carbs: result.totalCarbs,
        fats: result.totalFat,
        foodItems: result.detectedFoods,
        isStandardMet: result.isStandardMet,
      );

      // Jangan simpan ke history/DB jika simulasi atau tidak ada makanan terdeteksi
      if (!result.detectedFoods.contains('Tidak ada makanan terdeteksi')) {
        _scans.insert(0, newScan);
        await _db.insertScan(newScan);
      }

      return newScan;
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }
}
