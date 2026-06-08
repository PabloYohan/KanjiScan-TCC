import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/prediction_provider.dart';
import '../widgets/action_buttons_widget.dart';
import '../widgets/image_preview_widget.dart';
import '../widgets/prediction_card_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Kanji Scan'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Consumer<PredictionProvider>(
        builder: (context, provider, _) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!provider.hasImage) _buildHeader(context),
                    if (!provider.hasImage) const SizedBox(height: 20),
                    ImagePreviewWidget(imageFile: provider.selectedImage),
                    const SizedBox(height: 20),
                    ActionButtonsWidget(
                      onCameraPressed: provider.pickImageFromCamera,
                      onGalleryPressed: provider.pickImageFromGallery,
                    ),
                    if (provider.hasImage) ...[
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: provider.status == PredictionStatus.loading
                            ? null
                            : provider.predict,
                        icon: const Icon(Icons.search),
                        label: const Text('Analisar Caractere'),
                      ),
                    ],
                    if (provider.status == PredictionStatus.error &&
                        provider.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _buildErrorCard(context, provider.errorMessage!),
                    ],
                    if (provider.status == PredictionStatus.success &&
                        provider.result != null) ...[
                      const SizedBox(height: 20),
                      PredictionCardWidget(result: provider.result!),
                    ],
                    if (provider.hasImage) ...[
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: provider.reset,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Recomeçar'),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
              if (provider.status == PredictionStatus.loading)
                _buildLoadingOverlay(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '日本語',
            style: TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reconhecimento de Caracteres Japoneses',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tire uma foto ou selecione uma imagem contendo um caractere japonês para identificá-lo com IA.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Analisando imagem...',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
