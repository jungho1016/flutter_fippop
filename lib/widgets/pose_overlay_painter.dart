import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../screens/camera_screen.dart';
import '../models/squat_phase.dart';

class PoseOverlayPainter extends CustomPainter {
  final Map<PoseLandmarkType, PoseLandmark>? landmarks;
  final SquatPhase phase;

  PoseOverlayPainter({
    required this.landmarks,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks == null) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = _getColorForPhase(phase);

    _drawSkeleton(canvas, size, paint);
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

  void _drawSkeleton(Canvas canvas, Size size, Paint paint) {
    // 주요 관절 연결
    _drawLine(canvas, size, landmarks![PoseLandmarkType.leftShoulder]!,
        landmarks![PoseLandmarkType.leftElbow]!, paint);
    _drawLine(canvas, size, landmarks![PoseLandmarkType.leftElbow]!,
        landmarks![PoseLandmarkType.leftWrist]!, paint);
    // ... 필요한 다른 관절 연결 추가
  }

  void _drawLine(Canvas canvas, Size size, PoseLandmark start, PoseLandmark end,
      Paint paint) {
    canvas.drawLine(
      Offset(start.x * size.width, start.y * size.height),
      Offset(end.x * size.width, end.y * size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(PoseOverlayPainter oldDelegate) =>
      landmarks != oldDelegate.landmarks || phase != oldDelegate.phase;
}
