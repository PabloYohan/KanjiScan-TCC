import 'package:flutter/material.dart';

class ActionButtonsWidget extends StatelessWidget {
  final VoidCallback onCameraPressed;
  final VoidCallback onGalleryPressed;

  const ActionButtonsWidget({
    super.key,
    required this.onCameraPressed,
    required this.onGalleryPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onCameraPressed,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Câmera'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onGalleryPressed,
            icon: const Icon(Icons.photo_library),
            label: const Text('Galeria'),
          ),
        ),
      ],
    );
  }
}
