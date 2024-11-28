import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/achievement_service.dart';
import '../services/database_helper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isInitialized = false;
  String _statusMessage = '앱을 초기화하는 중...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 알림 서비스 초기화
      setState(() => _statusMessage = '알림 서비스 초기화 중...');
      await NotificationService.instance.initialize();
      await NotificationService.instance.requestPermissions();

      // 데이터베이스 초기화
      setState(() => _statusMessage = '데이터베이스 초기화 중...');
      await DatabaseHelper.instance.database;

      // 업적 시스템 초기화
      setState(() => _statusMessage = '업적 시스템 초기화 중...');
      await AchievementService.instance.initializeAchievements();

      setState(() => _isInitialized = true);

      // 메인 화면으로 이동
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      setState(() {
        _statusMessage = '초기화 중 오류가 발생했습니다.\n다시 시도해주세요.';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: $e'),
            action: SnackBarAction(
              label: '재시도',
              onPressed: _initializeApp,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 앱 로고
              Image.asset(
                'assets/images/splash_image.png',
                width: 150,
                height: 150,
              ),
              const SizedBox(height: 32),

              // 앱 이름
              const Text(
                'AI 스쿼트 트레이너',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // 로딩 인디케이터
              if (!_isInitialized) ...[
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  _statusMessage,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
