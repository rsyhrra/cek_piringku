/// Model yang merepresentasikan satu item makanan dari dataset nutrition.csv
/// Format CSV: id, calories, proteins, fat, carbohydrate, name, image
class FoodItemModel {
  final int id;
  final String name;
  final double calories;
  final double proteins;
  final double fat;
  final double carbohydrate;
  final String imageUrl;

  const FoodItemModel({
    required this.id,
    required this.name,
    required this.calories,
    required this.proteins,
    required this.fat,
    required this.carbohydrate,
    required this.imageUrl,
  });

  /// Parse dari satu baris CSV [id, calories, proteins, fat, carbohydrate, name, image]
  factory FoodItemModel.fromCsvRow(List<dynamic> row) {
    return FoodItemModel(
      id: _parseInt(row[0]),
      calories: _parseDouble(row[1]),
      proteins: _parseDouble(row[2]),
      fat: _parseDouble(row[3]),
      carbohydrate: _parseDouble(row[4]),
      name: row[5].toString().trim(),
      imageUrl: row.length > 6 ? row[6].toString().trim() : '',
    );
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    return double.tryParse(v.toString()) ?? 0.0;
  }

  @override
  String toString() =>
      'FoodItemModel(id: $id, name: $name, cal: $calories, pro: $proteins, fat: $fat, carb: $carbohydrate)';
}
