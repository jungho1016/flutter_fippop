import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_goal.dart';
import 'dart:convert';

class GoalService {
  static final GoalService instance = GoalService._();
  final _prefs = SharedPreferences.getInstance();

  GoalService._();

  Future<WorkoutGoal> getGoal() async {
    final prefs = await _prefs;
    final goalJson = prefs.getString('workout_goal');
    if (goalJson == null) {
      return WorkoutGoal(
        dailySquatTarget: 20,
        weeklySquatTarget: 35,
        workoutDuration: const Duration(minutes: 30),
        accuracyTarget: 80.0,
        minAccuracy: 70.0,
        intensity: 'medium',
      );
    }
    return WorkoutGoal.fromJson(Map<String, dynamic>.from(
        Map.from(const JsonDecoder().convert(goalJson))));
  }

  Future<void> setGoal(WorkoutGoal goal) async {
    final prefs = await _prefs;
    await prefs.setString(
        'workout_goal', const JsonEncoder().convert(goal.toJson()));
  }

  Future<bool> isDailyGoalAchieved() async {
    final prefs = await _prefs;
    final goal = await getGoal();
    final todaySquats = prefs.getInt('today_squats') ?? 0;
    return todaySquats >= goal.dailySquatTarget;
  }

  Future<void> updateDailyProgress(int squatCount) async {
    final prefs = await _prefs;
    final currentCount = prefs.getInt('today_squats') ?? 0;
    await prefs.setInt('today_squats', currentCount + squatCount);
  }

  Future<void> resetDailyProgress() async {
    final prefs = await _prefs;
    await prefs.setInt('today_squats', 0);
  }

  Future<void> saveGoal(WorkoutGoal goal) async {
    // TODO: 실제 저장 로직 구현
    // 예: SharedPreferences나 데이터베이스에 저장
  }
}
