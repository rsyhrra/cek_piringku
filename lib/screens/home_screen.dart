import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../services/reward_service.dart';
import '../services/nutrition_service.dart';
import '../widgets/progress_bar.dart';
import '../widgets/streak_widget.dart';
import '../widgets/badge_widget.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onScanPressed;

  const HomeScreen({super.key, required this.onScanPressed});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer2<RewardService, NutritionService>(
          builder: (context, rewardService, nutritionService, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selamat Pagi,',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            rewardService.user.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.accentMint,
                        child: Icon(Icons.notifications_none_rounded, color: AppColors.primaryGreen, size: 24),
                      )
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.restaurant_rounded,
                          value: '150',
                          label: 'MEALS SCANNED\nTODAY',
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.check_circle_outline_rounded,
                          value: '88%',
                          label: 'COMPLIANCE\nRATE',
                          color: AppColors.alertOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Scan Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: onScanPressed,
                      icon: const Icon(Icons.camera_alt_outlined, size: 24),
                      label: const Text(
                        'Scan Menu',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Recent Scans Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Scans',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Lihat Semua', style: TextStyle(color: AppColors.secondaryGreen, fontSize: 13)),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Mock Recent Scans List
                  _buildRecentScanItem(
                    name: 'Nasi Campur Ayam',
                    time: '10:45 AM • Kelas 4B',
                    status: 'COMPLIANT',
                    calories: '450 kcal',
                    statusColor: AppColors.secondaryGreen,
                  ),
                  _buildRecentScanItem(
                    name: 'Gado-Gado Sayur',
                    time: '10:30 AM • Kelas 2A',
                    status: 'LOW PROTEIN',
                    calories: '320 kcal',
                    statusColor: AppColors.alertOrange,
                  ),
                  _buildRecentScanItem(
                    name: 'Soto Ayam Kuning',
                    time: '10:15 AM • Kelas 6C',
                    status: 'COMPLIANT',
                    calories: '380 kcal',
                    statusColor: AppColors.secondaryGreen,
                  ),

                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required String value, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentScanItem({
    required String name,
    required String time,
    required String status,
    required String calories,
    required Color statusColor,
  }) {
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
            child: const Icon(Icons.fastfood_rounded, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                calories,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
