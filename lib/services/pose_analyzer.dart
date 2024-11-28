import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math';
import '../models/squat_phase.dart';

class PoseAnalyzer {
  static final PoseAnalyzer instance = PoseAnalyzer._();
  PoseAnalyzer._();

  static const double _squatAngleThreshold = 130.0; // 스쿼트 자세 판단 각도
  static const double _standingAngleThreshold = 160.0; // 서있는 자세 판단 각도

  SquatPhase analyzeSquatPhase(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final kneeAngle = _calculateKneeAngle(landmarks);

    if (kneeAngle > _standingAngleThreshold) {
      return SquatPhase.standing;
    } else if (kneeAngle < _squatAngleThreshold) {
      return SquatPhase.squatting;
    } else {
      return SquatPhase.rising;
    }
  }

  double calculateAccuracy(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    double accuracy = 100.0;

    // 무릎 정렬 체크
    accuracy -= _checkKneeAlignment(landmarks);

    // 허리 자세 체크
    accuracy -= _checkBackPosture(landmarks);

    // 발목 각도 체크
    accuracy -= _checkAnkleAngle(landmarks);

    return accuracy.clamp(0.0, 100.0);
  }

  double _calculateKneeAngle(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final hip = landmarks[PoseLandmarkType.leftHip]!;
    final knee = landmarks[PoseLandmarkType.leftKnee]!;
    final ankle = landmarks[PoseLandmarkType.leftAnkle]!;

    return _calculateAngle(
      Point(hip.x, hip.y),
      Point(knee.x, knee.y),
      Point(ankle.x, ankle.y),
    );
  }

  double _checkKneeAlignment(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftKnee = landmarks[PoseLandmarkType.leftKnee]!;
    final rightKnee = landmarks[PoseLandmarkType.rightKnee]!;
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle]!;
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle]!;

    // 무릎이 발끝을 넘어가면 감점
    double penalty = 0.0;
    if (leftKnee.x < leftAnkle.x) penalty += 10.0;
    if (rightKnee.x < rightAnkle.x) penalty += 10.0;

    return penalty;
  }

  double _checkBackPosture(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final shoulder = landmarks[PoseLandmarkType.leftShoulder]!;
    final hip = landmarks[PoseLandmarkType.leftHip]!;
    final knee = landmarks[PoseLandmarkType.leftKnee]!;

    final backAngle = _calculateAngle(
      Point(shoulder.x, shoulder.y),
      Point(hip.x, hip.y),
      Point(knee.x, knee.y),
    );

    // 허리가 굽으면 감점
    if (backAngle < 160.0) {
      return (160.0 - backAngle) * 0.5;
    }
    return 0.0;
  }

  double _checkAnkleAngle(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final knee = landmarks[PoseLandmarkType.leftKnee]!;
    final ankle = landmarks[PoseLandmarkType.leftAnkle]!;
    final foot = landmarks[PoseLandmarkType.leftFootIndex]!;

    final ankleAngle = _calculateAngle(
      Point(knee.x, knee.y),
      Point(ankle.x, ankle.y),
      Point(foot.x, foot.y),
    );

    // 발목 각도가 적절하지 않으면 감점
    if (ankleAngle < 70.0 || ankleAngle > 110.0) {
      return 10.0;
    }
    return 0.0;
  }

  double _calculateAngle(Point p1, Point p2, Point p3) {
    final radians =
        atan2(p3.y - p2.y, p3.x - p2.x) - atan2(p1.y - p2.y, p1.x - p2.x);
    var angle = (radians * 180 / pi).abs();

    if (angle > 180) {
      angle = 360 - angle;
    }

    return angle;
  }

  bool isValidSquat(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final kneeAngle = _calculateKneeAngle(landmarks);
    return kneeAngle < _squatAngleThreshold;
  }
}
