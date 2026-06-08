import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/services/prediction_service.dart';
import 'presentation/providers/prediction_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<PredictionService>(
          create: (_) => PredictionService(),
        ),
        ChangeNotifierProxyProvider<PredictionService, PredictionProvider>(
          create: (context) => PredictionProvider(
            predictionService: context.read<PredictionService>(),
          ),
          update: (context, service, previous) =>
              previous ?? PredictionProvider(predictionService: service),
        ),
      ],
      child: const KanjiScanApp(),
    ),
  );
}
