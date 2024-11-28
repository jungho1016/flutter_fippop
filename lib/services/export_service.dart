import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/workout_session.dart';
import 'database_helper.dart';

class ExportService {
  static final ExportService instance = ExportService._internal();
  ExportService._internal();

  Future<String> exportWorkoutData() async {
    try {
      // 모든 운동 세션 가져오기
      final sessions = await DatabaseHelper.instance.getAllWorkoutSessions();

      // JSON 형식으로 변환
      final jsonData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'sessions': sessions.map((session) => session.toMap()).toList(),
      };

      // 파일로 저장
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/workout_data.json');
      await file.writeAsString(jsonEncode(jsonData));

      // 파일 공유
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '운동 기록 데이터',
      );

      return file.path;
    } catch (e) {
      throw Exception('데이터 내보내기 실패: $e');
    }
  }

  Future<void> importWorkoutData(String jsonString) async {
    try {
      final data = jsonDecode(jsonString);

      // 버전 확인
      if (data['version'] != '1.0') {
        throw Exception('지원하지 않는 데이터 형식입니다.');
      }

      // 기존 데이터 삭제
      await DatabaseHelper.instance.deleteAllWorkoutSessions();

      // 새 데이터 추가
      final sessions = (data['sessions'] as List)
          .map((json) => WorkoutSession.fromMap(json))
          .toList();

      for (var session in sessions) {
        await DatabaseHelper.instance.insertWorkoutSession(session);
      }
    } catch (e) {
      throw Exception('데이터 가져오기 실패: $e');
    }
  }

  Future<Map<String, dynamic>> generateWorkoutSummary() async {
    final sessions = await DatabaseHelper.instance.getAllWorkoutSessions();

    if (sessions.isEmpty) {
      return {
        'totalSessions': 0,
        'totalSquats': 0,
        'averageAccuracy': 0.0,
        'totalDuration': Duration.zero,
      };
    }

    final totalSquats =
        sessions.fold<int>(0, (sum, session) => sum + session.squatCount);

    final averageAccuracy =
        sessions.fold<double>(0.0, (sum, session) => sum + session.accuracy) /
            sessions.length;

    final totalDuration = sessions.fold<Duration>(
      Duration.zero,
      (sum, session) => sum + session.endTime.difference(session.startTime),
    );

    return {
      'totalSessions': sessions.length,
      'totalSquats': totalSquats,
      'averageAccuracy': averageAccuracy,
      'totalDuration': totalDuration,
    };
  }
}
