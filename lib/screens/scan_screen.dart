import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../constants/colors.dart';
import '../services/nutrition_service.dart';
import '../services/reward_service.dart';
import '../widgets/nutrition_card.dart';

class ScanScreen extends StatefulWidget {
  final VoidCallback onViewHistory;
  
  const ScanScreen({super.key, required this.onViewHistory});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraReady = false;
  bool _hasResult = false;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isCameraReady = true;
          });
        }
      } else {
        // No cameras found, use simulation mode
        debugPrint("No cameras found, entering simulation mode");
        if (mounted) {
          setState(() {
            _isCameraReady = true; // Still mark as ready to show the UI
          });
        }
      }
    } catch (e) {
      debugPrint("Camera error: $e");
      // Error occurred, fallback to simulation mode
      if (mounted) {
        setState(() {
          _isCameraReady = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureAndAnalyze() async {
    setState(() {
      _isAnalyzing = true;
    });

    // Simulate analysis delay
    await Future.delayed(const Duration(seconds: 2));

    final nutritionService = Provider.of<NutritionService>(context, listen: false);
    final rewardService = Provider.of<RewardService>(context, listen: false);

    // Pick a random dummy result for simulation
    final result = await nutritionService.analyzeMeal("simulated_path");
    
    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _hasResult = true;
      });
      
      await rewardService.addScanReward(result.isStandardMet);
      
      if (!result.isStandardMet) {
        _showAlertBadge();
      }
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
          // Camera Preview or Simulation Background
          Positioned.fill(
            child: isUsingCamera 
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

          // AI Overlay (Bounding Boxes & Guides)
          if (!_hasResult) _buildAIOverlay(),

          // Top Header (Calories & Status)
          _buildHeader(),

          // Bottom Controls
          _buildBottomControls(),

          // Analysis Result Card (Overlay when finished)
          if (_hasResult) _buildResultOverlay(),
          
          // Analysis Loading
          if (_isAnalyzing) 
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(color: AppColors.primaryGreen),
                    SizedBox(height: 16),
                    Text("🔍 Menganalisis Kandungan Gizi...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('ESTIMATED CALORIES', style: TextStyle(color: Colors.white70, fontSize: 10)),
                    Text('~ 345 kcal', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryGreen.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Compliant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIOverlay() {
    return Stack(
      children: [
        // Guidance Box (Ompreng Shape)
        Center(
          child: Container(
            width: 300,
            height: 450,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white38, width: 2),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        
        // Mock Bounding Boxes
        _buildBoundingBox(120, 200, "Telur Rebus 50g", true),
        _buildBoundingBox(160, 380, "Nasi 150g", true),
        _buildBoundingBox(240, 250, "Sayur Hijau", false),
      ],
    );
  }

  Widget _buildBoundingBox(double top, double left, String label, bool isOk) {
    return Positioned(
      top: top,
      left: left,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isOk ? AppColors.primaryGreen : AppColors.alertOrange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isOk ? Icons.check_circle : Icons.warning, color: Colors.white, size: 12),
                const SizedBox(width: 4),
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              border: Border.all(color: isOk ? AppColors.primaryGreen : AppColors.alertOrange, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
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
          const SizedBox(height: 30),
          
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
          const SizedBox(height: 24),
          const Text(
            "Tahan posisi piring di dalam kotak panduan",
            style: TextStyle(color: Colors.white70, fontSize: 14),
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

  Widget _buildResultOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.85),
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
