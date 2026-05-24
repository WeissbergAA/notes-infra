#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Created .env from .env.example"
fi

PROFILE="${1:-dev}"

if [[ "$PROFILE" == "full" ]]; then
  docker compose --env-file .env up -d
else
  docker compose --env-file .env -f docker-compose.dev.yml up -d
fi

echo "Stack started (profile: $PROFILE)"
