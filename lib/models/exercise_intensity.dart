enum ExerciseIntensity { low, medium, high }

extension ExerciseIntensityExtension on ExerciseIntensity {
  String get displayName {
    switch (this) {
      case ExerciseIntensity.low:
        return '낮음';
      case ExerciseIntensity.medium:
        return '중간';
      case ExerciseIntensity.high:
        return '높음';
    }
  }
}
