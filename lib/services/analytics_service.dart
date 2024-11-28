import '../models/workout_session.dart';
import 'database_helper.dart';

class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._();
  AnalyticsService._();

  Future<Map<String, dynamic>> getWeeklyStats() async {
    final sessions = await DatabaseHelper.instance.getWorkoutSessions();
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final weekSessions = sessions
        .where(
          (session) =>
              session.startTime.isAfter(weekStart) &&
              session.startTime.isBefore(weekEnd),
        )
        .toList();

    final dailyStats = List.generate(7, (index) {
      final day = weekStart.add(Duration(days: index));
      final daySessions = weekSessions
          .where(
            (session) =>
                session.startTime.year == day.year &&
                session.startTime.month == day.month &&
                session.startTime.day == day.day,
          )
          .toList();

      return {
        'date': day,
        'squatCount':
            daySessions.fold(0, (sum, session) => sum + session.squatCount),
        'accuracy': daySessions.isEmpty
            ? 0.0
            : daySessions.fold(0.0, (sum, session) => sum + session.accuracy) /
                daySessions.length,
        'calories': daySessions.fold(
            0.0, (sum, session) => sum + session.caloriesBurned),
      };
    });

    return {
      'dailyStats': dailyStats,
      'totalSquats': dailyStats.fold(
          0, (sum, stats) => sum + (stats['squatCount'] as int)),
      'averageAccuracy': dailyStats.fold(
              0.0, (sum, stats) => sum + (stats['accuracy'] as double)) /
          7,
      'totalCalories': dailyStats.fold(
          0.0, (sum, stats) => sum + (stats['calories'] as double)),
    };
  }

  Future<Map<String, dynamic>> getMonthlyStats() async {
    final sessions = await DatabaseHelper.instance.getWorkoutSessions();
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    final monthSessions = sessions
        .where(
          (session) =>
              session.startTime.isAfter(monthStart) &&
              session.startTime.isBefore(monthEnd),
        )
        .toList();

    final weeklyStats = List.generate(
      (monthEnd.difference(monthStart).inDays / 7).ceil(),
      (weekIndex) {
        final weekStart = monthStart.add(Duration(days: weekIndex * 7));
        final weekEnd = weekStart.add(const Duration(days: 7));
        final weekSessions = monthSessions
            .where(
              (session) =>
                  session.startTime.isAfter(weekStart) &&
                  session.startTime.isBefore(weekEnd),
            )
            .toList();

        return {
          'weekStart': weekStart,
          'weekEnd': weekEnd,
          'squatCount':
              weekSessions.fold(0, (sum, session) => sum + session.squatCount),
          'accuracy': weekSessions.isEmpty
              ? 0.0
              : weekSessions.fold(
                      0.0, (sum, session) => sum + session.accuracy) /
                  weekSessions.length,
          'calories': weekSessions.fold(
              0.0, (sum, session) => sum + session.caloriesBurned),
        };
      },
    );

    return {
      'weeklyStats': weeklyStats,
      'totalSquats':
          monthSessions.fold(0, (sum, session) => sum + session.squatCount),
      'averageAccuracy': monthSessions.isEmpty
          ? 0.0
          : monthSessions.fold(0.0, (sum, session) => sum + session.accuracy) /
              monthSessions.length,
      'totalCalories': monthSessions.fold(
          0.0, (sum, session) => sum + session.caloriesBurned),
      'totalWorkouts': monthSessions.length,
    };
  }

  Future<Map<String, dynamic>> getProgressStats() async {
    final sessions = await DatabaseHelper.instance.getWorkoutSessions();
    if (sessions.isEmpty) {
      return {
        'improvement': 0.0,
        'consistencyScore': 0.0,
        'streak': 0,
        'bestAccuracy': 0.0,
        'totalSquats': 0,
      };
    }

    // 정확도 개선도 계산
    final recentSessions = sessions.take(10).toList();
    final oldSessions = sessions.skip(10).take(10).toList();
    final recentAccuracy = recentSessions.isEmpty
        ? 0.0
        : recentSessions.fold(0.0, (sum, s) => sum + s.accuracy) /
            recentSessions.length;
    final oldAccuracy = oldSessions.isEmpty
        ? 0.0
        : oldSessions.fold(0.0, (sum, s) => sum + s.accuracy) /
            oldSessions.length;

    // 연속 운동 일수 계산
    int streak = 0;
    final now = DateTime.now();
    var checkDate = now;
    for (var session in sessions) {
      if (session.startTime.year == checkDate.year &&
          session.startTime.month == checkDate.month &&
          session.startTime.day == checkDate.day) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return {
      'improvement': oldAccuracy == 0.0
          ? 0.0
          : (recentAccuracy - oldAccuracy) / oldAccuracy * 100,
      'consistencyScore': _calculateConsistencyScore(sessions),
      'streak': streak,
      'bestAccuracy':
          sessions.map((s) => s.accuracy).reduce((a, b) => a > b ? a : b),
      'totalSquats':
          sessions.fold(0, (sum, session) => sum + session.squatCount),
    };
  }

  double _calculateConsistencyScore(List<WorkoutSession> sessions) {
    if (sessions.isEmpty) return 0.0;

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final recentSessions = sessions
        .where(
          (session) => session.startTime.isAfter(thirtyDaysAgo),
        )
        .toList();

    // 최근 30일 중 운동한 날의 비율을 계산
    final daysWorkedOut = recentSessions
        .map(
          (s) => '${s.startTime.year}-${s.startTime.month}-${s.startTime.day}',
        )
        .toSet()
        .length;

    return (daysWorkedOut / 30) * 100;
  }
}
