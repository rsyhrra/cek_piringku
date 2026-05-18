import 'package:flutter/material.dart';
import '../models/nutrition_model.dart';
import '../constants/colors.dart';
import '../widgets/progress_bar.dart';

class NutritionCard extends StatelessWidget {
  final NutritionModel scanResult;

  const NutritionCard({super.key, required this.scanResult});

  @override
  Widget build(BuildContext context) {
    final statusColor = scanResult.isStandardMet ? AppColors.secondaryGreen : AppColors.alertOrange;
    
    return Column(
      children: [
        // Status Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  scanResult.isStandardMet ? Icons.check_rounded : Icons.priority_high_rounded,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scanResult.isStandardMet ? "GIZI SESUAI STANDAR" : "GIZI BELUM SESUAI",
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      scanResult.isStandardMet 
                        ? "Berdasarkan pedoman Kemenkes RI" 
                        : "Saran: Tambahkan sumber protein",
                      style: TextStyle(
                        color: AppColors.white.withOpacity(0.9),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Content Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Analisis Nutrisi",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    "Detail Penuh",
                    style: TextStyle(color: AppColors.secondaryGreen, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                   _buildLargeInfo("TOTAL ENERGI", "${scanResult.calories} kkal"),
                   const Spacer(),
                   _buildLargeInfo("SKOR KEPATUHAN", "98 %", isGreen: true),
                ],
              ),
              const SizedBox(height: 24),
              CustomProgressBar(label: "Protein", current: scanResult.protein, max: 24, color: AppColors.secondaryGreen),
              const SizedBox(height: 16),
              CustomProgressBar(label: "Karbohidrat", current: scanResult.carbs, max: 90, color: AppColors.alertOrange),
              const SizedBox(height: 16),
              CustomProgressBar(label: "Lemak", current: scanResult.fats, max: 20, color: AppColors.alertRed),
              const SizedBox(height: 16),
              CustomProgressBar(label: "Serat & Vitamin", current: 12, max: 10, color: Colors.blue),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLargeInfo(String label, String value, {bool isGreen = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: isGreen ? AppColors.secondaryGreen : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ],
    );
  }
}
