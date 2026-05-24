# Infrastructure setup

## Profiles

| Command | Services |
|---------|----------|
| `./scripts/up.sh` | PostgreSQL, Kafka |
| `./scripts/up.sh full` | PostgreSQL, Kafka, Elasticsearch, Kibana, Filebeat |

## Start order

1. Clone this repo and copy `.env.example` to `.env`.
2. Run `./scripts/up.sh` (or `full`).
3. Run `./scripts/healthcheck.sh`.
4. Start [notes-app](https://github.com/WeissbergAA/notes-app) with matching env vars.

## Kibana

1. Open http://localhost:5602
2. **Stack Management → Index Patterns → Create**
3. Pattern: `notes-*`, timestamp: `@timestamp`
4. **Discover** — filter by `correlationId` or `level:error`

## Kafka topics (auto-created)

- `notes.created`
- `notes.updated`
- `notes.deleted`
- `forms.submitted`

## Troubleshooting

- **Port conflict:** change `POSTGRES_PORT` / `KAFKA_PORT` in `.env`.
- **Kafka slow start:** wait 30–60s, re-run `./scripts/healthcheck.sh`.
- **Filebeat (full profile):** requires Docker socket access on macOS Docker Desktop.
