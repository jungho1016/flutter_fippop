import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/workout_session.dart';
import 'database_helper.dart';

class ExportService {
  static final ExportService instance = ExportService._init();
  ExportService._init();

  Future<void> exportWorkoutHistory() async {
    try {
      final sessions = await DatabaseHelper.instance.getAllWorkoutSessions();
      final csvData = _convertToCSV(sessions);
      final file = await _saveToFile(csvData);
      await Share.shareXFiles([XFile(file.path)], subject: '운동 기록 내보내기');
    } catch (e) {
      throw Exception('운동 기록 내보내기 실패: $e');
    }
  }

  String _convertToCSV(List<WorkoutSession> sessions) {
    final buffer = StringBuffer();
    // CSV 헤더 추가
    buffer.writeln('날짜,시작 시간,종료 시간,스쿼트 횟수,정확도,평균 시간(초),소모 칼로리');

    for (var session in sessions) {
      buffer.writeln('${session.startTime.toLocal().toString().split(' ')[0]},'
          '${session.startTime.toLocal().toString().split(' ')[1]},'
          '${session.endTime.toLocal().toString().split(' ')[1]},'
          '${session.squatCount},'
          '${session.accuracy.toStringAsFixed(1)},'
          '${session.averageDuration.toStringAsFixed(1)},'
          '${session.caloriesBurned.toStringAsFixed(1)}');
    }

    return buffer.toString();
  }

  Future<File> _saveToFile(String data) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/workout_history.csv');
    return await file.writeAsString(data);
  }
}
