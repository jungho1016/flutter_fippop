import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camera/camera.dart';
import 'package:flutter_fippop/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // 테스트용 카메라 목록 생성
    final List<CameraDescription> cameras = [];

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(cameras: cameras));

    // Verify that our counter starts at 0.
    expect(find.text('Pose Detection'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // 카메라 초기화 실패 시나리오 테스트
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  test('SquatAnalyzer angle calculation test', () {
    final pointA = [0.0, 0.0];
    final pointB = [1.0, 0.0];
    final pointC = [2.0, 0.0];

    final angle = SquatAnalyzer.computeAngle(pointA, pointB, pointC);
    expect(angle, 180.0);
  });

  test('SquatAnalyzer phase detection test', () {
    final validKeypoints = {
      'left_hip': {'x': 0.0, 'y': 0.0, 'confidence': 0.9},
      'left_knee': {'x': 0.0, 'y': 1.0, 'confidence': 0.9},
      'left_ankle': {'x': 0.0, 'y': 2.0, 'confidence': 0.9},
    };

    final phase = SquatAnalyzer.validateSquat(validKeypoints);
    expect(phase, isNotNull);
  });
}
