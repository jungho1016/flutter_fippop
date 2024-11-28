import '../models/workout_session.dart';

class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._internal();
  AnalyticsService._internal();

  // 일일 통계 계산
  Map<String, dynamic> calculateDailyStats(List<WorkoutSession> sessions) {
    if (sessions.isEmpty) {
      return {
        'totalSquats': 0,
        'averageAccuracy': 0.0,
        'totalDuration': Duration.zero,
        'sessionsCount': 0,
      };
    }

    final totalSquats =
        sessions.fold<int>(0, (sum, session) => sum + session.squatCount);
    final averageAccuracy =
        sessions.fold<double>(0, (sum, session) => sum + session.accuracy) /
            sessions.length;
    final totalDuration = sessions.fold<Duration>(
      Duration.zero,
      (sum, session) => sum + session.endTime.difference(session.startTime),
    );

    return {
      'totalSquats': totalSquats,
      'averageAccuracy': averageAccuracy,
      'totalDuration': totalDuration,
      'sessionsCount': sessions.length,
    };
  }

  // 운동 강도 분석
  String analyzeWorkoutIntensity(WorkoutSession session) {
    final duration = session.endTime.difference(session.startTime);
    final squatsPerMinute = session.squatCount / duration.inMinutes;

    if (squatsPerMinute > 20) return '고강도';
    if (squatsPerMinute > 10) return '중강도';
    return '저강도';
  }

  // 진행 상황 분석
  double calculateProgress(List<WorkoutSession> sessions, int targetSquats) {
    if (sessions.isEmpty) return 0.0;
    final totalSquats =
        sessions.fold<int>(0, (sum, session) => sum + session.squatCount);
    return totalSquats / targetSquats;
  }

  // 정확도 추세 분석
  List<double> getAccuracyTrend(List<WorkoutSession> sessions) {
    return sessions.map((session) => session.accuracy).toList();
  }
}
