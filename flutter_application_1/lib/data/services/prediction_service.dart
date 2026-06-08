import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../models/prediction_result.dart';

class PredictionService {
  late final Dio _dio;

  PredictionService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
      ),
    );
  }

  Future<PredictionResult> predict(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'image.jpg',
        ),
      });

      final response = await _dio.post<Map<String, dynamic>>(
        '/api/predict',
        data: formData,
      );

      // A API retorna { "success": true, "data": { ... } }
      final data = response.data!['data'] as Map<String, dynamic>;
      return PredictionResult.fromJson(data);
    } on DioException catch (e) {
      throw AppException(_mapDioError(e));
    } catch (e) {
      throw const AppException('Ocorreu um erro inesperado. Tente novamente.');
    }
  }

  String _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'A requisição excedeu o tempo limite. Verifique sua conexão.';
      case DioExceptionType.connectionError:
        return 'Não foi possível conectar ao servidor. Verifique se a API está ativa.';
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        if (status == 422) {
          return 'Imagem inválida ou formato não suportado.';
        }
        return 'Erro do servidor (código $status). Tente novamente.';
      default:
        return 'Erro de rede. Tente novamente.';
    }
  }
}
