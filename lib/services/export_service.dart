import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/workout_session.dart';
import 'database_helper.dart';

class ExportService {
  static final ExportService instance = ExportService._();
  ExportService._();

  Future<void> exportWorkoutData() async {
    try {
      final sessions = await DatabaseHelper.instance.getWorkoutSessions();
      final jsonData = await _createJsonExport(sessions);
      final csvData = await _createCsvExport(sessions);

      // JSON 파일 저장
      final jsonFile = await _saveToFile(jsonData, 'workout_data.json');

      // CSV 파일 저장
      final csvFile = await _saveToFile(csvData, 'workout_data.csv');

      // 파일 공유
      await Share.shareXFiles(
        [XFile(jsonFile.path), XFile(csvFile.path)],
        text: '운동 데이터 내보내기',
      );
    } catch (e) {
      throw Exception('데이터 내보내기 실패: $e');
    }
  }

  Future<String> _createJsonExport(List<WorkoutSession> sessions) async {
    final data = {
      'exportDate': DateTime.now().toIso8601String(),
      'sessions': sessions
          .map((session) => {
                'id': session.id,
                'startTime': session.startTime.toIso8601String(),
                'endTime': session.endTime.toIso8601String(),
                'squatCount': session.squatCount,
                'accuracy': session.accuracy,
                'averageDuration': session.averageDuration,
                'caloriesBurned': session.caloriesBurned,
                'sets': session.sets
                    .map((set) => {
                          'repetitions': set.repetitions,
                          'accuracy': set.accuracy,
                          'duration': set.duration.inMilliseconds,
                          'feedbacks': set.feedbacks,
                        })
                    .toList(),
                'feedbacks': session.feedbacks,
              })
          .toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<String> _createCsvExport(List<WorkoutSession> sessions) async {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    final buffer = StringBuffer();

    // CSV 헤더
    buffer.writeln(
      'ID,시작 시간,종료 시간,스쿼트 횟수,정확도,평균 소요 시간,소모 칼로리,피드백',
    );

    // 데이터 행
    for (var session in sessions) {
      buffer.writeln(
        '${session.id},'
        '${dateFormat.format(session.startTime)},'
        '${dateFormat.format(session.endTime)},'
        '${session.squatCount},'
        '${session.accuracy.toStringAsFixed(1)},'
        '${session.averageDuration.toStringAsFixed(1)},'
        '${session.caloriesBurned.toStringAsFixed(1)},'
        '"${session.feedbacks.join("; ")}"',
      );
    }

    return buffer.toString();
  }

  Future<File> _saveToFile(String data, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    return await file.writeAsString(data);
  }

  Future<Map<String, dynamic>> generateWorkoutSummary(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final sessions = await DatabaseHelper.instance.getWorkoutSessions();
    final filteredSessions = sessions
        .where(
          (session) =>
              session.startTime.isAfter(startDate) &&
              session.startTime.isBefore(endDate),
        )
        .toList();

    int totalSquats = 0;
    double totalCalories = 0;
    double totalAccuracy = 0;
    Duration totalDuration = Duration.zero;

    for (var session in filteredSessions) {
      totalSquats += session.squatCount;
      totalCalories += session.caloriesBurned;
      totalAccuracy += session.accuracy;
      totalDuration += session.duration;
    }

    return {
      'period': {
        'start': startDate.toIso8601String(),
        'end': endDate.toIso8601String(),
      },
      'totalSessions': filteredSessions.length,
      'totalSquats': totalSquats,
      'totalCalories': totalCalories,
      'averageAccuracy': filteredSessions.isEmpty
          ? 0.0
          : totalAccuracy / filteredSessions.length,
      'totalDuration': totalDuration.inMinutes,
      'sessionsPerWeek': filteredSessions.isEmpty
          ? 0.0
          : (filteredSessions.length * 7) /
              endDate.difference(startDate).inDays,
    };
  }
}
