import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/squat_phase.dart';
import 'pose_overlay_painter.dart';

class PoseSkeletonWidget extends StatelessWidget {
  final Map<PoseLandmarkType, PoseLandmark> landmarks;
  final SquatPhase phase;

  const PoseSkeletonWidget({
    super.key,
    required this.landmarks,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: PoseOverlayPainter(
            landmarks: landmarks,
            phase: phase,
          ),
        );
      },
    );
  }
}
