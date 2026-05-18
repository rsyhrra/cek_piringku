import 'package:flutter/material.dart';
import '../models/nutrition_model.dart';
import '../constants/dummy_data.dart';
import 'database_service.dart';

class NutritionService extends ChangeNotifier {
  List<NutritionModel> _scans = [];
  bool _isAnalyzing = false;
  final DatabaseService _db = DatabaseService();

  List<NutritionModel> get scans => _scans;
  bool get isAnalyzing => _isAnalyzing;

  NutritionService() {
    _loadScans();
  }

  Future<void> _loadScans() async {
    _scans = await _db.getScans();
    notifyListeners();
  }

  int get todayCalories {
    final today = DateTime.now();
    return _scans
        .where((scan) =>
            scan.timestamp.year == today.year &&
            scan.timestamp.month == today.month &&
            scan.timestamp.day == today.day)
        .fold(0, (sum, scan) => sum + scan.calories);
  }
  
  int get todayProtein {
    final today = DateTime.now();
    return _scans
        .where((scan) =>
            scan.timestamp.year == today.year &&
            scan.timestamp.month == today.month &&
            scan.timestamp.day == today.day)
        .fold(0, (sum, scan) => sum + scan.protein);
  }
  
  int get todayCarbs {
    final today = DateTime.now();
    return _scans
        .where((scan) =>
            scan.timestamp.year == today.year &&
            scan.timestamp.month == today.month &&
            scan.timestamp.day == today.day)
        .fold(0, (sum, scan) => sum + scan.carbs);
  }
  
  int get todayFats {
    final today = DateTime.now();
    return _scans
        .where((scan) =>
            scan.timestamp.year == today.year &&
            scan.timestamp.month == today.month &&
            scan.timestamp.day == today.day)
        .fold(0, (sum, scan) => sum + scan.fats);
  }

  Future<NutritionModel> analyzeMeal(String imagePath) async {
    _isAnalyzing = true;
    notifyListeners();

    // Simulate network/analysis delay
    await Future.delayed(const Duration(seconds: 3));

    final result = _scans.length % 2 == 0 
      ? DummyData.goodNutrition 
      : DummyData.badNutrition;

    final newScan = NutritionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      calories: result.calories,
      protein: result.protein,
      carbs: result.carbs,
      fats: result.fats,
      foodItems: result.foodItems,
      isStandardMet: result.isStandardMet,
    );

    _scans.insert(0, newScan);
    await _db.insertScan(newScan);
    
    _isAnalyzing = false;
    notifyListeners();

    return newScan;
  }
}
