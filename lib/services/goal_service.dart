import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_goal.dart';
import 'dart:convert';

class GoalService {
  static const String _goalKey = 'workout_goal';
  static final GoalService instance = GoalService._internal();

  GoalService._internal();

  Future<void> saveGoal(WorkoutGoal goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_goalKey, jsonEncode(goal.toMap()));
  }

  Future<WorkoutGoal> getGoal() async {
    final prefs = await SharedPreferences.getInstance();
    final goalString = prefs.getString(_goalKey);
    if (goalString == null) {
      return WorkoutGoal.defaultGoal();
    }
    return WorkoutGoal.fromMap(jsonDecode(goalString));
  }

  Future<bool> isDailyGoalAchieved(int todaySquats) async {
    final goal = await getGoal();
    return todaySquats >= goal.dailySquatTarget;
  }

  Future<double> getDailyProgress(int todaySquats) async {
    final goal = await getGoal();
    return todaySquats / goal.dailySquatTarget;
  }
}
