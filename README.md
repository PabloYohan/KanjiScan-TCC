# KanjiScan

Aplicação de reconhecimento óptico de caracteres japoneses (kanji) desenvolvida como Trabalho de Conclusão de Curso. O sistema é composto por um aplicativo mobile em Flutter e uma API de inferência em Python.

## Visão Geral

O usuário fotografa ou seleciona uma imagem contendo um kanji, o aplicativo envia a imagem para a API, que realiza o pré-processamento e executa um modelo CNN (ONNX) treinado. O resultado — caractere, confiança e significado em inglês — é exibido na tela.

```
Aplicativo Flutter  →  POST /api/predict (multipart)  →  API Python
                    ←  { label, confidence, meaning }  ←
```

## Estrutura do Repositório

```
KanjiScan - TCC/
├── flutter_application_1/   # Aplicativo mobile (Flutter/Dart)
└── japanese-ocr-api-py/     # API de inferência (Python/FastAPI)
```

---

## flutter_application_1 — Aplicativo Mobile

### Tecnologias

- **Flutter** (Dart)
- **Provider** — gerenciamento de estado
- **Dio** — cliente HTTP
- **image_picker** — câmera e galeria

### Funcionalidades

- Captura de imagem pela câmera ou galeria
- Upload multipart para a API com compressão automática (máx. 1024×1024, 85% de qualidade)
- Exibição do kanji reconhecido, percentual de confiança e significado
- Tratamento de erros e estado de carregamento

### Configuração

A URL base da API está definida em `lib/core/constants/app_constants.dart`:

```dart
static const String baseUrl = 'http://192.168.18.126:3000';
```

| Ambiente | URL |
|---|---|
| Dispositivo físico (rede local) | IP local da máquina que roda a API |
| Emulador Android | `http://10.0.2.2:3000` |

### Como executar

```bash
cd flutter_application_1
flutter pub get
flutter run
```

---

## japanese-ocr-api-py — API de Inferência

### Tecnologias

- **FastAPI** + **Uvicorn**
- **ONNX Runtime** — inferência otimizada
- **OpenCV** + **Pillow** + **SciPy** — pré-processamento de imagem
- **PyTorch** — softmax e utilitários de tensor

### Endpoints

| Método | Rota | Descrição |
|---|---|---|
| `GET` | `/api/health` | Status do serviço e uptime |
| `POST` | `/api/predict` | Reconhecimento de kanji |

#### POST /api/predict

**Request:** `multipart/form-data` com campo `image` (JPEG, PNG, WebP ou BMP, máx. 5 MB)

**Response de sucesso:**
```json
{
  "success": true,
  "data": {
    "label": "楷",
    "confidence": 0.9645,
    "meaning": "block style (of calligraphy)"
  }
}
```

**Response de erro:**
```json
{
  "success": false,
  "error": {
    "code": "INVALID_FILE_TYPE",
    "message": "Unsupported file type. Use JPEG, PNG, WebP, or BMP."
  }
}
```

### Pipeline de pré-processamento

1. Auto-orientação EXIF → escala de cinza → redimensionamento para 512×512
2. Suavização gaussiana (Pillow, raio 0.7)
3. CLAHE — equalização adaptativa de histograma
4. Limiarização adaptativa gaussiana (traços brancos em fundo preto)
5. Fechamento morfológico — une fragmentos de traço próximos
6. Análise de componentes conectados — remove ruído (< 8% da área máxima)
7. Recorte pelo bounding box com margem de 8 px
8. Canvas quadrado + 12% de padding
9. Redimensionamento para 64×64 px centralizado
10. Normalização para tensor float `[1, 1, 64, 64]`

### Configuração

Crie um arquivo `.env` na raiz de `japanese-ocr-api-py/`:

```env
HOST=0.0.0.0
PORT=3000
```

### Como executar

```bash
cd japanese-ocr-api-py
python -m venv .venv
.venv\Scripts\activate        # Windows
# source .venv/bin/activate   # Linux/macOS
pip install -r requirements.txt
python main.py
```

A API estará disponível em `http://localhost:3000`.

---

## Modelo

O modelo CNN foi treinado em 3.755 kanji e exportado no formato ONNX com quantização. Os arquivos ficam em `japanese-ocr-api-py/src/ai_model/` e **não são versionados** (`.gitignore`).

| Arquivo | Descrição |
|---|---|
| `best_cnn_model.onnx` | Grafo de inferência |
| `best_cnn_model.onnx.data` | Pesos do modelo (~9 MB) |
| `classes.json` | Mapeamento índice → kanji |
| `meaning.json` | Kanji → significado em inglês |

---

## Requisitos

| Componente | Versão mínima |
|---|---|
| Flutter | 3.x |
| Dart | 3.x |
| Python | 3.10+ |
