import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/squat_phase.dart';

class PoseOverlayPainter extends CustomPainter {
  final Map<PoseLandmarkType, PoseLandmark> landmarks;
  final SquatPhase phase;

  PoseOverlayPainter({
    required this.landmarks,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    debugPrint('=== PoseOverlayPainter 시작 ===');
    debugPrint('Canvas 크기: ${size.width}x${size.height}');
    debugPrint('랜드마크 수: ${landmarks.length}');

    // 랜드마크 좌표 출력
    landmarks.forEach((type, landmark) {
      debugPrint('$type: (${landmark.x}, ${landmark.y})');
    });

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // 좌표 변환 헬퍼 함수
    Offset getScaledOffset(PoseLandmark landmark) {
      debugPrint('원본 좌표: (${landmark.x}, ${landmark.y})');
      debugPrint('화면 크기: ${size.width}x${size.height}');

      // 원메라 비율과 화면 비율 계산
      const cameraAspectRatio = 1280 / 720;
      final screenAspectRatio = size.width / size.height;

      // 화면에 맞는 스케일 계산 (1.5배 크게)
      double scale;
      double offsetX = 0;
      double offsetY = 0;

      if (screenAspectRatio > cameraAspectRatio) {
        // 화면이 더 넓은 경우
        scale = (size.height / 720) * 1.5; // 1.5배 크게
        offsetX = (size.width - 1280 * scale) / 2;
      } else {
        // 화면이 더 높은 경우
        scale = (size.width / 1280) * 1.5; // 1.5배 크게
        offsetY = (size.height - 720 * scale) / 2;
      }

      // 좌표 변환
      final scaledX = landmark.x * scale + offsetX;
      final scaledY = landmark.y * scale + offsetY;
      debugPrint('스케일링 후: ($scaledX, $scaledY)');

      // 좌우 반전
      final mirroredX = size.width - scaledX;
      debugPrint('반전 후: ($mirroredX, $scaledY)');

      return Offset(mirroredX, scaledY);
    }

    // 좌표 변환 헬스트
    final testLandmark = landmarks[PoseLandmarkType.leftShoulder];
    if (testLandmark != null) {
      final testPoint = getScaledOffset(testLandmark);
      debugPrint('변환된 좌표 테스트 (왼쪽 어깨):');
      debugPrint('원본: (${testLandmark.x}, ${testLandmark.y})');
      debugPrint('변환: (${testPoint.dx}, ${testPoint.dy})');
    }

    // 연결선 그리기 함수도 수정
    void drawConnection(PoseLandmarkType from, PoseLandmarkType to) {
      if (!landmarks.containsKey(from) || !landmarks.containsKey(to)) {
        debugPrint('연결 실패: $from -> $to (랜드마크 없음)');
        return;
      }

      final fromPoint = getScaledOffset(landmarks[from]!);
      final toPoint = getScaledOffset(landmarks[to]!);

      paint.color = _getColorForPhase(phase).withOpacity(0.8);
      canvas.drawLine(fromPoint, toPoint, paint);

      // 디버그용 점 그리기 (크기 조정)
      final debugPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;
      canvas.drawCircle(fromPoint, 8, debugPaint); // 점 크기 증가
      canvas.drawCircle(toPoint, 8, debugPaint); // 점 크기 증가
    }

    // 연결선 그리기
    drawConnection(
        PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    drawConnection(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
    drawConnection(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
    drawConnection(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
    drawConnection(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);

    // 몸통 연결
    drawConnection(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
    drawConnection(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);
    drawConnection(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);

    // 다리 연결
    drawConnection(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
    drawConnection(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
    drawConnection(PoseLandmarkType.leftAnkle, PoseLandmarkType.leftFootIndex);
    drawConnection(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
    drawConnection(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);
    drawConnection(
        PoseLandmarkType.rightAnkle, PoseLandmarkType.rightFootIndex);

    // 관절 포인트 그리기
    paint
      ..style = PaintingStyle.fill
      ..color = _getColorForPhase(phase);

    // 주요 관절만 포인트 표시
    final mainJoints = [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    ];

    for (final jointType in mainJoints) {
      if (landmarks.containsKey(jointType)) {
        final point = getScaledOffset(landmarks[jointType]!);
        canvas.drawCircle(point, 6, paint);
      }
    }

    debugPrint('=== PoseOverlayPainter 완료 ===\n');
  }

  @override
  bool shouldRepaint(covariant PoseOverlayPainter oldDelegate) {
    return oldDelegate.landmarks != landmarks || oldDelegate.phase != phase;
  }

  Color _getColorForPhase(SquatPhase phase) {
    switch (phase) {
      case SquatPhase.standing:
        return Colors.green;
      case SquatPhase.squatting:
        return Colors.blue;
      case SquatPhase.rising:
        return Colors.orange;
    }
  }
}
