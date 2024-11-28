import 'package:flutter/material.dart';
import '../utils/exceptions.dart';

class ErrorHandler {
  static final ErrorHandler instance = ErrorHandler._init();
  ErrorHandler._init();

  void handleError(BuildContext context, dynamic error) {
    String message = '오류가 발생했습니다.';

    if (error is WorkoutException) {
      message = error.message;
    } else if (error is CameraException) {
      message = '카메라 오류: ${error.message}';
    } else if (error is DatabaseException) {
      message = '데이터베이스 오류: ${error.message}';
    }

    showErrorDialog(context, message);
    logError(error);
  }

  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void logError(dynamic error) {
    // TODO: 에러 로깅 구현
    print('Error logged: $error');
  }

  Future<T> wrapError<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      if (e is WorkoutException ||
          e is CameraException ||
          e is DatabaseException) {
        rethrow;
      }
      throw WorkoutException('예상치 못한 오류가 발생했습니다.', originalError: e);
    }
  }
}
