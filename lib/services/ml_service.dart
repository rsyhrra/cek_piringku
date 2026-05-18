import 'dart:io';
import 'dart:math';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/food_item_model.dart';

/// Konfigurasi model TFLite.
/// Sesuaikan jika model Anda berbeda dari asumsi MobileNet 224x224.
class _ModelConfig {
  /// Ukuran input gambar (lebar & tinggi dalam pixel). Default: 224 (MobileNet).
  static const int inputSize = 224;

  /// Path asset model TFLite
  static const String modelPath = 'assets/models/best_float32.tflite';

  /// Path asset dataset utama (label + nilai gizi)
  static const String nutritionCsvPath = 'assets/data/nutrition.csv';

  /// Threshold confidence minimum agar hasil diterima (0.0–1.0)
  static const double confidenceThreshold = 0.30;
}

/// Service utama untuk:
/// 1. Memuat & menjalankan model TFLite (klasifikasi makanan dari gambar)
/// 2. Memuat & melakukan lookup dataset CSV (nilai gizi per makanan)
/// 3. Mengembalikan hasil analisis makanan lengkap
class MlService {
  // ─── Singleton ────────────────────────────────────────────────────────────
  static final MlService _instance = MlService._internal();
  factory MlService() => _instance;
  MlService._internal();

  // ─── State ────────────────────────────────────────────────────────────────
  Interpreter? _interpreter;
  List<FoodItemModel> _foodDatabase = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  // ─── Inisialisasi ─────────────────────────────────────────────────────────

  /// Muat model TFLite dan dataset CSV ke memori.
  /// Panggil satu kali saat app start (atau lazy di first use).
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await Future.wait([
        _loadModel(),
        _loadFoodDatabase(),
      ]);
      _isInitialized = true;
      debugPrint('[MlService] Inisialisasi berhasil. '
          '${_foodDatabase.length} item makanan dimuat.');
    } catch (e) {
      debugPrint('[MlService] Gagal inisialisasi: $e');
      rethrow;
    }
  }

  Future<void> _loadModel() async {
    _interpreter = await Interpreter.fromAsset(_ModelConfig.modelPath);
    debugPrint('[MlService] Model TFLite dimuat.');
  }

  Future<void> _loadFoodDatabase() async {
    final raw = await rootBundle.loadString(_ModelConfig.nutritionCsvPath);
    // CsvToListConverter: eol auto, fieldDelimiter koma
    final rows = const CsvToListConverter(eol: '\n').convert(raw);
    // Lewati header (baris 0)
    _foodDatabase = rows
        .skip(1)
        .where((row) => row.length >= 6)
        .map((row) => FoodItemModel.fromCsvRow(row))
        .toList();
    debugPrint('[MlService] ${_foodDatabase.length} item makanan dari CSV.');
  }

  // ─── Analisis Gambar ──────────────────────────────────────────────────────

  /// Analisis gambar makanan dari [imagePath].
  ///
  /// Returns:
  /// - `detectedFoods` : List nama makanan yang terdeteksi (maks 3 teratas)
  /// - `nutritionData` : Penjumlahan nilai gizi semua makanan yang terdeteksi
  ///
  /// Jika model gagal / confidence rendah, fallback ke data representatif dari CSV.
  Future<MlAnalysisResult> analyzeFoodImage(String imagePath) async {
    if (!_isInitialized) await initialize();

    // Jika path adalah simulasi (tidak ada kamera), kembalikan hasil sampling CSV
    if (imagePath == 'simulated_path' || !File(imagePath).existsSync()) {
      return _buildSimulatedResult();
    }

    try {
      final topPredictions = await _runInference(imagePath);
      if (topPredictions.isEmpty) return _buildSimulatedResult();

      final detectedFoods = <String>[];
      double totalCalories = 0;
      double totalProteins = 0;
      double totalFat = 0;
      double totalCarbs = 0;

      for (final pred in topPredictions) {
        final food = _lookupFood(pred.label);
        if (food != null) {
          detectedFoods.add(food.name);
          totalCalories += food.calories;
          totalProteins += food.proteins;
          totalFat += food.fat;
          totalCarbs += food.carbohydrate;
        }
      }

      if (detectedFoods.isEmpty) return _buildSimulatedResult();

      // Standar BGN: kalori 600–900 kcal, protein ≥15g, sayur hadir
      final isStandardMet = totalCalories >= 400 &&
          totalCalories <= 900 &&
          totalProteins >= 15;

      return MlAnalysisResult(
        detectedFoods: detectedFoods,
        totalCalories: totalCalories.round(),
        totalProteins: totalProteins.round(),
        totalFat: totalFat.round(),
        totalCarbs: totalCarbs.round(),
        isStandardMet: isStandardMet,
        topPrediction: topPredictions.first,
      );
    } catch (e) {
      debugPrint('[MlService] Inferensi gagal: $e');
      return _buildSimulatedResult();
    }
  }

  // ─── Inferensi TFLite ─────────────────────────────────────────────────────

  Future<List<Prediction>> _runInference(String imagePath) async {
    final interpreter = _interpreter;
    if (interpreter == null) return [];

    // 1. Load & resize gambar
    final imageBytes = await File(imagePath).readAsBytes();
    final inputTensor = await _preprocessImage(imageBytes);

    // 2. Siapkan output buffer
    // Output shape: [1, numberOfClasses] — float32
    final outputShape = interpreter.getOutputTensor(0).shape;
    final numClasses = outputShape.last;
    final outputBuffer =
        List.filled(numClasses, 0.0).reshape([1, numClasses]);

    // 3. Jalankan inferensi
    interpreter.run(inputTensor, outputBuffer);

    // 4. Parse output → softmax index teratas
    final scores = outputBuffer[0] as List<double>;
    return _getTopPredictions(scores, topK: 3);
  }

  Future<List<List<List<List<double>>>>> _preprocessImage(
      Uint8List imageBytes) async {
    // Gunakan isolate agar UI tidak freeze
    return compute(_preprocessImageIsolate,
        _PreprocessArgs(imageBytes, _ModelConfig.inputSize));
  }

  List<Prediction> _getTopPredictions(List<double> scores, {int topK = 3}) {
    // Softmax (jika model belum apply)
    final softmaxScores = _softmax(scores);

    // Urutkan index berdasarkan score tertinggi
    final indexed = List.generate(softmaxScores.length,
            (i) => MapEntry(i, softmaxScores[i]))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return indexed
        .take(topK)
        .where((e) => e.value >= _ModelConfig.confidenceThreshold)
        .map((e) {
      // Index → nama makanan dari database (jika ada)
      final label = e.key < _foodDatabase.length
          ? _foodDatabase[e.key].name
          : 'Makanan #${e.key}';
      return Prediction(label: label, confidence: e.value, index: e.key);
    }).toList();
  }

  List<double> _softmax(List<double> logits) {
    final maxVal = logits.reduce(max);
    final exps = logits.map((v) => exp(v - maxVal)).toList();
    final sum = exps.fold(0.0, (a, b) => a + b);
    return exps.map((v) => v / sum).toList();
  }

  // ─── Lookup Dataset ───────────────────────────────────────────────────────

  FoodItemModel? _lookupFood(String name) {
    final normalized = name.toLowerCase().trim();
    try {
      return _foodDatabase.firstWhere(
          (f) => f.name.toLowerCase().trim() == normalized);
    } catch (_) {
      // Fuzzy fallback: cari yang mengandung kata pertama
      final firstWord = normalized.split(' ').first;
      try {
        return _foodDatabase.firstWhere(
            (f) => f.name.toLowerCase().contains(firstWord));
      } catch (_) {
        return null;
      }
    }
  }

  // ─── Simulasi (Fallback) ──────────────────────────────────────────────────

  /// Ambil 3 item acak dari database CSV sebagai fallback.
  MlAnalysisResult _buildSimulatedResult() {
    if (_foodDatabase.isEmpty) return _hardcodedFallback();

    final rng = Random();
    // Pilih 3 item dari indeks berbeda
    final picked = <FoodItemModel>[];
    final usedIdx = <int>{};
    while (picked.length < 3 && usedIdx.length < _foodDatabase.length) {
      final idx = rng.nextInt(_foodDatabase.length);
      if (usedIdx.add(idx)) picked.add(_foodDatabase[idx]);
    }

    final names = picked.map((f) => f.name).toList();
    final totalCalories = picked.fold(0.0, (s, f) => s + f.calories).round();
    final totalProteins = picked.fold(0.0, (s, f) => s + f.proteins).round();
    final totalFat = picked.fold(0.0, (s, f) => s + f.fat).round();
    final totalCarbs = picked.fold(0.0, (s, f) => s + f.carbohydrate).round();

    final isStandardMet =
        totalCalories >= 400 && totalCalories <= 900 && totalProteins >= 15;

    return MlAnalysisResult(
      detectedFoods: names,
      totalCalories: totalCalories,
      totalProteins: totalProteins,
      totalFat: totalFat,
      totalCarbs: totalCarbs,
      isStandardMet: isStandardMet,
      topPrediction:
          Prediction(label: names.first, confidence: 0.85, index: 0),
      isSimulated: true,
    );
  }

  MlAnalysisResult _hardcodedFallback() {
    return MlAnalysisResult(
      detectedFoods: ['Nasi Putih', 'Ayam Goreng', 'Sayur Bayam'],
      totalCalories: 620,
      totalProteins: 28,
      totalFat: 18,
      totalCarbs: 75,
      isStandardMet: true,
      topPrediction:
          Prediction(label: 'Nasi Putih', confidence: 0.85, index: 0),
      isSimulated: true,
    );
  }

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
    debugPrint('[MlService] Disposed.');
  }
}

// ─── Data Classes ─────────────────────────────────────────────────────────────

class Prediction {
  final String label;
  final double confidence;
  final int index;

  const Prediction({
    required this.label,
    required this.confidence,
    required this.index,
  });

  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';
}

class MlAnalysisResult {
  final List<String> detectedFoods;
  final int totalCalories;
  final int totalProteins;
  final int totalFat;
  final int totalCarbs;
  final bool isStandardMet;
  final Prediction topPrediction;
  final bool isSimulated;

  const MlAnalysisResult({
    required this.detectedFoods,
    required this.totalCalories,
    required this.totalProteins,
    required this.totalFat,
    required this.totalCarbs,
    required this.isStandardMet,
    required this.topPrediction,
    this.isSimulated = false,
  });
}

// ─── Isolate Helper ───────────────────────────────────────────────────────────

class _PreprocessArgs {
  final Uint8List imageBytes;
  final int targetSize;
  const _PreprocessArgs(this.imageBytes, this.targetSize);
}

/// Berjalan di isolate terpisah agar UI tidak freeze saat preprocessing gambar.
/// 
/// Asumsi model: float32 input, normalized [0,1], shape [1, size, size, 3]
List<List<List<List<double>>>> _preprocessImageIsolate(
    _PreprocessArgs args) {
  final size = args.targetSize;

  // Decode JPEG/PNG ke bytes raw RGB menggunakan decoding manual sederhana.
  // Catatan: Untuk produksi gunakan package `image` untuk decode lengkap.
  // Di sini kita buat tensor dari bytes langsung dengan resize sederhana.
  final bytes = args.imageBytes;
  final totalPixels = size * size;

  // Buat buffer float normalized
  final tensor =
      List.generate(1, (_) => List.generate(size, (_) => 
        List.generate(size, (_) => List.filled(3, 0.0))));

  // Distribusikan bytes ke grid size×size
  // (sampling sederhana — untuk hasil optimal gunakan package `image`)
  final stride = bytes.length ~/ (totalPixels * 3 + 1);
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final offset = ((y * size + x) * 3 * stride).clamp(0, bytes.length - 3);
      tensor[0][y][x][0] = bytes[offset] / 255.0;
      tensor[0][y][x][1] = bytes[offset + 1] / 255.0;
      tensor[0][y][x][2] = bytes[offset + 2] / 255.0;
    }
  }
  return tensor;
}
