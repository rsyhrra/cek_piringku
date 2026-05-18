import 'package:flutter/material.dart';
import '../models/badge_model.dart';
import '../constants/colors.dart';

class BadgeWidget extends StatelessWidget {
  final BadgeModel badge;

  const BadgeWidget({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: badge.isUnlocked ? AppColors.secondaryGreen.withOpacity(0.1) : Colors.grey.shade200,
              shape: BoxShape.circle,
              border: Border.all(
                color: badge.isUnlocked ? AppColors.secondaryGreen : Colors.grey.shade400,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                badge.isUnlocked ? badge.iconAsset : '🔒',
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            badge.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: badge.isUnlocked ? AppColors.textPrimary : Colors.grey.shade500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
