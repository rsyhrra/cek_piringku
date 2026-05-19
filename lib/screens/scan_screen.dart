import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../constants/colors.dart';
import '../services/nutrition_service.dart';
import '../services/reward_service.dart';
import '../widgets/nutrition_card.dart';
import '../services/ml_service.dart';
import '../services/roboflow_service.dart';
import '../widgets/mask_painter.dart';

class ScanScreen extends StatefulWidget {
  final VoidCallback onViewHistory;
  
  const ScanScreen({super.key, required this.onViewHistory});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraReady = false;
  bool _hasResult = false;
  bool _isAnalyzing = false;

  // Tambah variabel di state
  File? _capturedImage;
  List<SegmentationResult> _segmentations = [];
  Size _imageSize = const Size(640, 640);

  // Laser scanner animation (visual only, tidak ada loop inference)
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset.high, // High res untuk akurasi inferensi lebih baik
          enableAudio: false,
        );
        await _controller!.initialize();
        if (mounted) {
          setState(() => _isCameraReady = true);
        }
      } else {
        debugPrint("No cameras found, entering simulation mode");
        if (mounted) setState(() => _isCameraReady = true);
      }
    } catch (e) {
      debugPrint("Camera error: $e");
      if (mounted) setState(() => _isCameraReady = true);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureAndAnalyze() async {
    if (_isAnalyzing || _controller == null || !_controller!.value.isInitialized) return;

    setState(() => _isAnalyzing = true);

    try {
      final xFile = await _controller!.takePicture();
      final imageFile = File(xFile.path);

      // Dapatkan ukuran gambar asli
      final decodedImage = await decodeImageFromList(
          await imageFile.readAsBytes());
      final imgSize = Size(
          decodedImage.width.toDouble(),
          decodedImage.height.toDouble());

      // Kirim ke Roboflow untuk segmentasi
      final segments =
          await RoboflowService.detectWithMask(imageFile);

      if (!mounted) return;
      final nutritionService = Provider.of<NutritionService>(context, listen: false);
      final rewardService = Provider.of<RewardService>(context, listen: false);

      final result = await nutritionService.analyzeMeal(xFile.path);

      if (!mounted) return;

      if (result.foodItems.contains('Tidak ada makanan terdeteksi')) {
        setState(() {
          _isAnalyzing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Oups! Tidak ada makanan terdeteksi. Silakan coba scan ulang dengan pencahayaan yang lebih baik."),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      setState(() {
        _capturedImage = imageFile;
        _segmentations = segments;
        _imageSize = imgSize;
        _isAnalyzing = false;
        _hasResult = true;
      });

      await rewardService.addScanReward(result.isStandardMet);
      if (!result.isStandardMet) _showAlertBadge();
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _showAlertBadge() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text("Laporan gizi tidak sesuai dikirim ke BGN")),
          ],
        ),
        backgroundColor: AppColors.alertOrange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraReady) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
      );
    }

    final isUsingCamera = _controller != null && _controller!.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Preview / background simulasi
          Positioned.fill(
            child: (_hasResult && _capturedImage != null)
              ? _buildSegmentationView()
              : isUsingCamera 
                ? CameraPreview(_controller!) 
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.grey.shade900, Colors.black],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, color: AppColors.primaryGreen.withOpacity(0.3), size: 100),
                      const SizedBox(height: 20),
                      const Text(
                        "MODE SIMULASI AI SCAN",
                        style: TextStyle(color: Colors.white24, letterSpacing: 2, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
          ),

          // 2. Laser scanning overlay
          if (!_hasResult) _buildAIOverlay(),

          // 3. Top Header (Calories & Status)
          _buildHeader(),

          // 4. Bottom Controls (Zoom + Live HUD + Capture button)
          _buildBottomControls(),

          // 5. Card Hasil Analisis (Muncul setelah klik capture)
          if (_hasResult) _buildResultOverlay(),
          
          // 6. Spinner penganalisis utama
          if (_isAnalyzing) 
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(color: AppColors.primaryGreen),
                    SizedBox(height: 16),
                    Text("🔍 Memvalidasi & Menyimpan Hasil...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 40,
      left: 20,
      right: 20,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Text(
                'Cek-PiringKu',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.flash_on, color: Colors.white), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.help_outline, color: Colors.white), onPressed: () {}),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Consumer<NutritionService>(
            builder: (context, nutritionService, child) {
              final caloriesToday = nutritionService.todayCalories;
              final isCompliant = caloriesToday >= 400 && caloriesToday <= 900;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TOTAL KALORI HARI INI', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        Text('$caloriesToday kcal', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: caloriesToday == 0
                            ? Colors.white24
                            : (isCompliant
                                ? AppColors.secondaryGreen.withOpacity(0.8)
                                : AppColors.alertOrange.withOpacity(0.8)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        caloriesToday == 0
                            ? 'Ready'
                            : (isCompliant ? 'Sesuai Standar' : 'Tidak Sesuai'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAIOverlay() {
    return Stack(
      children: [
        // Laser scanning line moving up & down
        Center(
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Stack(
                children: [
                  Container(
                    width: 300,
                    height: 450,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white38, width: 2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  Positioned(
                    top: _animController.value * 440 + 5,
                    left: 10,
                    right: 10,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGreen.withOpacity(0.8),
                            blurRadius: 8,
                            spreadRadius: 2,
                          )
                        ],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLiveHudCard() {
    if (_hasResult) return const SizedBox();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withOpacity(0.8),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "AI SCANNER SIAP",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "📸 Posisikan piring di dalam kotak, lalu tekan tombol Capture",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Column(
        children: [
          // Sleek Sci-Fi Live Scanner HUD Card
          _buildLiveHudCard(),
          const SizedBox(height: 20),

          // Zoom controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildZoomBtn("0.5x"),
              const SizedBox(width: 12),
              _buildZoomBtn("1x", isActive: true),
              const SizedBox(width: 12),
              _buildZoomBtn("2x"),
            ],
          ),
          const SizedBox(height: 24),
          
          // Capture button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.photo_library_outlined, color: Colors.white)),
              GestureDetector(
                onTap: _captureAndAnalyze,
                child: Container(
                  width: 80,
                  height: 80,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.flip_camera_ios_outlined, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "Tahan piring makanan lalu tekan Capture",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomBtn(String text, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.black45,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: isActive ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildSegmentationView() {
    if (_capturedImage == null) return const SizedBox();

    return Stack(
      children: [
        // Gambar asli
        SizedBox.expand(
          child: Image.file(_capturedImage!, fit: BoxFit.cover),
        ),

        // Overlay segmentasi mask
        Positioned.fill(
          child: CustomPaint(
            painter: MaskPainter(
              detections: _segmentations,
              imageSize: _imageSize,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5), // Ubah opacity agar gambar terlihat
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: AppColors.secondaryGreen, size: 80),
          const SizedBox(height: 24),
          const Text(
            "Analisis Berhasil!",
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Consumer<NutritionService>(
            builder: (context, nutritionService, child) {
              if (nutritionService.scans.isEmpty) return const SizedBox();
              return NutritionCard(scanResult: nutritionService.scans.first);
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: widget.onViewHistory,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text("Simpan & Lanjutkan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => setState(() => _hasResult = false),
            child: const Text("Scan Ulang", style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
