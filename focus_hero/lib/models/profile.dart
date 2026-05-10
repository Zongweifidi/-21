class Profile {
  final int id;
  final String username;
  final int level;
  final int exp;
  final int totalTomatoes;
  final int maxStreak;
  final String updatedAt;

  Profile({
    required this.id,
    required this.username,
    required this.level,
    required this.exp,
    required this.totalTomatoes,
    required this.maxStreak,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'level': level,
      'exp': exp,
      'total_tomatoes': totalTomatoes,
      'max_streak': maxStreak,
      'updated_at': updatedAt,
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'],
      username: map['username'] ?? '专注英雄',
      level: map['level'] ?? 1,
      exp: map['exp'] ?? 0,
      totalTomatoes: map['total_tomatoes'] ?? 0,
      maxStreak: map['max_streak'] ?? 0,
      updatedAt: map['updated_at'] ?? DateTime.now().toIso8601String(),
    );
  }
}
