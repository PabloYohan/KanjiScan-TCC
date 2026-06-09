# KanjiScan — Flutter Application

Aplicativo móvel para reconhecimento de caracteres japoneses via câmera ou galeria. O usuário seleciona uma imagem contendo um caractere (hiragana, katakana ou kanji JLPT N5), envia para a API de OCR e recebe o caractere identificado, sua romanização e significado em português.

## Tecnologias

- **Flutter** 3.x / Dart SDK ^3.11.4
- **Provider** ^6.1.2 — gerenciamento de estado (ChangeNotifier)
- **Dio** ^5.7.0 — cliente HTTP com suporte a multipart
- **image_picker** ^1.1.2 — acesso à câmera e galeria

## Estrutura de pastas

```
lib/
├── main.dart                        # Ponto de entrada; configura MultiProvider
├── app.dart                         # Widget raiz (MaterialApp + tema)
├── core/
│   ├── constants/app_constants.dart # URL base da API e timeouts
│   ├── errors/app_exception.dart    # Classe de exceção customizada
│   └── theme/app_theme.dart         # Tema Material 3 (cor semente beni-iro #C41E3A)
├── data/
│   ├── models/prediction_result.dart    # Modelo de resultado (label, confidence, meaning)
│   └── services/prediction_service.dart # Upload multipart via Dio
└── presentation/
    ├── providers/prediction_provider.dart  # Estado e lógica de negócio
    ├── screens/home_screen.dart            # Tela principal
    └── widgets/
        ├── action_buttons_widget.dart      # Botões Câmera e Galeria
        ├── image_preview_widget.dart       # Pré-visualização da imagem selecionada
        └── prediction_card_widget.dart     # Card com resultado da predição
```

## Pré-requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado e no PATH
- Dispositivo físico ou emulador Android/iOS configurado
- A [API de OCR](../japanese-ocr-api-py/README.md) em execução na rede local

## Configuração

Abra [lib/core/constants/app_constants.dart](lib/core/constants/app_constants.dart) e ajuste `baseUrl` para o endereço IP da máquina que executa a API:

```dart
static const String baseUrl = 'http://<SEU_IP>:3000';
```

> O app usa HTTP simples. Em Android, `android:usesCleartextTraffic="true"` já está configurado no `AndroidManifest.xml`.

Em seguida, instale as dependências:

```bash
flutter pub get
```

## Executando

```bash
flutter run
```

Para um dispositivo específico:

```bash
flutter devices          # lista dispositivos disponíveis
flutter run -d <device_id>
```

## Build de produção

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Google Play)
flutter build appbundle --release

# iOS (requer macOS)
flutter build ios --release
```

## Arquitetura

O app segue separação em três camadas:

| Camada | Responsabilidade |
|---|---|
| **Data** | Modelos de dados e comunicação com a API (`PredictionService`) |
| **Provider** | Estado da aplicação, lógica de seleção de imagem e orquestração (`PredictionProvider`) |
| **Presentation** | Widgets e telas — apenas renderização e captura de eventos |

O `PredictionProvider` expõe um enum `PredictionStatus` com os estados `idle`, `loading`, `success` e `error`, que controla o que é exibido na `HomeScreen`.

## Fluxo de uso

1. O usuário toca em **Câmera** ou **Galeria** para selecionar uma imagem.
2. A imagem é redimensionada para no máximo 1024 × 1024 px com qualidade 85 %.
3. Ao tocar em **Analisar Caractere**, o `PredictionService` faz um `POST /api/predict` com a imagem como `multipart/form-data`.
4. A resposta é mapeada para `PredictionResult` e exibida no `PredictionCardWidget` com o kanji, confiança (%), romanização e significado.
5. O botão **Recomeçar** limpa o estado e volta ao início.

## Integração com a API

| Campo | Valor |
|---|---|
| Endpoint | `POST /api/predict` |
| Content-Type | `multipart/form-data` (campo `image`) |
| Formatos aceitos | JPEG, PNG, WebP, BMP |
| Resposta (sucesso) | `{ "success": true, "data": { "label": "字", "confidence": 0.96, "meaning": "..." } }` |
| Timeout de conexão | 15 s |
| Timeout de leitura | 30 s |
