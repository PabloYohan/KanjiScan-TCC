class AppConstants {
  AppConstants._();

  // Altere para o endereço da sua API.
  // Em emulador Android, use 10.0.2.2 para apontar para localhost da máquina host.
  // Em dispositivo físico, use o IP da máquina na rede local (ex: 192.168.x.x).
  static const String baseUrl = 'http://192.168.18.126:3000';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
