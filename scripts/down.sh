#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PROFILE="${1:-dev}"

if [[ "$PROFILE" == "full" ]]; then
  docker compose --env-file .env down
else
  docker compose --env-file .env -f docker-compose.dev.yml down
fi

echo "Stack stopped (profile: $PROFILE)"
