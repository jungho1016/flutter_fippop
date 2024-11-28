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

    cameraController = CameraController(
      widget.cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.bgra8888,
    );

    try {
      await cameraController!.initialize();
      if (mounted) {
        setState(() {});
        // 카메라 초기화 후 포즈 감지 시작
        detectPose();
      }
    } catch (e) {
      print('카메라 초기화 오류: $e');
    }
  }

  void _initializePoseDetector() {
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.accurate,
    );
    _poseDetector = PoseDetector(options: options);
  }

  Future<void> _processImage(CameraImage image) async {
    final inputImage = InputImage.fromBytes(
      bytes: image.planes[0].bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation90deg, // 카메라 방향에 따라 조정 필요
        format: InputImageFormat.bgra8888, // 이미지 포맷
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );

    try {
      final poses = await _poseDetector?.processImage(inputImage);
      if (poses != null && poses.isNotEmpty) {
        final pose = poses.first;
        setState(() {
          currentPose = pose.landmarks;
          currentPhase = _analyzePose(pose);
        });
      }
    } catch (e) {
      print('포즈 감지 오류: $e');
    }
  }

  SquatPhase _analyzePose(Pose pose) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];

    if (leftHip == null || leftKnee == null || leftAnkle == null) {
      return SquatPhase.invalid;
    }

    double kneeAngle = SquatAnalyzer.computeAngle(
      [leftHip.x, leftHip.y],
      [leftKnee.x, leftKnee.y],
      [leftAnkle.x, leftAnkle.y],
    );

    if (kneeAngle > 150) {
      return SquatPhase.standing;
    } else if (kneeAngle > 90) {
      return SquatPhase.descending;
    } else {
      return SquatPhase.bottom;
    }
  }

  void detectPose() async {
    if (!isDetecting) {
      isDetecting = true;

      await cameraController?.startImageStream((CameraImage image) async {
        if (isDetecting) {
          await _processImage(image);
        }
      });
    }
  }

  @override
  void dispose() {
    _poseDetector?.close();
    cameraController?.dispose();
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
            onPressed: () {
              // 카메라 전환 기능 추가 예정
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
        return '천천히 일어나세요';
      case SquatPhase.invalid:
        return '카메라 앞에서 전신이 보이도록 서주세요';
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

    // 키포인트 그리기
    landmarks!.forEach((type, landmark) {
      final confidence = _getLikelihoodFromInference(landmark.likelihood);
      paint.color = _getConfidenceColor(confidence);
      canvas.drawCircle(
        Offset(landmark.x * size.width, landmark.y * size.height),
        8,
        paint,
      );
    });

    // 관절 연결선 그리기
    _drawSkeleton(canvas, size, paint);
  }

  // 추가: ML Kit의 confidence 값을 Likelihood enum으로 변환
  Likelihood _getLikelihoodFromInference(double confidence) {
    if (confidence > 0.8) return Likelihood.high;
    if (confidence > 0.5) return Likelihood.medium;
    return Likelihood.low;
  }

  void _drawSkeleton(Canvas canvas, Size size, Paint paint) {
    final connections = [
      [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
      [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
      [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
      [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
      [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
      [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
      [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
    ];

    for (var connection in connections) {
      final startLandmark = landmarks?[connection[0]];
      final endLandmark = landmarks?[connection[1]];

      if (startLandmark != null && endLandmark != null) {
        paint.color = _getConnectionColor(phase);
        canvas.drawLine(
          Offset(startLandmark.x * size.width, startLandmark.y * size.height),
          Offset(endLandmark.x * size.width, endLandmark.y * size.height),
          paint,
        );
      }
    }
  }

  Color _getConfidenceColor(Likelihood confidence) {
    if (confidence == Likelihood.high) return Colors.green;
    if (confidence == Likelihood.medium) return Colors.yellow;
    return Colors.red;
  }

  Color _getConnectionColor(SquatPhase phase) {
    switch (phase) {
      case SquatPhase.standing:
        return Colors.blue.withOpacity(0.7);
      case SquatPhase.descending:
        return Colors.orange.withOpacity(0.7);
      case SquatPhase.bottom:
        return Colors.green.withOpacity(0.7);
      case SquatPhase.ascending:
        return Colors.orange.withOpacity(0.7);
      case SquatPhase.invalid:
        return Colors.red.withOpacity(0.7);
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
