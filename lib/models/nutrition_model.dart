class NutritionModel {
  final String id;
  final DateTime timestamp;
  final int calories; // in kcal
  final int protein; // in grams
  final int carbs; // in grams
  final int fats; // in grams
  final List<String> foodItems;
  final bool isStandardMet;

  NutritionModel({
    required this.id,
    required this.timestamp,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.foodItems,
    required this.isStandardMet,
  });
}
