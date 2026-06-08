import 'dart:io';

import 'package:flutter/material.dart';

class ImagePreviewWidget extends StatelessWidget {
  final File? imageFile;

  const ImagePreviewWidget({super.key, this.imageFile});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (imageFile == null) {
      return Container(
        height: 240,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_search, size: 64, color: colorScheme.outlineVariant),
            const SizedBox(height: 12),
            Text(
              'Nenhuma imagem selecionada',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colorScheme.outline),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.file(
        imageFile!,
        height: 300,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}
