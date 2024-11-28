class WorkoutSession {
  final int? id;
  final DateTime startTime;
  final DateTime endTime;
  final int squatCount;
  final double accuracy;
  final double averageDuration;
  final double caloriesBurned;
  final List<ExerciseSet> sets;
  final List<String> feedbacks;

  WorkoutSession({
    this.id,
    required this.startTime,
    required this.endTime,
    required this.squatCount,
    required this.accuracy,
    required this.averageDuration,
    required this.caloriesBurned,
    required this.sets,
    this.feedbacks = const [],
  });

  Duration get duration => endTime.difference(startTime);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'squatCount': squatCount,
      'accuracy': accuracy,
      'averageDuration': averageDuration,
      'caloriesBurned': caloriesBurned,
      'feedbacks': feedbacks.join('|'),
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
      sets: [], // 세트 정보는 별도로 로드
      feedbacks: map['feedbacks']?.split('|') ?? [],
    );
  }

  WorkoutSession copyWith({
    int? id,
    DateTime? startTime,
    DateTime? endTime,
    int? squatCount,
    double? accuracy,
    double? averageDuration,
    double? caloriesBurned,
    List<ExerciseSet>? sets,
    List<String>? feedbacks,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      squatCount: squatCount ?? this.squatCount,
      accuracy: accuracy ?? this.accuracy,
      averageDuration: averageDuration ?? this.averageDuration,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      sets: sets ?? this.sets,
      feedbacks: feedbacks ?? this.feedbacks,
    );
  }
}

class ExerciseSet {
  final int repetitions;
  final double accuracy;
  final Duration duration;
  final List<String> feedbacks;

  ExerciseSet({
    required this.repetitions,
    required this.accuracy,
    required this.duration,
    this.feedbacks = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'repetitions': repetitions,
      'accuracy': accuracy,
      'duration': duration.inMilliseconds,
      'feedbacks': feedbacks.join('|'),
    };
  }

  factory ExerciseSet.fromMap(Map<String, dynamic> map) {
    return ExerciseSet(
      repetitions: map['repetitions'],
      accuracy: map['accuracy'],
      duration: Duration(milliseconds: map['duration']),
      feedbacks: map['feedbacks']?.split('|') ?? [],
    );
  }
}
