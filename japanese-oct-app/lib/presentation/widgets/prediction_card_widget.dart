import 'package:flutter/material.dart';

import '../../data/models/prediction_result.dart';

class PredictionCardWidget extends StatelessWidget {
  final PredictionResult result;

  const PredictionCardWidget({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'RESULTADO',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  result.label,
                  style: TextStyle(
                    fontSize: 64,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _InfoRow(
              icon: Icons.percent,
              label: 'Confiança',
              value: result.confidencePercent,
            ),
            if (result.romanization != null) ...[
              const Divider(height: 24),
              _InfoRow(
                icon: Icons.text_fields,
                label: 'Romanização',
                value: result.romanization!,
              ),
            ],
            if (result.meaning != null) ...[
              const Divider(height: 24),
              _InfoRow(
                icon: Icons.translate,
                label: 'Significado',
                value: result.meaning!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
