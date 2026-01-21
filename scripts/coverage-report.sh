#!/bin/bash
set -eu -o pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT_DIR/coverage"
OUT_FILE="$OUT_DIR/lcov.info"

if [ ! -d "$ROOT_DIR" ]; then
  echo "error: workspace root directory not found: $ROOT_DIR" >&2
  exit 1
fi

if [ ! -d "$ROOT_DIR/packages" ]; then
  echo "error: missing $ROOT_DIR/packages directory" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

# Aggregate all package coverage reports into a single lcov file.
find "$ROOT_DIR/packages" -name "lcov.info" -path "*/coverage/lcov.info" -exec cat {} + > "$OUT_FILE"

echo "wrote $OUT_FILE"
