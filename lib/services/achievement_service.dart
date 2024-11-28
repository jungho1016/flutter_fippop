import '../models/achievement_badge.dart';
import '../models/workout_session.dart';
import 'database_helper.dart';
import 'notification_service.dart';

class AchievementService {
  static final AchievementService instance = AchievementService._();
  AchievementService._();

  final _achievements = {
    'first_workout': AchievementBadge(
      id: 'first_workout',
      title: '첫 운동 완료',
      description: '첫 번째 운동을 완료했습니다!',
      iconPath: 'assets/images/badge_first_workout.png',
    ),
    'perfect_form': AchievementBadge(
      id: 'perfect_form',
      title: '완벽한 자세',
      description: '95% 이상의 정확도로 운동을 완료했습니다!',
      iconPath: 'assets/images/badge_perfect_form.png',
    ),
    'consistency_week': AchievementBadge(
      id: 'consistency_week',
      title: '일주일 연속 운동',
      description: '7일 연속으로 운동했습니다!',
      iconPath: 'assets/images/badge_consistency_week.png',
    ),
    'squat_master': AchievementBadge(
      id: 'squat_master',
      title: '스쿼트 마스터',
      description: '총 1000회 스쿼트를 달성했습니다!',
      iconPath: 'assets/images/badge_squat_master.png',
    ),
    'calorie_burn': AchievementBadge(
      id: 'calorie_burn',
      title: '칼로리 버너',
      description: '한 세션에서 300kcal 이상 소모했습니다!',
      iconPath: 'assets/images/badge_calorie_burn.png',
    ),
  };

  Future<void> initializeAchievements() async {
    for (var badge in _achievements.values) {
      try {
        await DatabaseHelper.instance.insertAchievement(badge);
      } catch (e) {
        // 이미 존재하는 업적은 무시
      }
    }
  }

  Future<void> checkAchievements(WorkoutSession session) async {
    final achievements = await DatabaseHelper.instance.getAchievements();
    final unlockedAchievements = <AchievementBadge>[];

    // 첫 운동 체크
    if (!achievements.any((a) => a.id == 'first_workout' && a.isUnlocked)) {
      await _unlockAchievement('first_workout');
      unlockedAchievements.add(_achievements['first_workout']!);
    }

    // 완벽한 자세 체크
    if (session.accuracy >= 95 &&
        !achievements.any((a) => a.id == 'perfect_form' && a.isUnlocked)) {
      await _unlockAchievement('perfect_form');
      unlockedAchievements.add(_achievements['perfect_form']!);
    }

    // 연속 운동 체크
    final sessions = await DatabaseHelper.instance.getWorkoutSessions();
    if (_checkConsecutiveDays(sessions) >= 7 &&
        !achievements.any((a) => a.id == 'consistency_week' && a.isUnlocked)) {
      await _unlockAchievement('consistency_week');
      unlockedAchievements.add(_achievements['consistency_week']!);
    }

    // 총 스쿼트 횟수 체크
    final totalSquats =
        sessions.fold(0, (sum, session) => sum + session.squatCount);
    if (totalSquats >= 1000 &&
        !achievements.any((a) => a.id == 'squat_master' && a.isUnlocked)) {
      await _unlockAchievement('squat_master');
      unlockedAchievements.add(_achievements['squat_master']!);
    }

    // 칼로리 소모 체크
    if (session.caloriesBurned >= 300 &&
        !achievements.any((a) => a.id == 'calorie_burn' && a.isUnlocked)) {
      await _unlockAchievement('calorie_burn');
      unlockedAchievements.add(_achievements['calorie_burn']!);
    }

    // 새로 획득한 업적에 대한 알림 표시
    for (var badge in unlockedAchievements) {
      await NotificationService.instance.showAchievementNotification(
        '🎉 새로운 업적 달성!',
        '${badge.title} - ${badge.description}',
      );
    }
  }

  Future<void> _unlockAchievement(String achievementId) async {
    await DatabaseHelper.instance.unlockAchievement(achievementId);
  }

  int _checkConsecutiveDays(List<WorkoutSession> sessions) {
    if (sessions.isEmpty) return 0;

    sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    int consecutiveDays = 1;
    DateTime lastDate = DateTime(
      sessions[0].startTime.year,
      sessions[0].startTime.month,
      sessions[0].startTime.day,
    );

    for (var i = 1; i < sessions.length; i++) {
      final currentDate = DateTime(
        sessions[i].startTime.year,
        sessions[i].startTime.month,
        sessions[i].startTime.day,
      );

      if (lastDate.difference(currentDate).inDays == 1) {
        consecutiveDays++;
        lastDate = currentDate;
      } else if (lastDate.difference(currentDate).inDays > 1) {
        break;
      }
    }

    return consecutiveDays;
  }

  Future<List<AchievementBadge>> getAchievements() async {
    return await DatabaseHelper.instance.getAchievements();
  }

  Future<List<AchievementBadge>> getUnlockedAchievements() async {
    final achievements = await getAchievements();
    return achievements.where((badge) => badge.isUnlocked).toList();
  }
}
