import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// ─── Enums ────────────────────────────────────────────────────────────────────

enum GoalType { simple, segmented }

enum GoalLevel { spark, grind, hustle, elite, legend }

extension GoalLevelX on GoalLevel {
  String get displayName {
    switch (this) {
      case GoalLevel.spark:   return 'Spark';
      case GoalLevel.grind:   return 'Grind';
      case GoalLevel.hustle:  return 'Hustle';
      case GoalLevel.elite:   return 'Elite';
      case GoalLevel.legend:  return 'Legend';
    }
  }

  String get emoji {
    switch (this) {
      case GoalLevel.spark:   return '🌱';
      case GoalLevel.grind:   return '⚡';
      case GoalLevel.hustle:  return '🔥';
      case GoalLevel.elite:   return '💎';
      case GoalLevel.legend:  return '👑';
    }
  }

  String get description {
    switch (this) {
      case GoalLevel.spark:   return 'Small habit';
      case GoalLevel.grind:   return 'Regular effort';
      case GoalLevel.hustle:  return 'Hard pursuit';
      case GoalLevel.elite:   return 'Major milestone';
      case GoalLevel.legend:  return 'Life-defining';
    }
  }
}

// ─── GoalSegment ──────────────────────────────────────────────────────────────

class GoalSegment {
  final String id;
  String title;
  bool completed;

  GoalSegment({
    String? id,
    required this.title,
    this.completed = false,
  }) : id = id ?? _uuid.v4();

  GoalSegment copyWith({String? id, String? title, bool? completed}) {
    return GoalSegment(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'completed': completed,
  };

  factory GoalSegment.fromJson(Map<String, dynamic> json) => GoalSegment(
    id: json['id'] as String,
    title: json['title'] as String,
    completed: json['completed'] as bool? ?? false,
  );
}

// ─── Goal ─────────────────────────────────────────────────────────────────────

class Goal {
  final String id;
  String title;
  String description;
  GoalType type;
  GoalLevel level;
  final DateTime createdAt;
  List<GoalSegment> segments;

  Goal({
    String? id,
    required this.title,
    this.description = '',
    required this.type,
    required this.level,
    DateTime? createdAt,
    List<GoalSegment>? segments,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        segments = segments ?? [];

  /// 0.0 → 1.0. Always 0 for simple goals.
  double get progress {
    if (type == GoalType.simple || segments.isEmpty) return 0.0;
    return segments.where((s) => s.completed).length / segments.length;
  }

  int get completedSegments => segments.where((s) => s.completed).length;

  /// Simple goals can always be completed; segmented only when all done.
  bool get canComplete {
    if (type == GoalType.simple) return true;
    return segments.isNotEmpty && segments.every((s) => s.completed);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'type': type.name,
    'level': level.name,
    'createdAt': createdAt.toIso8601String(),
    'segments': segments.map((s) => s.toJson()).toList(),
  };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    type: GoalType.values.firstWhere((t) => t.name == json['type']),
    level: GoalLevel.values.firstWhere((l) => l.name == json['level']),
    createdAt: DateTime.parse(json['createdAt'] as String),
    segments: (json['segments'] as List<dynamic>? ?? [])
        .map((s) => GoalSegment.fromJson(s as Map<String, dynamic>))
        .toList(),
  );
}
