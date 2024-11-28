import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:async';
import 'settings_screen.dart';
import '../widgets/pose_overlay_painter.dart';
import '../models/squat_phase.dart';
import '../models/exercise_intensity.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({
    super.key,
    required this.title,
    required this.cameras,
  });

  final String title;
  final List<CameraDescription> cameras;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  bool isDetecting = false;
  CameraController? cameraController;
  PoseDetector? _poseDetector;
  Map<PoseLandmarkType, PoseLandmark>? currentPose;
  final bool _processingFrame = false;

  // 운동 상태 관리
  SquatPhase currentPhase = SquatPhase.standing;
  int squatCount = 0;
  DateTime? sessionStartTime;
  double accuracyScore = 0.0;
  List<Duration> squatDurations = [];
  Timer? _exerciseTimer;

  // 설정값
  final ExerciseIntensity _intensity = ExerciseIntensity.medium;
  final int _targetSquats = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _initializePoseDetector();
    _startExerciseTimer();
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _exerciseTimer?.cancel();
    cameraController?.dispose();
    _poseDetector?.close();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      cameraController = CameraController(
        widget.cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );
      await cameraController!.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('카메라 초기화 오류: $e');
    }
  }

  Future<void> _initializePoseDetector() async {
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.accurate,
    );
    _poseDetector = PoseDetector(options: options);
  }

  void _startExerciseTimer() {
    sessionStartTime = DateTime.now();
    _exerciseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _loadSettings() async {
    // 설정값을 로드하는 로직을 여기에 구현
    // 나중에 실제 설정 로직을 추가할 수 있습니다
  }

  Future<void> _switchCamera() async {
    if (widget.cameras.length < 2) return;

    final newCameraIndex =
        cameraController?.description == widget.cameras[0] ? 1 : 0;

    await cameraController?.dispose();

    setState(() {
      cameraController = CameraController(
        widget.cameras[newCameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );
    });

    await cameraController?.initialize();
  }

  Future<void> _showSettingsDialog() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  void _finishWorkout() {
    setState(() {
      isDetecting = false;
      sessionStartTime = null;
      squatCount = 0;
      accuracyScore = 0.0;
      squatDurations.clear();
    });
  }

  // ... (나머지 메서드들은 main.dart에서 가져옴)

  @override
  Widget build(BuildContext context) {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed: _switchCamera,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Transform.scale(
              scale: 1.0,
              child: AspectRatio(
                aspectRatio: 1 / cameraController!.value.aspectRatio,
                child: CameraPreview(cameraController!),
              ),
            ),
            CustomPaint(
              painter: PoseOverlayPainter(
                landmarks: currentPose,
                phase: currentPhase,
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _buildInfoPanel(),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildControlPanel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPanel() {
    final exerciseTime = sessionStartTime != null
        ? DateTime.now().difference(sessionStartTime!)
        : Duration.zero;

    return Card(
      color: Colors.black54,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '스쿼트 횟수: $squatCount / $_targetSquats',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '정확도: ${accuracyScore.toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              '운동 시간: ${exerciseTime.inMinutes}:${(exerciseTime.inSeconds % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Card(
      color: Colors.black54,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(
                isDetecting ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
              onPressed: () {
                setState(() {
                  isDetecting = !isDetecting;
                  if (isDetecting && sessionStartTime == null) {
                    sessionStartTime = DateTime.now();
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.stop,
                color: Colors.white,
                size: 32,
              ),
              onPressed: squatCount > 0 ? _finishWorkout : null,
            ),
          ],
        ),
      ),
    );
  }

  // ... (나머지 UI 관련 메서드들은 main.dart에서 가져옴)
}
