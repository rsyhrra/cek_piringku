import 'dart:io';
import 'dart:math';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'package:image/image.dart' as img;

import '../models/food_item_model.dart';

/// Konfigurasi model TFLite.
/// Disesuaikan khusus untuk model YOLOv8n-seg yang memiliki input size 320x320.
class _ModelConfig {
  /// Ukuran input gambar (lebar & tinggi dalam pixel).
  /// Model YOLOv8n-seg yang Anda miliki menggunakan input 320x320.
  static const int inputSize = 320;

  /// Path asset model TFLite
  static const String modelPath = 'assets/models/best_float32.tflite';

  /// Path asset dataset utama (label + nilai gizi)
  static const String nutritionCsvPath = 'assets/data/nutrition.csv';

  /// Threshold confidence minimum agar hasil deteksi diterima (0.0–1.0)
  static const double confidenceThreshold = 0.25;
}

/// Service utama untuk:
/// 1. Memuat & menjalankan model TFLite (YOLOv8n-seg menu makanan)
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

  /// Daftar Label Kelas dari model YOLOv8n-seg Anda (total 39 kelas)
  /// yang diekstrak langsung dari metadata model.
  static const List<String> _modelLabels = [
    "Acar Timun Wortel",
    "Anggur",
    "Apel",
    "Ayam Goreng",
    "Ayam Serundeng",
    "Bakso Saus BBQ",
    "Capcay",
    "Chiken Katsu",
    "Fla Susu",
    "Gudeg",
    "Jagung",
    "Jeruk",
    "Kacang Merah",
    "Keju",
    "Kelengkeng",
    "Ketimun dan Selada",
    "Kwetiaw",
    "Lele Crispy",
    "Lontong",
    "Mie",
    "Nasi",
    "Nasi Daun Jeruk",
    "Pepes Tahu",
    "Pisang",
    "Pisang Lampung",
    "Rolade Asam Manis",
    "Roti",
    "Salad Buah",
    "Sawi",
    "Sayur Isi Pepaya",
    "Semur Ayam Kecap",
    "Tahu",
    "Tahu Crispy",
    "Telur",
    "Telur Semur",
    "Tempe Goreng",
    "Tempe Sagu",
    "Tumis Keciwis",
    "Tumis Koll Wortel"
  ];

  // ─── Inisialisasi ─────────────────────────────────────────────────────────

  /// Muat model TFLite dan dataset CSV ke memori.
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
    final rows = const CsvToListConverter(eol: '\n').convert(raw);
    _foodDatabase = rows
        .skip(1)
        .where((row) => row.length >= 6)
        .map((row) => FoodItemModel.fromCsvRow(row))
        .toList();
    debugPrint('[MlService] ${_foodDatabase.length} item makanan dari CSV.');
  }

  // ─── Analisis Gambar ──────────────────────────────────────────────────────

  /// Analisis gambar makanan dari [imagePath].
  Future<MlAnalysisResult> analyzeFoodImage(String imagePath) async {
    if (!_isInitialized) await initialize();

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
        } else {
          // Jika tidak ada di database, gunakan nama dari model langsung
          detectedFoods.add(pred.label);
        }
      }

      if (detectedFoods.isEmpty) return _buildSimulatedResult();

      // Standar BGN: kalori 400–900 kcal, protein ≥15g
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

    // 1. Load & preprocess gambar ke 320x320
    final imageBytes = await File(imagePath).readAsBytes();
    final inputTensor = await _preprocessImage(imageBytes);

    // 2. Alokasikan buffer secara dinamis untuk multi-output model YOLOv8
    final outputs = <int, Object>{};
    final outputTensors = interpreter.getOutputTensors();

    for (int i = 0; i < outputTensors.length; i++) {
      final shape = outputTensors[i].shape;
      if (shape.length == 3) {
        // [1, 75, 2100] untuk YOLOv8 Preds
        outputs[i] = List.generate(shape[0], (_) => 
          List.generate(shape[1], (_) => 
            List.filled(shape[2], 0.0)));
      } else if (shape.length == 4) {
        // [1, 32, 160, 160] untuk Prototype Masks
        outputs[i] = List.generate(shape[0], (_) => 
          List.generate(shape[1], (_) => 
            List.generate(shape[2], (_) => 
              List.filled(shape[3], 0.0))));
      } else {
        final size = shape.fold(1, (a, b) => a * b);
        outputs[i] = List.filled(size, 0.0);
      }
    }

    // 3. Jalankan inferensi untuk model multi-output
    final inputs = [inputTensor];
    interpreter.runForMultipleInputs(inputs, outputs);

    // 4. Parse YOLOv8 Detection Output (Output 0)
    final predTensor = outputTensors[0];
    final predShape = predTensor.shape;

    if (predShape.length == 3) {
      final rawPreds = outputs[0] as List<List<List<double>>>;
      final dim1 = predShape[1];
      final dim2 = predShape[2];

      // Deteksi bentuk transpose (biasanya dim1=75 channel, dim2=2100 anchor)
      final bool isTransposed = dim1 < dim2;
      final int channels = isTransposed ? dim1 : dim2;
      final int anchors = isTransposed ? dim2 : dim1;

      debugPrint('[MlService] Output shape: [$dim1, $dim2], isTransposed=$isTransposed, channels=$channels, anchors=$anchors');

      // Kumpulkan skor TERTINGGI per kelas di semua anchors
      final classMaxScores = List.filled(_modelLabels.length, -999.0);

      for (int a = 0; a < anchors; a++) {
        for (int c = 0; c < _modelLabels.length; c++) {
          final int channelIdx = 4 + c; // Lewati 4 koordinat box awal
          if (channelIdx >= channels) break;

          final double score = isTransposed
              ? rawPreds[0][channelIdx][a]
              : rawPreds[0][a][channelIdx];

          if (score > classMaxScores[c]) {
            classMaxScores[c] = score;
          }
        }
      }

      // Log top-5 scores untuk debugging (terlihat di flutter run console)
      final debugList = List.generate(_modelLabels.length, (i) => MapEntry(i, classMaxScores[i]))
        ..sort((a, b) => b.value.compareTo(a.value));
      final top5 = debugList.take(5).map((e) => '${_modelLabels[e.key]}=${e.value.toStringAsFixed(3)}').join(', ');
      debugPrint('[MlService] Top-5 scores: $top5');

      // SELALU ambil prediksi terbaik (tidak ada threshold cutoff)
      // Urutkan semua kelas dari skor tertinggi ke terendah
      final sorted = List.generate(_modelLabels.length, (c) => MapEntry(c, classMaxScores[c]))
        ..sort((a, b) => b.value.compareTo(a.value));

      final result = <Prediction>[];

      // Ambil top-1 SELALU (item utama, apapun score-nya)
      final top1 = sorted.first;
      result.add(Prediction(
        label: _modelLabels[top1.key],
        confidence: top1.value,
        index: top1.key,
      ));

      // Tambahkan item ke-2 dan ke-3 HANYA jika score mereka > 0.50 DAN
      // sangat dekat (selisih <= 0.20) dengan item utama
      for (int i = 1; i < sorted.length && result.length < 3; i++) {
        final entry = sorted[i];
        if (entry.value >= 0.50 && (top1.value - entry.value) <= 0.20) {
          result.add(Prediction(
            label: _modelLabels[entry.key],
            confidence: entry.value,
            index: entry.key,
          ));
        } else {
          break; // Sudah tidak ada yang cukup tinggi
        }
      }

      debugPrint('[MlService] Returning ${result.length} prediction(s): ${result.map((p) => "${p.label}(${p.confidence.toStringAsFixed(3)})").join(", ")}');
      return result;
    } else {
      // Fallback untuk model klasifikasi standar [1, numClasses]
      final flatPreds = outputs[0] as List<List<double>>;
      return _getTopPredictions(flatPreds[0], topK: 1);
    }
  }

  Future<List<List<List<List<double>>>>> _preprocessImage(
      Uint8List imageBytes) async {
    return compute(_preprocessImageIsolate,
        _PreprocessArgs(imageBytes, _ModelConfig.inputSize));
  }

  List<Prediction> _getTopPredictions(List<double> scores, {int topK = 3}) {
    final softmaxScores = _softmax(scores);
    final indexed = List.generate(softmaxScores.length,
            (i) => MapEntry(i, softmaxScores[i]))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return indexed
        .take(topK)
        .where((e) => e.value >= _ModelConfig.confidenceThreshold)
        .map((e) {
      final label = e.key < _modelLabels.length
          ? _modelLabels[e.key]
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
    
    // Pemetaan khusus (typo dari label model agar cocok ke nama CSV)
    String lookupName = normalized;
    if (normalized == "chiken katsu") {
      lookupName = "chicken katsu";
    }

    try {
      // Cari kecocokan persis
      return _foodDatabase.firstWhere(
          (f) => f.name.toLowerCase().trim() == lookupName);
    } catch (_) {
      // Fuzzy fallback: cari nama di database yang mengandung kata model
      final words = lookupName.split(' ');
      final firstWord = words.first;
      try {
        return _foodDatabase.firstWhere(
            (f) => f.name.toLowerCase().contains(firstWord));
      } catch (_) {
        // Fallback pencarian mengandung kata manapun
        for (final word in words) {
          if (word.length < 3) continue;
          try {
            return _foodDatabase.firstWhere(
                (f) => f.name.toLowerCase().contains(word));
          } catch (_) {}
        }
        return null;
      }
    }
  }

  // ─── Simulasi (Fallback) ──────────────────────────────────────────────────

  MlAnalysisResult _buildSimulatedResult() {
    if (_foodDatabase.isEmpty) return _hardcodedFallback();

    final rng = Random();
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

List<List<List<List<double>>>> _preprocessImageIsolate(
    _PreprocessArgs args) {
  final size = args.targetSize;
  
  // 1. Decode compressed JPEG/PNG bytes to raw Image
  final image = img.decodeImage(args.imageBytes);
  if (image == null) {
    throw Exception('Failed to decode JPEG/PNG image bytes');
  }

  // 2. Resize image berkualitas tinggi ke size x size (320x320)
  final resizedImage = img.copyResize(image, width: size, height: size);

  // 3. Inisialisasi float32 input tensor [1, size, size, 3]
  final tensor = List.generate(1, (_) => 
    List.generate(size, (_) => 
      List.generate(size, (_) => List.filled(3, 0.0))));

  // 4. Copy raw RGB ternormalisasi [0, 1] ke tensor
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final pixel = resizedImage.getPixel(x, y);
      
      // Mengakses RGB channel
      tensor[0][y][x][0] = pixel.r / 255.0; // Red
      tensor[0][y][x][1] = pixel.g / 255.0; // Green
      tensor[0][y][x][2] = pixel.b / 255.0; // Blue
    }
  }
  
  return tensor;
}
