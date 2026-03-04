#!/bin/bash
set -eu -o pipefail

# How to run it from the repo root:
#   chmod +x scripts/create-token.sh
#   ./scripts/create-token.sh
# Or set the environment explicitly:
#   AFFINIDI_CLI_ENVIRONMENT=dev ./scripts/create-token.sh
# If AFFINIDI_CLI_ENVIRONMENT is not provided, "prod" is used by default.
# The script runs in sequence: start, list projects, select project, create token.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ ! -d "$ROOT_DIR" ]; then
  echo "error: workspace root directory not found: $ROOT_DIR" >&2
  exit 1
fi

if ! command -v affinidi >/dev/null 2>&1; then
  echo "error: affinidi CLI not found in PATH" >&2
  exit 1
fi

ENVIRONMENT="${AFFINIDI_CLI_ENVIRONMENT:-dev}"

AFFINIDI_CLI_ENVIRONMENT="$ENVIRONMENT" affinidi start

echo "Listing projects..."
AFFINIDI_CLI_ENVIRONMENT="$ENVIRONMENT" affinidi project list-projects

echo ""
read -r -p "Enter project ID to select: " PROJECT_ID

if [ -z "$PROJECT_ID" ]; then
  echo "error: project ID is required" >&2
  exit 1
fi

AFFINIDI_CLI_ENVIRONMENT="$ENVIRONMENT" affinidi project select-project -i "$PROJECT_ID"
echo "selected project: $PROJECT_ID in environment: $ENVIRONMENT"

AFFINIDI_CLI_ENVIRONMENT="$ENVIRONMENT" affinidi token create-token

