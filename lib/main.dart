import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:async';
import 'dart:math' show pi, acos, sqrt, pow;

// 앱 시작 전 카메라 초기화를 위해 main 함수를 수정
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

// MyApp 클래스 수정
class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Squat Pose Detection',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: PoseRecognitionApp(title: 'Pose Detection', cameras: cameras),
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

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializePoseDetector();
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras.isEmpty) {
      print('사용 가능한 카메라가 없습니다.');
      return;
    }

    try {
      // 후면 카메라로 시작
      final backCamera = widget.cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => widget.cameras.first,
      );

      cameraController = CameraController(
        backCamera,
        ResolutionPreset.low, // 해상도를 낮춤
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );

      await cameraController!.initialize();
      if (!mounted) return;

      setState(() {});

      // 포즈 감지 시작 전 지연
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        detectPose();
      }
    } catch (e) {
      print('카메라 초기화 오류: $e');
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
          final newPhase = _analyzePose(pose);
          if (currentPhase == SquatPhase.bottom &&
              newPhase == SquatPhase.ascending) {
            squatCount++;
          }
          currentPhase = newPhase;
        });
      }
    }
  }

  SquatPhase _analyzePose(Pose pose) {
    final smoothedPose = _smoothPose(pose.landmarks);
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
      return (leftAngle + rightAngle) / 2;
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
        return '올라가는 중';
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
        return '등을 똑바로 유지하면서 내려가세요';
      case SquatPhase.bottom:
        return '좋습니다! 이 자세를 잠시 유지하세요';
      case SquatPhase.ascending:
        return '천히 일어나세요';
      case SquatPhase.invalid:
        return '카메라 앞에서 전신이 보이도 서주세요';
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
    // 필수 관절 포인트들
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

  // 포즈 스무딩 메서드 추가
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

    // 키포인트 그리기 (연결선 위에 그려지도록)
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
