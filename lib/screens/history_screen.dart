import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/colors.dart';
import '../services/nutrition_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primaryGreen,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none_rounded), onPressed: () {}),
        ],
      ),
      body: Consumer<NutritionService>(
        builder: (context, nutritionService, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mei 2024',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Row(
                      children: [
                        IconButton(icon: const Icon(Icons.chevron_left), onPressed: () {}),
                        IconButton(icon: const Icon(Icons.chevron_right), onPressed: () {}),
                      ],
                    )
                  ],
                ),
                
                // Calendar Days (Simplified)
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (index) {
                    final days = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
                    bool isSelected = index == 3; // Mock today
                    return Column(
                      children: [
                        Text(days[index], style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                        const SizedBox(height: 8),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryGreen : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${21 + index}',
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 24),

                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari menu atau tanggal...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Scans List
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Scans Terakhir',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    TextButton(onPressed: () {}, child: const Text('Lihat Semua', style: TextStyle(color: AppColors.secondaryGreen))),
                  ],
                ),
                const SizedBox(height: 12),
                if (nutritionService.scans.isEmpty)
                  const Center(child: Text("Belum ada riwayat scan hari ini"))
                else
                  ...nutritionService.scans.reversed.map((scan) => _buildHistoryItem(
                    name: scan.foodItems.join(', '),
                    time: '${scan.timestamp.hour}:${scan.timestamp.minute} • ${scan.timestamp.day} Mei 2024',
                    isCompliant: scan.isStandardMet,
                    calories: '${scan.calories} kcal',
                  )),

                const SizedBox(height: 24),

                // Trend Card
                _buildTrendCard(),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryItem({
    required String name,
    required String time,
    required bool isCompliant,
    required String calories,
  }) {
    Color statusColor = isCompliant ? AppColors.secondaryGreen : AppColors.alertOrange;
    IconData statusIcon = isCompliant ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.restaurant_rounded, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(time, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Icon(statusIcon, color: statusColor, size: 20),
        ],
      ),
    );
  }

  Widget _buildTrendCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('TREND\nMINGGUAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(height: 8),
                  Text('84%', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32)),
                  Text('Kepatuhan', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('+12% Minggu Ini', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Simple sparkline simulation
          SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(5, (index) {
                final heights = [0.6, 0.4, 0.9, 0.5, 0.8];
                return Container(
                  width: 40,
                  height: 60 * heights[index],
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Sen', style: TextStyle(color: Colors.white70, fontSize: 10)),
              Text('Sel', style: TextStyle(color: Colors.white70, fontSize: 10)),
              Text('Rab', style: TextStyle(color: Colors.white70, fontSize: 10)),
              Text('Kam', style: TextStyle(color: Colors.white70, fontSize: 10)),
              Text('Jum', style: TextStyle(color: Colors.white70, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
