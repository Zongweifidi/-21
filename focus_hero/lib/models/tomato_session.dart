class TomatoSession {
  final String? id;
  final String completedAt;
  final int duration;
  final bool interrupted;

  TomatoSession({
    this.id,
    required this.completedAt,
    required this.duration,
    required this.interrupted,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'completed_at': completedAt,
      'duration': duration,
      'interrupted': interrupted ? 1 : 0,
    };
  }

  factory TomatoSession.fromMap(Map<String, dynamic> map) {
    return TomatoSession(
      id: map['id'],
      completedAt: map['completed_at'],
      duration: map['duration'],
      interrupted: map['interrupted'] == 1,
    );
  }
}
