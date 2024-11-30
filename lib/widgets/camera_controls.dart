import 'package:flutter/material.dart';

class CameraControls extends StatelessWidget {
  final VoidCallback onCapture;
  final VoidCallback onFlipCamera;
  final VoidCallback onFlashToggle;
  final bool isFlashOn;

  const CameraControls({
    super.key,
    required this.onCapture,
    required this.onFlipCamera,
    required this.onFlashToggle,
    required this.isFlashOn,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 32,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              onPressed: onFlashToggle,
              icon: Icon(
                isFlashOn ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
                size: 32,
              ),
            ),
            FloatingActionButton.large(
              onPressed: onCapture,
              child: const Icon(Icons.camera, size: 32),
            ),
            IconButton(
              onPressed: onFlipCamera,
              icon: const Icon(
                Icons.flip_camera_ios,
                color: Colors.white,
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
