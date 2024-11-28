class WorkoutException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  WorkoutException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'WorkoutException: $message (Code: $code)';
}

class CameraException implements Exception {
  final String message;
  final String? code;

  CameraException(this.message, {this.code});

  @override
  String toString() => 'CameraException: $message (Code: $code)';
}

class DatabaseException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  DatabaseException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'DatabaseException: $message (Code: $code)';
}
