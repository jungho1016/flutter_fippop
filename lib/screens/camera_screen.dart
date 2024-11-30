import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../widgets/camera_controls.dart';
import '../widgets/camera_overlay.dart';
import '../models/squat_phase.dart';
import '../services/pose_analyzer.dart';
import '../services/camera_image_converter.dart';
import '../widgets/pose_guide.dart';
import '../models/squat_counter.dart';
import '../widgets/squat_counter_display.dart';
import '../widgets/pose_skeleton_widget.dart';
import '../services/database_service.dart';
import '../models/squat_record.dart';
import '../models/pose_error.dart';

Future<CameraController> initializeCamera() async {
  final cameras = await availableCameras();
  final controller = CameraController(
    cameras[0],
    ResolutionPreset.high,
    enableAudio: false,
    imageFormatGroup: ImageFormatGroup.bgra8888,
  );
  await controller.initialize();
  return controller;
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isFlashOn = false;
  XFile? _lastImage;
  final _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.accurate,
    ),
  );
  List<Pose>? _detectedPoses;
  SquatPhase _currentPhase = SquatPhase.standing;
  bool _isProcessing = false;
  final _squatCounter = SquatCounter();
  CameraController? _cameraController;
  bool _isInitializing = true;
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );
      await _cameraController!.initialize();
      await _cameraController!
          .lockCaptureOrientation(DeviceOrientation.portraitUp);
      if (mounted) {
        await _cameraController!.startImageStream(_processCameraImage);
        setState(() => _isInitializing = false);
      }
    } catch (e) {
      debugPrint('카메라 초기화 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('카메라를 시작할 수 없습니다')),
        );
      }
    }
  }

  @override
  void dispose() {
    _poseDetector.close();
    _squatCounter.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      debugPrint('=== 이미지 처리 시작 ===');
      debugPrint('이미지 크기: ${image.width}x${image.height}');
      debugPrint('이미지 포맷: ${image.format.group}');
      debugPrint('플레인 수: ${image.planes.length}');

      final inputImage = CameraImageConverter.convertToInputImage(image);
      if (inputImage == null) {
        debugPrint('❌ 이미지 변환 실패');
        return;
      }
      debugPrint('✅ 이미지 변환 성공');
      debugPrint(
          '변환된 이미지 크기: ${inputImage.metadata?.size.width}x${inputImage.metadata?.size.height}');
      debugPrint('변환된 이미지 회전: ${inputImage.metadata?.rotation}');
      debugPrint('변환된 이미지 포맷: ${inputImage.metadata?.format}');

      debugPrint('🔍 포즈 감지 시작');
      try {
        final poses = await _poseDetector.processImage(inputImage);
        debugPrint('감지된 포즈 수: ${poses.length}');

        if (poses.isNotEmpty) {
          final landmarks = poses.first.landmarks;
          debugPrint('감지된 랜드마크 수: ${landmarks.length}');
          debugPrint('주요 랜드마크 좌표:');
          debugPrint(
              '- 왼쪽 어깨: ${landmarks[PoseLandmarkType.leftShoulder]?.x}, ${landmarks[PoseLandmarkType.leftShoulder]?.y}');
          debugPrint(
              '- 오른쪽 어깨: ${landmarks[PoseLandmarkType.rightShoulder]?.x}, ${landmarks[PoseLandmarkType.rightShoulder]?.y}');
          debugPrint(
              '- 왼쪽 엉덩이: ${landmarks[PoseLandmarkType.leftHip]?.x}, ${landmarks[PoseLandmarkType.leftHip]?.y}');

          if (mounted) {
            setState(() {
              _detectedPoses = poses;
              _currentPhase = PoseAnalyzer.analyzeSquat(landmarks);
            });
            _squatCounter.updatePhase(_currentPhase);
            debugPrint('✅ 포즈 분석 완료: $_currentPhase');
          }
        } else {
          debugPrint('❌ 포즈가 감지되지 않음');
        }
      } catch (e, stack) {
        debugPrint('❌ 포즈 감지 오류: $e');
        debugPrint('스택 트레이스: $stack');
      }
    } catch (e, stack) {
      debugPrint('❌ 전체 처리 오류: $e');
      debugPrint('스택 트레이스: $stack');
    } finally {
      _isProcessing = false;
      debugPrint('=== 이미지 처리 완료 ===\n');
    }
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.storage.request();
  }

  Future<void> _saveToGallery(String path) async {
    final bytes = await File(path).readAsBytes();
    await ImageGallerySaver.saveImage(bytes);
  }

  Widget _buildThumbnail() {
    if (_lastImage == null) return const SizedBox();

    return Positioned(
      bottom: 32,
      left: 32,
      child: GestureDetector(
        onTap: () {
          // TODO: 이미지 상세보기 화면으로 이동
        },
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: FileImage(File(_lastImage!.path)),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _finishWorkout() async {
    if (_squatCounter.count > 0) {
      final record = SquatRecord(
        id: 0,
        dateTime: DateTime.now(),
        count: _squatCounter.count,
        accuracy: _squatCounter.accuracy,
        duration: Duration(seconds: _squatCounter.duration),
      );

      await _databaseService.insertRecord(record);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('운동 기록이 저장되었습니다')),
        );
        Navigator.pushNamed(context, '/history'); // 기록 화면으로 이동
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ChangeNotifierProvider<SquatCounter>.value(
      value: _squatCounter,
      child: Scaffold(
        body: Stack(
          children: [
            Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.95,
                  maxHeight: MediaQuery.of(context).size.height * 0.98,
                ),
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(_cameraController!),
                      if (_detectedPoses != null && _detectedPoses!.isNotEmpty)
                        Positioned.fill(
                          child: PoseSkeletonWidget(
                            landmarks: _detectedPoses!.first.landmarks,
                            phase: _currentPhase,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              left: 16,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
                onPressed: () {
                  // 운동 중이라면 초기화
                  _squatCounter.reset();
                  // 모든 화면을 제거하고 홈 화면으로 이동
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false, // 모든 이전 화면 제거
                  );
                },
              ),
            ),
            const CameraOverlay(),
            CameraControls(
              onCapture: () async {
                try {
                  final image = await _cameraController!.takePicture();
                  await _saveToGallery(image.path);
                  setState(() => _lastImage = image);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('사진이 갤러리에 저장되었습니다')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('사진 촬영에 실패했습니다')),
                    );
                  }
                }
              },
              onFlipCamera: () async {
                final cameras = await availableCameras();
                final newCamera = _cameraController!.description == cameras[0]
                    ? cameras[1]
                    : cameras[0];

                await _cameraController!.dispose();
                final newController = CameraController(
                  newCamera,
                  ResolutionPreset.max,
                  enableAudio: false,
                );
                await newController.initialize();
                setState(() {});
              },
              onFlashToggle: () async {
                setState(() => _isFlashOn = !_isFlashOn);
                await _cameraController!.setFlashMode(
                  _isFlashOn ? FlashMode.torch : FlashMode.off,
                );
              },
              isFlashOn: _isFlashOn,
            ),
            _buildThumbnail(),
            PoseGuide(
              poses: _detectedPoses,
              phase: _currentPhase,
              error: PoseError.none,
            ),
            const SquatCounterDisplay(),
            if (_squatCounter.count > 0)
              Positioned(
                right: 16,
                bottom: 100,
                child: FloatingActionButton(
                  onPressed: _finishWorkout,
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.check),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
