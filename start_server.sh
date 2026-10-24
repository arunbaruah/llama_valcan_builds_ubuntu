#!/bin/bash
set -e

# Get directory where this script is located
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODEL_DIR="$CORE_DIR/../model"
CONFIG_FILE="$CORE_DIR/runtime.json"

# Check if runtime.json exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "[ERROR] runtime.json not found in $CORE_DIR"
    exit 1
fi

# Read configuration values from runtime.json using python3
CPU_THREADS=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('cpu_threads', 6))")
CTX_SIZE=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('context_size', 8192))")
BATCH_SIZE=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('batch_size', 2048))")
UBATCH_SIZE=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('ubatch_size', 2048))")
GPU_LAYERS=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('gpu_layers', 99))")
CACHE_TYPE_K=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('cache_type_k', 'f16'))")
CACHE_TYPE_V=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('cache_type_v', 'f16'))")
MODEL_NAME=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('modelFileName', 'gemma-4-E2B-it-Q4_K_M.gguf'))")
PORT=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('MAIN_LLM_PORT', 8080))")

MODEL_FILE="$MODEL_DIR/$MODEL_NAME"
HOST="0.0.0.0"

echo "===================================================="
echo "Starting AxoLabs Main LLM Server (Linux Desktop)"
echo "===================================================="
echo "Engine Path:  $CORE_DIR/bin/llama-server"
echo "Model Path:   $MODEL_FILE"
echo "Port:         $PORT"
echo "Threads:      $CPU_THREADS"
echo "Context Size: $CTX_SIZE"
echo "===================================================="

# Check if executable exists
if [ ! -f "$CORE_DIR/bin/llama-server" ]; then
    echo "[ERROR] llama-server executable not found in $CORE_DIR/bin/"
    exit 1
fi

# Check if model exists
if [ ! -f "$MODEL_FILE" ]; then
    echo "[ERROR] Model file not found: $MODEL_FILE"
    exit 1
fi

# Launch the server (LD_LIBRARY_PATH points to the lib folder where .so plugins reside)
LD_LIBRARY_PATH="$CORE_DIR/lib:$LD_LIBRARY_PATH" \
"$CORE_DIR/bin/llama-server" \
  -m "$MODEL_FILE" \
  -c "$CTX_SIZE" \
  -b "$BATCH_SIZE" \
  -ub "$UBATCH_SIZE" \
  -t "$CPU_THREADS" \
  -ngl "$GPU_LAYERS" \
  -ctk "$CACHE_TYPE_K" \
  -ctv "$CACHE_TYPE_V" \
  --port "$PORT" \
  --host "$HOST" \
  --metrics \
  --embedding \
  --pooling mean