class User {
  final String name;
  final String grade;
  final String school;
  final int points;
  final int streak;
  final int totalScans;

  User({
    required this.name,
    required this.grade,
    required this.school,
    required this.points,
    required this.streak,
    required this.totalScans,
  });

  User copyWith({
    String? name,
    String? grade,
    String? school,
    int? points,
    int? streak,
    int? totalScans,
  }) {
    return User(
      name: name ?? this.name,
      grade: grade ?? this.grade,
      school: school ?? this.school,
      points: points ?? this.points,
      streak: streak ?? this.streak,
      totalScans: totalScans ?? this.totalScans,
    );
  }
}
