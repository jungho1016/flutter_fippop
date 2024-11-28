import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
  }

  Future<void> showGoalAchievedNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'goal_channel',
      '목표 달성 알림',
      channelDescription: '운동 목표 달성 시 알림을 표시합니다',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      '목표 달성!',
      '오늘의 운동 목표를 달성했습니다! 🎉',
      details,
    );
  }

  Future<void> showWorkoutReminder() async {
    const androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      '운동 알림',
      channelDescription: '운동 시간 알림을 표시합니다',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      1,
      '운동 시간!',
      '오늘의 스쿼트를 시작할 시간입니다! 💪',
      details,
    );
  }

  Future<void> showAccuracyWarning() async {
    const androidDetails = AndroidNotificationDetails(
      'accuracy_channel',
      '자세 교정 알림',
      channelDescription: '운동 자세 교정이 필요할 때 알림을 표시합니다',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      2,
      '자세 교정 필요',
      '정확한 자세로 운동하세요! 🎯',
      details,
    );
  }
}
