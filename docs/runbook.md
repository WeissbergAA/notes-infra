# Runbook

## PostgreSQL not ready

```bash
docker logs notes-postgres
docker compose -f docker-compose.dev.yml ps
```

## Kafka not ready

```bash
docker logs notes-kafka
docker exec notes-kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list
```

## No logs in Kibana

1. Confirm full profile: `./scripts/up.sh full`
2. Check Elasticsearch: `curl http://localhost:9200/_cat/indices?v`
3. Check Filebeat: `docker logs notes-filebeat`
4. Ensure API logs JSON to stdout with fields: `level`, `correlationId`, `service`

## 401 after login (notes-app)

1. Check `JWT_SECRET` matches between restarts
2. Send header: `Authorization: Bearer <token>`
3. Token expires in 24h by default

## Stop everything

```bash
./scripts/down.sh
# or full:
./scripts/down.sh full
```
