import 'package:share_plus/share_plus.dart';
import '../models/workout_session.dart';

class ShareService {
  static Future<void> shareWorkoutResults(WorkoutSession session) async {
    final String shareText = '''
🏋️‍♂️ 오늘의 운동 결과
날짜: ${session.startTime.toString().split(' ')[0]}
스쿼트 개수: ${session.squatCount}회
정확도: ${session.accuracy.toStringAsFixed(1)}%
소요 시간: ${session.averageDuration.toStringAsFixed(1)}초
소모 칼로리: ${session.caloriesBurned.toStringAsFixed(1)}kcal
    ''';

    await Share.share(shareText);
  }

  static Future<void> shareAchievement(String badgeTitle) async {
    final String shareText = '🎉 새로운 뱃지를 획득했습니다: $badgeTitle';
    await Share.share(shareText);
  }
}
