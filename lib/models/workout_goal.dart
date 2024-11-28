class WorkoutGoal {
  final int dailySquatTarget;
  final int weeklySquatTarget;
  final double minAccuracy;
  final ExerciseIntensity intensity;

  WorkoutGoal({
    required this.dailySquatTarget,
    required this.weeklySquatTarget,
    required this.minAccuracy,
    required this.intensity,
  });

  Map<String, dynamic> toMap() {
    return {
      'dailySquatTarget': dailySquatTarget,
      'weeklySquatTarget': weeklySquatTarget,
      'minAccuracy': minAccuracy,
      'intensity': intensity.index,
    };
  }

  factory WorkoutGoal.fromMap(Map<String, dynamic> map) {
    return WorkoutGoal(
      dailySquatTarget: map['dailySquatTarget'],
      weeklySquatTarget: map['weeklySquatTarget'],
      minAccuracy: map['minAccuracy'],
      intensity: ExerciseIntensity.values[map['intensity']],
    );
  }

  factory WorkoutGoal.defaultGoal() {
    return WorkoutGoal(
      dailySquatTarget: 50,
      weeklySquatTarget: 300,
      minAccuracy: 70.0,
      intensity: ExerciseIntensity.medium,
    );
  }
}

enum ExerciseIntensity {
  easy,
  medium,
  hard,
}
