import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:async';
import 'dart:math' show pi, acos, sqrt, pow;
import 'package:vibration/vibration.dart';
import 'screens/settings_screen.dart';
import 'services/notification_service.dart';
import 'services/goal_service.dart';
import 'services/error_handler.dart' as app_error;

// main 함수 수정
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      primarySwatch: Colors.blue,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    ),
    home: SplashScreen(cameras: cameras),
  ));
}

// MyApp 클래스 수정
class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '운동 트래커',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: PoseRecognitionApp(title: 'AI 스쿼트 트레이너', cameras: cameras),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class PoseRecognitionApp extends StatefulWidget {
  const PoseRecognitionApp({
    super.key,
    required this.title,
    required this.cameras,
  });

  final String title;
  final List<CameraDescription> cameras;

  @override
  _PoseRecognitionAppState createState() => _PoseRecognitionAppState();
}

class _PoseRecognitionAppState extends State<PoseRecognitionApp> {
  bool isDetecting = false;
  CameraController? cameraController;
  PoseDetector? _poseDetector;
  List<Pose>? poses;
  Map<PoseLandmarkType, PoseLandmark>? currentPose;

  // 현재 스쿼트 단계를 저장할 변수 추가
  SquatPhase currentPhase = SquatPhase.standing;
  int squatCount = 0;
  bool _processingImage = false; // 이미지 처리 중복 방지를 위한 플래그 추가

  // 포즈 스무딩을 위한 변수들
  final List<Map<PoseLandmarkType, PoseLandmark>> _poseHistory = [];
  static const int _historyLength = 5; // 스무딩에 사용할 프레임 수

  // 자세 분석을 위한 변수들
  double _lastKneeAngle = 0.0;
  DateTime _lastPhaseChange = DateTime.now();
  static const Duration _minPhaseDuration = Duration(milliseconds: 500);

  // 운동 통계를 위한 변수들
  DateTime? sessionStartTime;
  int totalSquats = 0;
  List<Duration> squatDurations = [];
  double accuracyScore = 0.0;

  // 타이머 관련 변수
  Timer? _exerciseTimer;
  int _exerciseSeconds = 0;

  // 운동 설정 변수
  final int _targetSquats = 20; // 목표 스쿼트 횟수
  final ExerciseIntensity _intensity = ExerciseIntensity.medium; // 운동 강도

  // 운동 강도에 따른 각도 임계값
  Map<ExerciseIntensity, double> get _squatDepthThresholds => {
        ExerciseIntensity.easy: 100.0, // 쉬움: 얕은 스쿼트
        ExerciseIntensity.medium: 90.0, // 보통: 일반적인 스쿼트
        ExerciseIntensity.hard: 80.0, // 어려움: 깊은 스쿼트
      };

  final bool _isSpeaking = false;

  // 프레임 처리 최적화
  bool _processingFrame = false;

  Future<void> _processFrame(CameraImage image) async {
    if (_processingFrame) return;
    _processingFrame = true;

    try {
      await app_error.ErrorHandler.instance.wrapError(() async {
        final inputImage = InputImage.fromBytes(
          bytes: image.planes[0].bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: InputImageRotation.rotation90deg,
            format: InputImageFormat.bgra8888,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );

        final poses = await _poseDetector?.processImage(inputImage);

        if (poses != null && poses.isNotEmpty && mounted) {
          setState(() {
            currentPose = poses.first.landmarks;
            _updatePoseAnalysis();
          });
        }
      });
    } catch (e) {
      app_error.ErrorHandler.instance.handleError(context, e);
    } finally {
      _processingFrame = false;
    }
  }

  void _updatePoseAnalysis() async {
    if (currentPose == null) return;

    final newPhase = _analyzePose(currentPose!);
    if (mounted) {
      setState(() {
        currentPhase = newPhase;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializePoseDetector();
    _startExerciseTimer();
    NotificationService.instance.initialize();
  }

  Future<void> _initializeCamera() async {
    try {
      if (widget.cameras.isEmpty) {
        throw CameraException('NO_CAMERA', '사용 가능한 카메라가 없습니다.');
      }

      final backCamera = widget.cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => widget.cameras.first,
      );

      cameraController = CameraController(
        backCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );

      await app_error.ErrorHandler.instance
          .wrapError(() => cameraController!.initialize());

      if (mounted) {
        setState(() {});
        await Future.delayed(const Duration(seconds: 2));
        detectPose();
      }
    } catch (e) {
      app_error.ErrorHandler.instance.handleError(context, e);
    }
  }

  void _initializePoseDetector() {
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.base, // accurate에서 base로 변경하여 속도 향상
    );
    _poseDetector = PoseDetector(options: options);
  }

  Future<void> _processImage(CameraImage image) async {
    if (_processingImage) return;
    _processingImage = true;

    try {
      if (!mounted || cameraController == null) return;

      // Android용 이미지 처리 로직
      if (Platform.isAndroid) {
        final bytes = image.planes[0].bytes;

        final inputImage = InputImage.fromBytes(
          bytes: bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: InputImageRotation.rotation90deg,
            format: InputImageFormat.yuv420,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );

        if (_poseDetector != null) {
          final poses = await _poseDetector!.processImage(inputImage);
          if (poses.isNotEmpty && mounted) {
            setState(() {
              currentPose = poses.first.landmarks;
            });
          }
        }
      }
    } catch (e) {
      print('포즈 감지 오류: $e');
    } finally {
      _processingImage = false;
    }
  }

  // 포즈 결과 처리를 위한 새로운 메서드
  void _processPoseResults(List<Pose>? poses) {
    if (!mounted) return;

    if (poses != null && poses.isNotEmpty) {
      final pose = poses.first;
      if (_checkPoseReliability(pose)) {
        setState(() {
          currentPose = pose.landmarks;
          final newPhase = _analyzePose(pose.landmarks);
          if (currentPhase == SquatPhase.bottom &&
              newPhase == SquatPhase.ascending) {
            squatCount++;
          }
          currentPhase = newPhase;
        });
      }
    }
  }

  SquatPhase _analyzePose(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final smoothedPose = _smoothPose(landmarks);
    if (smoothedPose == null) return SquatPhase.invalid;

    double? kneeAngle = _calculateKneeAngle(smoothedPose);
    if (kneeAngle == null) return SquatPhase.invalid;

    // 급격한 변화 방지
    if ((_lastKneeAngle - kneeAngle).abs() > 30) {
      return currentPhase; // 현재 상태 유지
    }
    _lastKneeAngle = kneeAngle;

    // 최소 지속 시간 체크
    if (DateTime.now().difference(_lastPhaseChange) < _minPhaseDuration) {
      return currentPhase; // 현재 상태 유지
    }

    SquatPhase newPhase;
    if (kneeAngle > 140) {
      newPhase = SquatPhase.standing;
    } else if (kneeAngle > 80) {
      newPhase = kneeAngle < _lastKneeAngle
          ? SquatPhase.descending
          : SquatPhase.ascending;
    } else {
      newPhase = SquatPhase.bottom;
    }

    if (newPhase != currentPhase) {
      _lastPhaseChange = DateTime.now();

      // 스쿼트 완료 시 통계 업데이트
      if (currentPhase == SquatPhase.bottom &&
          newPhase == SquatPhase.ascending) {
        squatCount++;
        totalSquats++;

        // 목표 달성 체크 및 알림
        GoalService.instance.getGoal().then((goal) {
          if (squatCount == goal.dailySquatTarget) {
            NotificationService.instance.showGoalAchievedNotification();
          }
        });

        // 정확도가 낮을 때 알림
        final accuracy = _calculatePoseAccuracy(landmarks);
        if (accuracy < 60) {
          NotificationService.instance.showAccuracyWarning();
        }

        accuracyScore =
            (accuracyScore * (squatCount - 1) + accuracy) / squatCount;
        squatDurations.add(DateTime.now().difference(_lastPhaseChange));
      }

      // 피드백 제공
      switch (newPhase) {
        case SquatPhase.descending:
          _speakFeedback('천천히 내려가세요');
          break;
        case SquatPhase.bottom:
          _speakFeedback('자세를 유지하세요');
          _provideHapticFeedback();
          break;
        case SquatPhase.ascending:
          _speakFeedback('천천히 올라오세요');
          break;
        case SquatPhase.standing:
          if (currentPhase == SquatPhase.ascending) {
            _speakFeedback('좋습니다');
            _provideHapticFeedback();
          }
          break;
        default:
          break;
      }
    }

    return newPhase;
  }

  double? _calculateKneeAngle(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];

    double? leftAngle, rightAngle;

    if (leftHip != null && leftKnee != null && leftAnkle != null) {
      leftAngle = SquatAnalyzer.computeAngle(
        [leftHip.x, leftHip.y],
        [leftKnee.x, leftKnee.y],
        [leftAnkle.x, leftAnkle.y],
      );
    }

    if (rightHip != null && rightKnee != null && rightAnkle != null) {
      rightAngle = SquatAnalyzer.computeAngle(
        [rightHip.x, rightHip.y],
        [rightKnee.x, rightKnee.y],
        [rightAnkle.x, rightAnkle.y],
      );
    }

    if (leftAngle != null && rightAngle != null) {
      double avgAngle = (leftAngle + rightAngle) / 2;
      // 운동 강도에 따른 각도 임계값 적용
      double targetAngle = _squatDepthThresholds[_intensity]!;
      return avgAngle > targetAngle ? avgAngle : targetAngle;
    } else if (leftAngle != null) {
      return leftAngle;
    } else if (rightAngle != null) {
      return rightAngle;
    }

    return null;
  }

  void detectPose() async {
    if (!isDetecting) {
      isDetecting = true;

      try {
        await cameraController?.startImageStream((CameraImage image) async {
          if (isDetecting && mounted) {
            await Future.delayed(const Duration(milliseconds: 500)); // 처리 간격 증가
            await _processImage(image);
          }
        });
      } catch (e) {
        print('이미지 스트림 시작 오류: $e');
        isDetecting = false;
      }
    }
  }

  @override
  void dispose() {
    isDetecting = false;
    _processingImage = false;
    cameraController?.dispose();
    _poseDetector?.close();
    _exerciseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('카메라 초기화 중...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed: _switchCamera,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetCounter,
          ),
          IconButton(
            icon:
                Icon(sessionStartTime == null ? Icons.play_arrow : Icons.stop),
            onPressed: () {
              if (sessionStartTime == null) {
                _startSession();
              } else {
                _endSession();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 카메라 프리뷰
          Transform.scale(
            scale: 1.0,
            child: Center(
              child: AspectRatio(
                aspectRatio: cameraController!.value.aspectRatio,
                child: CameraPreview(cameraController!),
              ),
            ),
          ),

          // 자세 피드백 오버레이
          Positioned.fill(
            child: CustomPaint(
              painter: PoseOverlayPainter(
                landmarks: currentPose,
                phase: currentPhase,
              ),
            ),
          ),

          // 상단 정보 패널
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '스쿼트 횟수: $squatCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '현재 단계: ${_getPhaseText(currentPhase)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  _buildPhaseIndicator(currentPhase),
                ],
              ),
            ),
          ),

          // 하단 피드백 메시지
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: _getFeedbackColor(currentPhase).withOpacity(0.9),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                _getFeedbackMessage(currentPhase),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // 자세 가이드라인 오버레이 추가
          if (currentPhase == SquatPhase.standing)
            Positioned.fill(
              child: CustomPaint(
                painter: GuidelinePainter(),
              ),
            ),

          // 하단 버튼 추가
          Positioned(
            bottom: 100,
            right: 20,
            child: FloatingActionButton(
              onPressed: _resetCounter,
              child: const Icon(Icons.refresh),
            ),
          ),

          // 운동 시간 표시
          Positioned(
            top: 80,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_exerciseSeconds ~/ 60}:${(_exerciseSeconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 목표 달성 진행률
          Positioned(
            top: 120,
            left: 20,
            right: 20,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: squatCount / _targetSquats,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseIndicator(SquatPhase phase) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getFeedbackColor(phase),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _getPhaseIcon(phase),
        color: Colors.white,
        size: 24,
      ),
    );
  }

  String _getPhaseText(SquatPhase phase) {
    switch (phase) {
      case SquatPhase.standing:
        return '준비 자세';
      case SquatPhase.descending:
        return '내려가는 중';
      case SquatPhase.bottom:
        return '최저 자세';
      case SquatPhase.ascending:
        return '올라가 중';
      case SquatPhase.invalid:
        return '자세 인식 실패';
    }
  }

  IconData _getPhaseIcon(SquatPhase phase) {
    switch (phase) {
      case SquatPhase.standing:
        return Icons.accessibility_new;
      case SquatPhase.descending:
        return Icons.arrow_downward;
      case SquatPhase.bottom:
        return Icons.crop_square;
      case SquatPhase.ascending:
        return Icons.arrow_upward;
      case SquatPhase.invalid:
        return Icons.error_outline;
    }
  }

  Color _getFeedbackColor(SquatPhase phase) {
    switch (phase) {
      case SquatPhase.standing:
        return Colors.blue;
      case SquatPhase.descending:
        return Colors.orange;
      case SquatPhase.bottom:
        return Colors.green;
      case SquatPhase.ascending:
        return Colors.orange;
      case SquatPhase.invalid:
        return Colors.red;
    }
  }

  String _getFeedbackMessage(SquatPhase phase) {
    switch (phase) {
      case SquatPhase.standing:
        return '천천히 무릎을 구부려주세요';
      case SquatPhase.descending:
        return '등을 똑바로 유지��면서 내려가세요';
      case SquatPhase.bottom:
        return '좋습니다! 이 자세를 잠시 유지하세요';
      case SquatPhase.ascending:
        return '천히 일어나세요';
      case SquatPhase.invalid:
        return '카메라 앞에서 전신이 보이 서주세요';
    }
  }

  // 카메라 전환 메서드
  Future<void> _switchCamera() async {
    if (widget.cameras.length < 2) return;

    final lensDirection = cameraController?.description.lensDirection;
    CameraDescription newCamera;

    if (lensDirection == CameraLensDirection.front) {
      newCamera = widget.cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
    } else {
      newCamera = widget.cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
    }

    await cameraController?.dispose();

    cameraController = CameraController(
      newCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.bgra8888,
    );

    try {
      await cameraController!.initialize();
      if (mounted) {
        setState(() {});
        detectPose();
      }
    } catch (e) {
      print('카메라 전환 오류: $e');
    }
  }

  // 스쿼트 카운터 리셋
  void _resetCounter() {
    setState(() {
      squatCount = 0;
    });
  }

  // 포즈 신뢰도 체크 메서드 수정
  bool _checkPoseReliability(Pose pose) {
    // 수 관절 포인트들
    final requiredLandmarks = [
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
    ];

    // 신뢰도 임계값을 매우 낮춤
    const minConfidence = 0.1; // 0.3에서 0.1로 변경

    // 최소 2개 이상의 포인트만 있어도 인정
    int validPoints = 0;
    for (var type in requiredLandmarks) {
      final landmark = pose.landmarks[type];
      if (landmark != null && landmark.likelihood >= minConfidence) {
        validPoints++;
      }
    }

    return validPoints >= 2; // 4개에서 2개로 변경
  }

  // 포 스무딩 메서드 추가
  Map<PoseLandmarkType, PoseLandmark>? _smoothPose(
      Map<PoseLandmarkType, PoseLandmark> newPose) {
    _poseHistory.add(newPose);
    if (_poseHistory.length > _historyLength) {
      _poseHistory.removeAt(0);
    }

    if (_poseHistory.length < 3) return newPose;

    final smoothedPose = <PoseLandmarkType, PoseLandmark>{};

    for (var type in PoseLandmarkType.values) {
      double sumX = 0, sumY = 0, sumZ = 0, sumLikelihood = 0;
      int count = 0;

      for (var pose in _poseHistory) {
        if (pose[type] != null) {
          sumX += pose[type]!.x;
          sumY += pose[type]!.y;
          sumZ += pose[type]!.z;
          sumLikelihood += pose[type]!.likelihood;
          count++;
        }
      }

      if (count > 0) {
        smoothedPose[type] = PoseLandmark(
          type: type,
          x: sumX / count,
          y: sumY / count,
          z: sumZ / count,
          likelihood: sumLikelihood / count,
        );
      }
    }

    return smoothedPose;
  }

  // 운동 세션 시작
  void _startSession() {
    setState(() {
      sessionStartTime = DateTime.now();
      squatCount = 0;
      squatDurations.clear();
      accuracyScore = 0.0;
    });
    NotificationService.instance.showWorkoutReminder();
  }

  // 동 세션 종료
  void _endSession() {
    if (sessionStartTime != null) {
      final duration = DateTime.now().difference(sessionStartTime!);
      _saveWorkoutSession(duration).then((_) {
        setState(() {
          sessionStartTime = null;
        });
        _showSessionSummary(duration);
      });
    }
  }

  // 세션 요약 표시
  void _showSessionSummary(Duration duration) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('운동 세션 요약'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('총 운동 시간: ${duration.inMinutes}분'),
            Text('총 스쿼트 횟수: $squatCount회'),
            Text('평균 정확도: ${accuracyScore.toStringAsFixed(1)}%'),
            if (squatDurations.isNotEmpty)
              Text('평균 스쿼트 시간: ${_calculateAverageSquatDuration().inSeconds}초'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
            child: const Text('기록 보기'),
          ),
        ],
      ),
    );
  }

  // 평균 스쿼트 시간 계산
  Duration _calculateAverageSquatDuration() {
    if (squatDurations.isEmpty) return Duration.zero;
    final totalDuration = squatDurations.reduce((a, b) => a + b);
    return Duration(
        microseconds: totalDuration.inMicroseconds ~/ squatDurations.length);
  }

  // 자세 정확도 계산
  double _calculatePoseAccuracy(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    double totalConfidence = 0;
    int count = 0;

    // 주요 관절 포인트들의 신뢰도 평균 계산
    final keyPoints = [
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    ];

    for (var point in keyPoints) {
      if (landmarks[point] != null) {
        totalConfidence += landmarks[point]!.likelihood;
        count++;
      }
    }

    return count > 0 ? (totalConfidence / count) * 100 : 0;
  }

  void _startExerciseTimer() {
    _exerciseTimer?.cancel();
    _exerciseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _exerciseSeconds++;
        });
      }
    });
  }

  void _showSettingsDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  Future<void> _speakFeedback(String text) async {
    print('Feedback: $text');
  }

  void _provideHapticFeedback() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 200);
    }
  }

  // 운동 세션 저장
  Future<void> _saveWorkoutSession(Duration duration) async {
    final session = WorkoutSession(
      startTime: sessionStartTime!,
      endTime: DateTime.now(),
      squatCount: squatCount,
      accuracy: accuracyScore,
      averageDuration: squatDurations.isEmpty
          ? 0.0
          : squatDurations.reduce((a, b) => a + b).inMilliseconds /
              squatDurations.length,
    );

    try {
      await DatabaseHelper.instance.insertWorkoutSession(session);
      print('운동 세션 저장 완료');
    } catch (e) {
      print('운동 세션 저장 오류: $e');
    }
  }
}

// 포즈 오버레이 페인터 클래스 추가
class PoseOverlayPainter extends CustomPainter {
  final Map<PoseLandmarkType, PoseLandmark>? landmarks;
  final SquatPhase phase;

  PoseOverlayPainter({required this.landmarks, required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks == null) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    // 관절 연결선 먼저 그리기
    _drawSkeleton(canvas, size, paint);

    // 키포인트 리기 (연결선 위에 그려지도록)
    landmarks!.forEach((type, landmark) {
      paint
        ..color = Colors.blue
        ..style = PaintingStyle.fill;

      // 화면 크기에 맞게 좌표 변환
      final position = Offset(
        landmark.x * size.width,
        landmark.y * size.height,
      );

      // 키포인트 그리기
      canvas.drawCircle(position, 6.0, paint);

      // 키포인트 테두리 그리기
      paint
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(position, 6.0, paint);
    });
  }

  void _drawSkeleton(Canvas canvas, Size size, Paint paint) {
    final connections = [
      // 다리
      [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
      [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
      [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
      [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],

      // 골반
      [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],

      // 상체
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
      [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
      [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],

      // 척추
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    ];

    for (var connection in connections) {
      final startLandmark = landmarks?[connection[0]];
      final endLandmark = landmarks?[connection[1]];

      if (startLandmark != null && endLandmark != null) {
        paint
          ..color = Colors.green.withOpacity(0.7)
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke;

        canvas.drawLine(
          Offset(startLandmark.x * size.width, startLandmark.y * size.height),
          Offset(endLandmark.x * size.width, endLandmark.y * size.height),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(PoseOverlayPainter oldDelegate) {
    return oldDelegate.landmarks != landmarks || oldDelegate.phase != phase;
  }
}

class SquatAnalyzer {
  static const double STANDING_ANGLE_THRESHOLD = 150.0;
  static const double SQUAT_BOTTOM_ANGLE_THRESHOLD = 90.0;

  static double computeAngle(
      List<double> pointA, List<double> pointB, List<double> pointC) {
    double vectorABx = pointB[0] - pointA[0];
    double vectorABy = pointB[1] - pointA[1];
    double vectorBCx = pointC[0] - pointB[0];
    double vectorBCy = pointC[1] - pointB[1];

    double dotProduct = (vectorABx * vectorBCx) + (vectorABy * vectorBCy);
    double magnitudeAB = sqrt(pow(vectorABx, 2) + pow(vectorABy, 2));
    double magnitudeBC = sqrt(pow(vectorBCx, 2) + pow(vectorBCy, 2));

    double angle = acos(dotProduct / (magnitudeAB * magnitudeBC)) * (180 / pi);
    return angle;
  }

  static SquatPhase validateSquat(Map<String, dynamic> keypoints) {
    final hipPoint = keypoints['left_hip'];
    final kneePoint = keypoints['left_knee'];
    final anklePoint = keypoints['left_ankle'];

    if (!_arePointsValid([hipPoint, kneePoint, anklePoint])) {
      return SquatPhase.invalid;
    }

    double kneeAngle = computeAngle([hipPoint['x'], hipPoint['y']],
        [kneePoint['x'], kneePoint['y']], [anklePoint['x'], anklePoint['y']]);

    // 자세 판정
    if (kneeAngle > STANDING_ANGLE_THRESHOLD) {
      return SquatPhase.standing;
    } else if (kneeAngle > SQUAT_BOTTOM_ANGLE_THRESHOLD) {
      return SquatPhase.descending;
    } else {
      return SquatPhase.bottom;
    }
  }

  static bool _arePointsValid(List<Map<String, dynamic>?> points) {
    return points.every((point) =>
        point != null &&
        point['x'] != null &&
        point['y'] != null &&
        point['confidence'] > 0.5);
  }
}

enum SquatPhase { standing, descending, bottom, ascending, invalid }

enum Likelihood { high, medium, low }

// GuidelinePainter 클래스 추가
class GuidelinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 세로 중앙선
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );

    // 가로 기준선들
    final guidelines = [0.3, 0.5, 0.7]; // 화면 높이의 30%, 50%, 70% 위치에 선 그리기
    for (var ratio in guidelines) {
      canvas.drawLine(
        Offset(0, size.height * ratio),
        Offset(size.width, size.height * ratio),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(GuidelinePainter oldDelegate) => false;
}

// 운동 강도 enum 추가
enum ExerciseIntensity {
  easy,
  medium,
  hard,
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('운동 기록'),
      ),
      body: const Center(
        child: Text('운동 기록이 여기에 표시됩니다'),
      ),
    );
  }
}

class WorkoutSession {
  final DateTime startTime;
  final DateTime endTime;
  final int squatCount;
  final double accuracy;
  final double averageDuration;

  WorkoutSession({
    required this.startTime,
    required this.endTime,
    required this.squatCount,
    required this.accuracy,
    required this.averageDuration,
  });

  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'squatCount': squatCount,
      'accuracy': accuracy,
      'averageDuration': averageDuration,
    };
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  Future<void> insertWorkoutSession(WorkoutSession session) async {
    // TODO: 실제 데이터베이스 구현
    // 임시로 프린만 수행
    print('세션 데이터: ${session.toMap()}');
  }
}

// SplashScreen 클래스 수정
class SplashScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const SplashScreen({super.key, required this.cameras});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();

    // 3초 후 메인 화면으로 이동
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PoseRecognitionApp(
              title: 'AI 스쿼트 트레이너',
              cameras: widget.cameras,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _animation,
              child: const Icon(
                Icons.fitness_center,
                size: 100,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _animation,
              child: const Text(
                'AI 스쿼트 트레이너',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
