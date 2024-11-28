class WorkoutGoal {
  final int dailySquatTarget;
  final int weeklySquatTarget;
  final Duration workoutDuration;
  final double accuracyTarget;
  final double minAccuracy;
  final String intensity;

  WorkoutGoal({
    required this.dailySquatTarget,
    required this.weeklySquatTarget,
    required this.workoutDuration,
    required this.accuracyTarget,
    required this.minAccuracy,
    required this.intensity,
  });

  Map<String, dynamic> toMap() {
    return {
      'dailySquatTarget': dailySquatTarget,
      'weeklySquatTarget': weeklySquatTarget,
      'workoutDuration': workoutDuration.inSeconds,
      'accuracyTarget': accuracyTarget,
      'minAccuracy': minAccuracy,
      'intensity': intensity,
    };
  }

  factory WorkoutGoal.fromMap(Map<String, dynamic> map) {
    return WorkoutGoal(
      dailySquatTarget: map['dailySquatTarget'],
      weeklySquatTarget: map['weeklySquatTarget'],
      workoutDuration: Duration(seconds: map['workoutDuration']),
      accuracyTarget: map['accuracyTarget'],
      minAccuracy: map['minAccuracy'],
      intensity: map['intensity'],
    );
  }

  factory WorkoutGoal.defaultGoal() {
    return WorkoutGoal(
      dailySquatTarget: 50,
      weeklySquatTarget: 300,
      workoutDuration: const Duration(hours: 1),
      accuracyTarget: 80.0,
      minAccuracy: 70.0,
      intensity: 'medium',
    );
  }

  factory WorkoutGoal.fromJson(Map<String, dynamic> json) {
    return WorkoutGoal(
      dailySquatTarget: json['dailySquatTarget'],
      weeklySquatTarget: json['weeklySquatTarget'],
      workoutDuration: Duration(minutes: json['workoutDurationMinutes']),
      accuracyTarget: json['accuracyTarget'],
      minAccuracy: json['minAccuracy'],
      intensity: json['intensity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailySquatTarget': dailySquatTarget,
      'weeklySquatTarget': weeklySquatTarget,
      'workoutDurationMinutes': workoutDuration.inMinutes,
      'accuracyTarget': accuracyTarget,
      'minAccuracy': minAccuracy,
      'intensity': intensity,
    };
  }
}

enum ExerciseIntensity {
  easy,
  medium,
  hard,
}
