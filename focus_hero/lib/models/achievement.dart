class Achievement {
  final String id;
  final String achievementKey;
  final String unlockedAt;

  Achievement({
    required this.id,
    required this.achievementKey,
    required this.unlockedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'achievement_key': achievementKey,
      'unlocked_at': unlockedAt,
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'],
      achievementKey: map['achievement_key'],
      unlockedAt: map['unlocked_at'],
    );
  }
}
