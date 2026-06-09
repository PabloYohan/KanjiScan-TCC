/// Exceção centralizada da aplicação.
/// O serviço de dados captura erros técnicos (DioException, etc.)
/// e os converte nesta classe antes de propagar para a camada de apresentação.
class AppException implements Exception {
  final String message;

  const AppException(this.message);

  @override
  String toString() => message;
}
