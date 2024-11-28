import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:io';
import 'package:flutter/material.dart' show Size;

class CameraService {
  static final CameraService instance = CameraService._();
  CameraService._();

  CameraController? _controller;
  PoseDetector? _poseDetector;
  bool _processingFrame = false;

  Future<void> initialize(List<CameraDescription> cameras) async {
    if (cameras.isEmpty) {
      throw Exception('카메라를 찾을 수 없습니다.');
    }

    final camera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize();

    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.accurate,
      ),
    );
  }

  Future<void> startStream(
    Function(Map<PoseLandmarkType, PoseLandmark>) onPoseDetected,
  ) async {
    if (_controller == null) return;

    await _controller!.startImageStream((image) async {
      if (_processingFrame) return;
      _processingFrame = true;

      try {
        final poses = await compute(
          _processPoseDetection,
          _ImageData(image, _poseDetector!),
        );

        if (poses.isNotEmpty) {
          onPoseDetected(poses.first.landmarks);
        }
      } catch (e) {
        debugPrint('포즈 감지 오류: $e');
      } finally {
        _processingFrame = false;
      }
    });
  }

  void stopStream() {
    _controller?.stopImageStream();
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    await _poseDetector?.close();
  }

  CameraController? get controller => _controller;

  Future<List<Pose>> detectPose(CameraImage image) async {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }

    final poses = await _poseDetector!.processImage(
      InputImage.fromBytes(
        bytes: allBytes.done() as Uint8List,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.bgra8888,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      ),
    );

    return poses;
  }
}

class _ImageData {
  final CameraImage image;
  final PoseDetector detector;

  _ImageData(this.image, this.detector);
}

Future<List<Pose>> _processPoseDetection(_ImageData data) async {
  final inputImage = InputImage.fromBytes(
    bytes: data.image.planes[0].bytes,
    metadata: InputImageMetadata(
      size: Size(
        data.image.width.toDouble(),
        data.image.height.toDouble(),
      ),
      rotation: Platform.isAndroid
          ? InputImageRotation.rotation90deg
          : InputImageRotation.rotation0deg,
      format: InputImageFormat.bgra8888,
      bytesPerRow: data.image.planes[0].bytesPerRow,
    ),
  );

  return await data.detector.processImage(inputImage);
}
