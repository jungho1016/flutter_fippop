import 'package:flutter/foundation.dart';
import '../models/squat_phase.dart';

class SquatCounter extends ChangeNotifier {
  int _count = 0;
  double _accuracy = 0.0;
  SquatPhase _lastPhase = SquatPhase.standing;
  bool _isInProgress = false;
  DateTime? _lastUpdateTime;
  int _squattingFrameCount = 0;
  DateTime? _startTime;
  static const int _requiredSquattingFrames = 5;

  int get count => _count;
  double get accuracy => _accuracy;
  int get duration =>
      _startTime == null ? 0 : DateTime.now().difference(_startTime!).inSeconds;

  void start() {
    _startTime = DateTime.now();
    notifyListeners();
  }

  void updatePhase(SquatPhase currentPhase) {
    if (_count == 0 &&
        currentPhase == SquatPhase.squatting &&
        _startTime == null) {
      start();
    }

    final now = DateTime.now();
    if (_lastUpdateTime != null &&
        now.difference(_lastUpdateTime!).inMilliseconds < 100) {
      return;
    }
    _lastUpdateTime = now;

    switch (currentPhase) {
      case SquatPhase.standing:
        if (_isInProgress && _lastPhase == SquatPhase.rising) {
          _count++;
          _isInProgress = false;
          _squattingFrameCount = 0;
          notifyListeners();
        }
        break;

      case SquatPhase.squatting:
        _squattingFrameCount++;
        if (_squattingFrameCount >= _requiredSquattingFrames &&
            !_isInProgress &&
            _lastPhase == SquatPhase.standing) {
          _isInProgress = true;
        }
        break;

      case SquatPhase.rising:
        if (_isInProgress && _lastPhase == SquatPhase.squatting) {
          // rising 상태 확인
        }
        break;
    }

    _lastPhase = currentPhase;
  }

  void reset() {
    _count = 0;
    _lastPhase = SquatPhase.standing;
    _isInProgress = false;
    _lastUpdateTime = null;
    _squattingFrameCount = 0;
    _startTime = null;
    notifyListeners();
  }

  void incrementCount() {
    _count++;
    notifyListeners();
  }

  void updateAccuracy(double newAccuracy) {
    _accuracy = newAccuracy;
    notifyListeners();
  }
}
