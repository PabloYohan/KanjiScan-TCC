class PredictionResult {
  final String label;
  final double confidence;
  final String? romanization;
  final String? meaning;

  const PredictionResult({
    required this.label,
    required this.confidence,
    this.romanization,
    this.meaning,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      label: json['label'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      romanization: json['romanization'] as String?,
      meaning: json['meaning'] as String?,
    );
  }

  /// Retorna a confiança formatada como porcentagem (ex: "96.0%")
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';
}
