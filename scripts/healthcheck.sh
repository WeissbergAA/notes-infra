#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -f .env ]]; then
  cp .env.example .env
fi

# shellcheck disable=SC1091
source .env

PROFILE="${1:-dev}"
MAX_ATTEMPTS=30
ATTEMPT=0

wait_for_postgres() {
  echo "Waiting for PostgreSQL on port ${POSTGRES_PORT}..."
  until docker exec notes-postgres pg_isready -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" >/dev/null 2>&1; do
    ATTEMPT=$((ATTEMPT + 1))
    if [[ $ATTEMPT -ge $MAX_ATTEMPTS ]]; then
      echo "PostgreSQL is not ready"
      exit 1
    fi
    sleep 2
  done
  echo "PostgreSQL is ready"
}

wait_for_kafka() {
  echo "Waiting for Kafka on port ${KAFKA_PORT}..."
  ATTEMPT=0
  until docker exec notes-kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list >/dev/null 2>&1; do
    ATTEMPT=$((ATTEMPT + 1))
    if [[ $ATTEMPT -ge $MAX_ATTEMPTS ]]; then
      echo "Kafka is not ready"
      exit 1
    fi
    sleep 3
  done
  echo "Kafka is ready"
}

wait_for_elasticsearch() {
  if [[ "$PROFILE" != "full" ]]; then
    return 0
  fi
  echo "Waiting for Elasticsearch on port ${ELASTICSEARCH_PORT}..."
  ATTEMPT=0
  until curl -sf "http://localhost:${ELASTICSEARCH_PORT}/_cluster/health" >/dev/null 2>&1; do
    ATTEMPT=$((ATTEMPT + 1))
    if [[ $ATTEMPT -ge $MAX_ATTEMPTS ]]; then
      echo "Elasticsearch is not ready"
      exit 1
    fi
    sleep 3
  done
  echo "Elasticsearch is ready"
}

wait_for_postgres
wait_for_kafka
wait_for_elasticsearch

echo "All services are healthy"
