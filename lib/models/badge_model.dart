class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String iconAsset;
  final bool isUnlocked;

  BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconAsset,
    required this.isUnlocked,
  });

  BadgeModel copyWith({
    String? id,
    String? name,
    String? description,
    String? iconAsset,
    bool? isUnlocked,
  }) {
    return BadgeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconAsset: iconAsset ?? this.iconAsset,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }
}
