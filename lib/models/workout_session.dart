class WorkoutSession {
  final int? id;
  final DateTime startTime;
  final DateTime endTime;
  final int squatCount;
  final double accuracy;
  final double averageDuration;
  final List<ExerciseSet> sets;
  final double caloriesBurned;

  WorkoutSession({
    this.id,
    required this.startTime,
    required this.endTime,
    required this.squatCount,
    required this.accuracy,
    required this.averageDuration,
    this.sets = const [],
    this.caloriesBurned = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'squatCount': squatCount,
      'accuracy': accuracy,
      'averageDuration': averageDuration,
      'caloriesBurned': caloriesBurned,
    };
  }

  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    return WorkoutSession(
      id: map['id'],
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      squatCount: map['squatCount'],
      accuracy: map['accuracy'],
      averageDuration: map['averageDuration'],
      caloriesBurned: map['caloriesBurned'],
    );
  }

  WorkoutSession copyWith({
    int? id,
    DateTime? startTime,
    DateTime? endTime,
    int? squatCount,
    double? accuracy,
    double? averageDuration,
    List<ExerciseSet>? sets,
    double? caloriesBurned,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      squatCount: squatCount ?? this.squatCount,
      accuracy: accuracy ?? this.accuracy,
      averageDuration: averageDuration ?? this.averageDuration,
      sets: sets ?? this.sets,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
    );
  }
}

class ExerciseSet {
  final int repetitions;
  final double accuracy;
  final Duration duration;

  ExerciseSet({
    required this.repetitions,
    required this.accuracy,
    required this.duration,
  });
}
