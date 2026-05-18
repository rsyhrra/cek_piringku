import 'package:flutter/material.dart';
import 'dart:math';
import '../constants/colors.dart';
import '../constants/dummy_data.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  late String randomFact;

  @override
  void initState() {
    super.initState();
    randomFact = DummyData.nutritionalFacts[Random().nextInt(DummyData.nutritionalFacts.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edukasi Gizi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primaryGreen,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Fun Fact Card
            _buildCard(
              color: AppColors.primaryGreen.withOpacity(0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.lightbulb_outline_rounded, color: AppColors.alertOrange, size: 24),
                      SizedBox(width: 8),
                      Text("💡 Tahukah kamu?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryGreen)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    randomFact,
                    style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Lacking Nutrition Card
            const Text("Gizi yang masih kurang", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            _buildCard(
              child: Column(
                children: [
                  _buildLackingItem("Karbohidrat", "kurang 35 g", AppColors.alertOrange),
                  const Divider(height: 24),
                  _buildLackingItem("Protein", "kurang 22 g", AppColors.secondaryGreen),
                  const Divider(height: 24),
                  _buildLackingItem("Kalori", "kurang 480 kkal", AppColors.alertRed),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Recommendations Section (Matching Mockup)
            const Text("Saran Tambahan Menu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildRecommendationCard("Telur Rebus", "+3g Protein", Icons.egg_rounded)),
                const SizedBox(width: 16),
                Expanded(child: _buildRecommendationCard("Tempe/Tahu", "+4g Protein", Icons.eco_rounded)),
              ],
            ),
            const SizedBox(height: 16),
            _buildCard(
              child: _buildRecommendationItem("🥬", "Kangkung", "Sumber serat & vitamin"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child, Color color = AppColors.white}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  Widget _buildRecommendationCard(String name, String gain, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primaryGreen, size: 32),
          ),
          const SizedBox(height: 12),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              gain,
              style: const TextStyle(color: AppColors.secondaryGreen, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLackingItem(String name, String detail, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        Text(detail, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildRecommendationItem(String emoji, String name, String desc) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(desc, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}
