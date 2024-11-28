import 'package:image/image.dart' as img;

class ImageProcessor {
  static img.Image resizeImage(img.Image image) {
    return img.copyResize(
      image,
      width: 640, // ML Kit의 권장 크기
      height: 480,
      interpolation: img.Interpolation.linear,
    );
  }

  static Future<img.Image> preprocessImage(img.Image image) async {
    // 이미지 전처리 최적화
    final resized = resizeImage(image);

    // 밝기 정규화
    for (var pixel in resized) {
      pixel.r = (pixel.r / 255 * 2 - 1).round();
      pixel.g = (pixel.g / 255 * 2 - 1).round();
      pixel.b = (pixel.b / 255 * 2 - 1).round();
    }

    return resized;
  }
}
