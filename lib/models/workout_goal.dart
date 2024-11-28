import 'exercise_intensity.dart';

class WorkoutGoal {
  final int dailySquatTarget;
  final int weeklySquatTarget;
  final Duration workoutDuration;
  final double accuracyTarget;
  final double minAccuracy;
  final ExerciseIntensity intensity;

  WorkoutGoal({
    required this.dailySquatTarget,
    required this.weeklySquatTarget,
    required this.workoutDuration,
    required this.accuracyTarget,
    required this.minAccuracy,
    required this.intensity,
  });

  Map<String, dynamic> toJson() {
    return {
      'dailySquatTarget': dailySquatTarget,
      'weeklySquatTarget': weeklySquatTarget,
      'workoutDuration': workoutDuration.inMinutes,
      'accuracyTarget': accuracyTarget,
      'minAccuracy': minAccuracy,
      'intensity': intensity.toString(),
    };
  }

  factory WorkoutGoal.fromJson(Map<String, dynamic> json) {
    return WorkoutGoal(
      dailySquatTarget: json['dailySquatTarget'],
      weeklySquatTarget: json['weeklySquatTarget'],
      workoutDuration: Duration(minutes: json['workoutDuration']),
      accuracyTarget: json['accuracyTarget'],
      minAccuracy: json['minAccuracy'],
      intensity: ExerciseIntensity.values.firstWhere(
        (e) => e.toString() == json['intensity'],
        orElse: () => ExerciseIntensity.medium,
      ),
    );
  }

  WorkoutGoal copyWith({
    int? dailySquatTarget,
    int? weeklySquatTarget,
    Duration? workoutDuration,
    double? accuracyTarget,
    double? minAccuracy,
    ExerciseIntensity? intensity,
  }) {
    return WorkoutGoal(
      dailySquatTarget: dailySquatTarget ?? this.dailySquatTarget,
      weeklySquatTarget: weeklySquatTarget ?? this.weeklySquatTarget,
      workoutDuration: workoutDuration ?? this.workoutDuration,
      accuracyTarget: accuracyTarget ?? this.accuracyTarget,
      minAccuracy: minAccuracy ?? this.minAccuracy,
      intensity: intensity ?? this.intensity,
    );
  }

  @override
  String toString() {
    return 'WorkoutGoal(dailySquatTarget: $dailySquatTarget, weeklySquatTarget: $weeklySquatTarget, workoutDuration: $workoutDuration, accuracyTarget: $accuracyTarget, minAccuracy: $minAccuracy, intensity: $intensity)';
  }
}
