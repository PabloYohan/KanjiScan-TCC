# KanjiScan — Japanese OCR API

API REST para reconhecimento de caracteres japoneses a partir de imagens. Recebe uma imagem via upload multipart, aplica um pipeline de pré-processamento e executa inferência com um modelo CNN exportado em ONNX, retornando o caractere identificado, a confiança da predição e seu significado em português.

O modelo reconhece **215 classes**: hiragana, katakana e os kanjis do nível JLPT N5.

## Tecnologias

- **FastAPI** ^0.115 — framework web assíncrono
- **Uvicorn** — servidor ASGI
- **ONNX Runtime** ^1.20 — inferência do modelo CNN
- **OpenCV** (headless) — limiarização adaptativa e morfologia
- **Pillow** — decodificação e rotação de imagens
- **PyTorch** — cálculo de softmax sobre os logits
- **Pydantic Settings** — configuração via variáveis de ambiente

> O campo `meaning` da resposta é retornado em **português**.

## Estrutura de pastas

```
japanese-ocr-api-py/
├── main.py                       # App FastAPI, CORS, registro de rotas
├── src/
│   ├── config/settings.py        # Configurações (porta, host, tamanho máximo de arquivo)
│   ├── routes/
│   │   ├── health.py             # GET  /api/health
│   │   └── predict.py            # POST /api/predict
│   ├── schemas/responses.py      # Modelos Pydantic de resposta
│   ├── services/
│   │   ├── inference.py          # Sessão ONNX, TTA, softmax, mapeamento de classes
│   │   └── image_processing.py   # Pipeline de pré-processamento em 10 etapas
│   ├── utils/response.py         # Helpers success_response / error_response
│   └── ai_model/                 # Não versionado — veja "Modelo" abaixo
│       ├── best_cnn_model.onnx
│       ├── best_cnn_model.onnx.data
│       ├── classes.json
│       └── meaning.json
├── images_test/                  # Saídas de debug do pré-processamento
├── requirements.txt
└── .env.example
```

## Pré-requisitos

- Python 3.10+
- `pip` ou `uv`
- Arquivos do modelo na pasta `src/ai_model/` (ver seção abaixo)

## Instalação

```bash
# 1. Crie e ative o ambiente virtual
python -m venv .venv
source .venv/bin/activate      # Linux/macOS
.venv\Scripts\activate         # Windows

# 2. Instale as dependências
pip install -r requirements.txt
```

## Configuração

Copie o arquivo de exemplo e ajuste conforme necessário:

```bash
cp .env.example .env
```

Variáveis disponíveis:

| Variável | Padrão | Descrição |
|---|---|---|
| `PORT` | `3000` | Porta em que o servidor irá escutar |
| `HOST` | `0.0.0.0` | Interface de rede |
| `ENVIRONMENT` | `development` | `development` habilita hot-reload |
| `MAX_FILE_SIZE` | `5242880` | Tamanho máximo de upload em bytes (5 MB) |

## Modelo

Os arquivos do modelo não são versionados no repositório. Coloque-os manualmente em `src/ai_model/`:

| Arquivo | Descrição |
|---|---|
| `best_cnn_model.onnx` | Grafo ONNX do modelo CNN |
| `best_cnn_model.onnx.data` | Pesos do modelo (~9 MB) |
| `classes.json` | Mapeamento índice → caractere (215 classes: hiragana, katakana e JLPT N5) |
| `meaning.json` | Mapeamento kanji → significado em português |

## Executando

```bash
python main.py
```

Em modo `development` o servidor recarrega automaticamente ao detectar mudanças nos arquivos fonte.

Para executar diretamente com uvicorn:

```bash
uvicorn main:app --host 0.0.0.0 --port 3000 --reload
```

## Endpoints

### `GET /api/health`

Verifica se o serviço está operacional.

**Resposta 200:**
```json
{
  "success": true,
  "data": {
    "status": "ok",
    "timestamp": "2024-01-01T12:00:00.000Z",
    "uptime": 42.3
  }
}
```

---

### `POST /api/predict`

Recebe uma imagem e retorna o kanji reconhecido.

**Request:** `multipart/form-data`

| Campo | Tipo | Descrição |
|---|---|---|
| `image` | `file` | Imagem do kanji (JPEG, PNG, WebP ou BMP, máx. 5 MB) |

**Resposta 200:**
```json
{
  "success": true,
  "data": {
    "label": "楷",
    "confidence": 0.9645,
    "meaning": "método de escrita quadrada e correta"
  }
}
```

**Erros possíveis:**

| Código HTTP | Código de erro | Causa |
|---|---|---|
| 413 | `FILE_TOO_LARGE` | Arquivo excede `MAX_FILE_SIZE` |
| 415 | `INVALID_FILE_TYPE` | Formato não suportado |
| 500 | `MODEL_NOT_FOUND` | Arquivos do modelo ausentes |
| 500 | `INTERNAL_ERROR` | Erro inesperado durante inferência |

## Pipeline de pré-processamento

A função `preprocess_image` em [src/services/image_processing.py](src/services/image_processing.py) transforma a imagem bruta em um tensor `[1, 1, 64, 64]` em 10 etapas:

1. Decodificação, auto-orientação EXIF e conversão para escala de cinza
2. Redimensionamento para no máximo 512 × 512 px
3. Desfoque Gaussiano (raio 0,7)
4. CLAHE — equalização adaptativa de histograma (clipLimit 2,0, tiles 8 × 8)
5. Limiarização adaptativa Gaussiana (invertida — traços brancos, fundo preto)
6. Fechamento morfológico (kernel 2 × 2) para unir fragmentos de traços
7. Análise de componentes conectados — remoção de ruído por área
8. Recorte pelo bounding box do caractere com margem de 8 px
9. Centralização em canvas quadrado com padding de 12 %
10. Redimensionamento final para 64 × 64 e normalização para float32 [0, 1]

Imagens de debug de cada etapa são salvas em `images_test/` durante o desenvolvimento.
