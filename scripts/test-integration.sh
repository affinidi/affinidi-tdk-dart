#!/bin/bash
set -eu -o pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ ! -d "$ROOT_DIR" ]; then
  echo "error: workspace root directory not found: $ROOT_DIR" >&2
  exit 1
fi

if [ ! -f "$ROOT_DIR/.env" ]; then
  echo "error: missing $ROOT_DIR/.env (integration tests require env vars)" >&2
  exit 1
fi

if ! command -v melos >/dev/null 2>&1; then
  echo "error: melos not found in PATH" >&2
  exit 1
fi

cd "$ROOT_DIR"

echo "Running integration tests with env variables:"
grep -E '^[A-Za-z_][A-Za-z0-9_]*=' ".env" | cut -d= -f1 | sed 's/^/ - /'

set -a
# shellcheck source=/dev/null
. ".env"
set +a

melos exec --scope="*integration_tests*" -- "dart test --concurrency=1 --chain-stack-traces"
