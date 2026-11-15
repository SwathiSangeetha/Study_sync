class Subject {
  final String id;
  final String name;
  final int durationMinutes;
  final String emoji;
  final bool isActive;
  final int weaknessLevel; // 1: Low, 2: Med, 3: High

  Subject({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.emoji,
    this.isActive = true,
    this.weaknessLevel = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'durationMinutes': durationMinutes,
      'emoji': emoji,
      'isActive': isActive,
      'weaknessLevel': weaknessLevel,
    };
  }

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'],
      name: json['name'],
      durationMinutes: json['durationMinutes'],
      emoji: json['emoji'],
      isActive: json['isActive'] ?? true,
      weaknessLevel: json['weaknessLevel'] ?? 1,
    );
  }

  Subject copyWith({bool? isActive, int? weaknessLevel}) {
    return Subject(
      id: id,
      name: name,
      durationMinutes: durationMinutes,
      emoji: emoji,
      isActive: isActive ?? this.isActive,
      weaknessLevel: weaknessLevel ?? this.weaknessLevel,
    );
  }
}
