import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/squat_phase.dart';
import 'package:flutter/foundation.dart';
import '../models/pose_error.dart';

class PoseAnalyzer {
  // 각도 임계값
  static const double _kneeAngleThreshold = 110.0; // 무릎 각도
  static const double _hipAngleThreshold = 100.0; // 엉덩이 각도

  static SquatPhase analyzeSquat(
      Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final kneeAngle = _calculateKneeAngle(landmarks);
    final hipAngle = _calculateHipAngle(landmarks);

    if (kneeAngle == null || hipAngle == null) return SquatPhase.standing;

    debugPrint('무릎 각도: $kneeAngle, 엉덩이 각도: $hipAngle'); // 디버그용

    // 스쿼트 단계 판단 로직 개선
    if (kneeAngle > 150 && hipAngle > 150) {
      return SquatPhase.standing; // 완전히 선 자세
    } else if (kneeAngle < _kneeAngleThreshold &&
        hipAngle < _hipAngleThreshold) {
      return SquatPhase.squatting; // 스쿼트 자세
    } else if (kneeAngle > _kneeAngleThreshold && kneeAngle < 150) {
      return SquatPhase.rising; // 일어나는 중
    } else {
      return SquatPhase.standing; // 기본값
    }
  }

  static double? _calculateKneeAngle(
      Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final hip = landmarks[PoseLandmarkType.rightHip];
    final knee = landmarks[PoseLandmarkType.rightKnee];
    final ankle = landmarks[PoseLandmarkType.rightAnkle];

    if (hip == null || knee == null || ankle == null) return null;

    return _calculateAngle(
      hip.x,
      hip.y,
      knee.x,
      knee.y,
      ankle.x,
      ankle.y,
    );
  }

  static double? _calculateHipAngle(
      Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final shoulder = landmarks[PoseLandmarkType.rightShoulder];
    final hip = landmarks[PoseLandmarkType.rightHip];
    final knee = landmarks[PoseLandmarkType.rightKnee];

    if (shoulder == null || hip == null || knee == null) return null;

    return _calculateAngle(
      shoulder.x,
      shoulder.y,
      hip.x,
      hip.y,
      knee.x,
      knee.y,
    );
  }

  static double _calculateAngle(
    double p1x,
    double p1y,
    double p2x,
    double p2y,
    double p3x,
    double p3y,
  ) {
    final radians = atan2(p3y - p2y, p3x - p2x) - atan2(p1y - p2y, p1x - p2x);
    var angle = radians * 180 / pi;

    if (angle < 0) {
      angle += 360;
    }

    return angle > 180 ? 360 - angle : angle;
  }

  static PoseError analyzePoseError(
      Map<PoseLandmarkType, PoseLandmark> landmarks) {
    if (_isKneeOverToes(landmarks)) {
      return PoseError.kneeOverToes;
    }
    if (_isBackNotStraight(landmarks)) {
      return PoseError.backNotStraight;
    }
    if (_isSquatTooShallow(landmarks)) {
      return PoseError.squatTooShallow;
    }
    return PoseError.none;
  }

  static bool _isKneeOverToes(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final knee = landmarks[PoseLandmarkType.rightKnee];
    final ankle = landmarks[PoseLandmarkType.rightAnkle];

    if (knee == null || ankle == null) return false;

    // 무릎이 발목보다 앞으로 나가면 true
    return knee.x > ankle.x + 0.1; // 10% 이상 차이나면 경고
  }

  static bool _isBackNotStraight(
      Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final shoulder = landmarks[PoseLandmarkType.rightShoulder];
    final hip = landmarks[PoseLandmarkType.rightHip];
    final ankle = landmarks[PoseLandmarkType.rightAnkle];

    if (shoulder == null || hip == null || ankle == null) return false;

    // 어깨-엉덩이-발목이 일직선이 아니면 true
    final angle =
        _calculateAngle(shoulder.x, shoulder.y, hip.x, hip.y, ankle.x, ankle.y);
    return angle < 160 || angle > 200; // 20도 이상 기울어지면 경고
  }

  static bool _isSquatTooShallow(
      Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final hip = landmarks[PoseLandmarkType.rightHip];
    final knee = landmarks[PoseLandmarkType.rightKnee];
    final ankle = landmarks[PoseLandmarkType.rightAnkle];

    if (hip == null || knee == null || ankle == null) return false;

    // 엉덩이와 무릎의 거리가 일정 범위를 넘어가면 true
    final distanceHipKnee =
        sqrt(pow(hip.x - knee.x, 2) + pow(hip.y - knee.y, 2));
    final distanceHipAnkle =
        sqrt(pow(hip.x - ankle.x, 2) + pow(hip.y - ankle.y, 2));
    return distanceHipKnee > 0.5 * distanceHipAnkle; // 50% 이상 차이나면 경고
  }
}

class Point {
  final double x;
  final double y;

  Point(this.x, this.y);
}
