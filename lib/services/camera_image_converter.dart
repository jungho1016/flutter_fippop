import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:flutter/foundation.dart';

class CameraImageConverter {
  static InputImage? convertToInputImage(CameraImage image) {
    try {
      final allBytes = List<int>.empty(growable: true);

      allBytes.addAll(image.planes[0].bytes);
      allBytes.addAll(image.planes[1].bytes);
      allBytes.addAll(image.planes[2].bytes);

      final inputImageData = InputImageMetadata(
        size: ui.Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation90deg,
        format: InputImageFormat.yuv420,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      return InputImage.fromBytes(
        bytes: Uint8List.fromList(allBytes),
        metadata: inputImageData,
      );
    } catch (e) {
      debugPrint('이미지 변환 오류: $e');
      return null;
    }
  }
}
