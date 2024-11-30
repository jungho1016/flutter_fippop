import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/squat_phase.dart';
import '../models/pose_error.dart';

class PoseGuide extends StatelessWidget {
  final List<Pose>? poses;
  final SquatPhase phase;
  final PoseError error;

  const PoseGuide({
    super.key,
    required this.poses,
    required this.phase,
    required this.error,
  });

  String _getGuideMessage() {
    if (error != PoseError.none) {
      switch (error) {
        case PoseError.kneeOverToes:
          return '무릎이 발끝을 넘어갔습니다';
        case PoseError.backNotStraight:
          return '등을 똑바로 펴주세요';
        case PoseError.squatTooShallow:
          return '더 깊게 앉아주세요';
        case PoseError.none:
          break;
      }
    }

    return _getPhaseGuideMessage();
  }

  String _getPhaseGuideMessage() {
    if (poses == null || poses!.isEmpty) {
      return '화면에 전신이 보이도록 서주세요';
    }

    switch (phase) {
      case SquatPhase.standing:
        return '무릎을 굽혀 천천히 앉아주세요';
      case SquatPhase.squatting:
        return '무릎이 발끝을 넘어가지 않도록 주의하세요';
      case SquatPhase.rising:
        return '천천히 일어나주세요';
    }
  }

  Color _getGuideColor() {
    if (poses == null || poses!.isEmpty) {
      return Colors.grey;
    }

    switch (phase) {
      case SquatPhase.standing:
        return Colors.green;
      case SquatPhase.squatting:
        return Colors.blue;
      case SquatPhase.rising:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: _getGuideColor().withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _getGuideMessage(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
