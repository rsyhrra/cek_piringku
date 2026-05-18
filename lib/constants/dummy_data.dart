import '../models/badge_model.dart';
import '../models/nutrition_model.dart';
import '../models/user_model.dart';

class DummyData {
  static final User currentUser = User(
    name: "Budi Santoso",
    grade: "Kelas 8A",
    school: "SMP Negeri 1 Jakarta",
    points: 120,
    streak: 3,
    totalScans: 15,
  );

  static final List<BadgeModel> allBadges = [
    BadgeModel(
      id: '1',
      name: 'Sayur Lover',
      description: '5x scan dengan sayur lengkap',
      iconAsset: '🥦', // We can use emojis for simplicity instead of actual image assets if no assets are provided
      isUnlocked: true,
    ),
    BadgeModel(
      id: '2',
      name: 'Protein King',
      description: '3x scan protein cukup',
      iconAsset: '🍗',
      isUnlocked: true,
    ),
    BadgeModel(
      id: '3',
      name: 'Full Energy',
      description: 'Scan dengan gizi sempurna',
      iconAsset: '⚡',
      isUnlocked: false,
    ),
    BadgeModel(
      id: '4',
      name: 'Konsisten 7',
      description: 'Streak 7 hari berturut-turut',
      iconAsset: '🔥',
      isUnlocked: false,
    ),
    BadgeModel(
      id: '5',
      name: 'Master Gizi',
      description: 'Total 30x scan',
      iconAsset: '🌟',
      isUnlocked: false,
    ),
  ];

  static final NutritionModel goodNutrition = NutritionModel(
    id: 'n1',
    timestamp: DateTime.now(),
    calories: 650,
    protein: 30,
    carbs: 85,
    fats: 15,
    foodItems: ['Nasi', 'Ayam Bakar', 'Sayur Bayam', 'Tahu'],
    isStandardMet: true,
  );

  static final NutritionModel badNutrition = NutritionModel(
    id: 'n2',
    timestamp: DateTime.now(),
    calories: 450,
    protein: 15,
    carbs: 70,
    fats: 12,
    foodItems: ['Nasi', 'Mie Goreng', 'Kerupuk'],
    isStandardMet: false,
  );

  static final List<String> nutritionalFacts = [
    "Tahukah kamu? Protein membantu konsentrasi belajarmu!",
    "Sayuran berdaun hijau mengandung zat besi yang mencegah kamu dari rasa kantuk di kelas.",
    "Karbohidrat kompleks dari nasi merah atau kentang memberikan energi yang tahan lebih lama.",
    "Minum air putih yang cukup sangat penting agar otakmu bekerja maksimal."
  ];
}
