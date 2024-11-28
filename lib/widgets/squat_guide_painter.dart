import 'package:flutter/material.dart';

class SquatGuidePainter extends CustomPainter {
  final int phase;
  final Color color;
  final bool showGuideLines;
  final bool showKneeWarning;
  final bool showAngle;
  final bool showArrow;

  SquatGuidePainter({
    required this.phase,
    this.color = Colors.blue,
    this.showGuideLines = false,
    this.showKneeWarning = false,
    this.showAngle = false,
    this.showArrow = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    switch (phase) {
      case 1:
        _drawStandingPose(canvas, size, paint);
        break;
      case 2:
        _drawDescendingPose(canvas, size, paint);
        break;
      case 3:
        _drawSquatPose(canvas, size, paint);
        break;
      case 4:
        _drawAscendingPose(canvas, size, paint);
        break;
    }
  }

  void _drawStandingPose(Canvas canvas, Size size, Paint paint) {
    // 기본 자세 그리기
    // ... 자세한 구현 코드
  }

  void _drawDescendingPose(Canvas canvas, Size size, Paint paint) {
    // 내려가는 자세 그리기
    // ... 자세한 구현 코드
  }

  void _drawSquatPose(Canvas canvas, Size size, Paint paint) {
    // 스쿼트 자세 그리기
    // ... 자세한 구현 코드
  }

  void _drawAscendingPose(Canvas canvas, Size size, Paint paint) {
    // 올라오는 자세 그리기
    // ... 자세한 구현 코드
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
