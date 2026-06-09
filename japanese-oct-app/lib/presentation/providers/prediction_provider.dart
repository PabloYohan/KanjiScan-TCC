import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/errors/app_exception.dart';
import '../../data/models/prediction_result.dart';
import '../../data/services/prediction_service.dart';

enum PredictionStatus { idle, loading, success, error }

class PredictionProvider extends ChangeNotifier {
  final PredictionService _predictionService;
  final ImagePicker _imagePicker = ImagePicker();

  PredictionStatus _status = PredictionStatus.idle;
  File? _selectedImage;
  PredictionResult? _result;
  String? _errorMessage;

  PredictionProvider({required PredictionService predictionService})
      : _predictionService = predictionService;

  PredictionStatus get status => _status;
  File? get selectedImage => _selectedImage;
  PredictionResult? get result => _result;
  String? get errorMessage => _errorMessage;
  bool get hasImage => _selectedImage != null;

  Future<void> pickImageFromCamera() => _pickImage(ImageSource.camera);
  Future<void> pickImageFromGallery() => _pickImage(ImageSource.gallery);

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (picked == null) return;

    _selectedImage = File(picked.path);
    _result = null;
    _errorMessage = null;
    _status = PredictionStatus.idle;
    notifyListeners();
  }

  Future<void> predict() async {
    if (_selectedImage == null) return;

    _status = PredictionStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _result = await _predictionService.predict(_selectedImage!);
      _status = PredictionStatus.success;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _status = PredictionStatus.error;
    } catch (_) {
      _errorMessage = 'Ocorreu um erro inesperado. Tente novamente.';
      _status = PredictionStatus.error;
    }

    notifyListeners();
  }

  void reset() {
    _status = PredictionStatus.idle;
    _selectedImage = null;
    _result = null;
    _errorMessage = null;
    notifyListeners();
  }
}
