import 'goal.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final GoalType type;
  final GoalLevel level;
  final DateTime startedAt;
  final DateTime completedAt;
  final List<GoalSegment> segments;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.level,
    required this.startedAt,
    required this.completedAt,
    required this.segments,
  });

  /// Number of calendar days from start to completion (same-day = 0 days, next day = 1, etc.)
  int get daysTaken => completedAt.difference(startedAt).inDays;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'type': type.name,
    'level': level.name,
    'startedAt': startedAt.toIso8601String(),
    'completedAt': completedAt.toIso8601String(),
    'segments': segments.map((s) => s.toJson()).toList(),
  };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    type: GoalType.values.firstWhere((t) => t.name == json['type']),
    level: GoalLevel.values.firstWhere((l) => l.name == json['level']),
    startedAt: DateTime.parse(json['startedAt'] as String),
    completedAt: DateTime.parse(json['completedAt'] as String),
    segments: (json['segments'] as List<dynamic>? ?? [])
        .map((s) => GoalSegment.fromJson(s as Map<String, dynamic>))
        .toList(),
  );

  /// Snapshot a Goal at the moment of completion.
  factory Achievement.fromGoal(Goal goal) => Achievement(
    id: goal.id,
    title: goal.title,
    description: goal.description,
    type: goal.type,
    level: goal.level,
    startedAt: goal.createdAt,
    completedAt: DateTime.now(),
    segments: List.unmodifiable(goal.segments.map((s) => s.copyWith())),
  );
}
