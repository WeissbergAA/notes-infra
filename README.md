# notes-infra

Инфраструктура для учебного проекта **[Notes App](https://github.com/WeissbergAA/notes-app)** — сервиса заметок и форм с JWT-авторизацией, Kafka-событиями и стеком наблюдаемости (логи → Elasticsearch → Kibana).

Этот репозиторий **не содержит прикладного кода**. Здесь только Docker Compose, скрипты запуска и документация по окружению. Код приложения живёт в отдельном репозитории [`notes-app`](https://github.com/WeissbergAA/notes-app).

> **Запуск всего стека:** сначала этот репо → затем [QUICKSTART notes-app](https://github.com/WeissbergAA/notes-app/blob/main/docs/QUICKSTART.ru.md)

---

## Зачем нужен этот проект

Notes App задуман как **pet-project для изучения DevOps-практик**:

- разделение **инфраструктуры** и **приложения** на два GitHub-репозитория;
- поднятие окружения через **Docker Compose**;
- работа с **PostgreSQL**, **Kafka**, **ELK** (Elasticsearch + Kibana + Filebeat);
- явная передача настроек между репо через **переменные окружения** (`DATABASE_URL`, `KAFKA_BROKERS` и т.д.);
- healthcheck-скрипты и CI для валидации compose-файлов.

**notes-infra** — это «platform-team»: поднимает базу, очередь и (опционально) стек логов. **notes-app** подключается к уже запущенным сервисам.

---

## Что входит в стек

| Сервис | Назначение | Порт (по умолчанию) |
|--------|------------|---------------------|
| **PostgreSQL 16** | Пользователи, заметки, формы, audit-события | `5433` |
| **Kafka 3.7 (KRaft)** | Асинхронные доменные события | `9093` |
| **Kafka UI** | Web-UI для топиков и сообщений | `8080` |
| **Elasticsearch 8** | Хранение JSON-логов | `9200` |
| **Kibana 8** | UI для поиска и анализа логов | `5602` |
| **Filebeat 8** | Сбор логов из Docker-контейнеров | — |

Порты **5433** и **9093** выбраны намеренно — чтобы не конфликтовать с другими локальными проектами (стандартные 5432/9092 часто заняты).

---

## Профили запуска

### Dev-профиль (минимальный, для ежедневной разработки)

Поднимает только **PostgreSQL + Kafka**. Быстрый старт, меньше RAM.

```bash
./scripts/up.sh
./scripts/healthcheck.sh
```

### Full-профиль (полный стек с логами)

Дополнительно поднимает **Elasticsearch + Kibana + Filebeat**. Нужен для практики с Kibana и трассировкой запросов по `correlationId`.

```bash
./scripts/up.sh full
./scripts/healthcheck.sh full
```

---

## Требования

- **macOS / Linux / Windows** с Docker Desktop
- **Docker Compose v2** (команда `docker compose`, не `docker-compose`)
- **Git**
- Свободные порты: `5433`, `9093` (dev) или также `9200`, `5602` (full)

Проверка Docker:

```bash
docker info
docker compose version
```

---

## Быстрый старт

```bash
git clone git@github.com:WeissbergAA/notes-infra.git
cd notes-infra
cp .env.example .env
./scripts/up.sh
./scripts/healthcheck.sh
```

После этого переходи в **notes-app** → `npm run setup` → `npm run dev`.

| Сервис | URL после старта |
|--------|------------------|
| PostgreSQL | `localhost:5433` |
| Kafka | `localhost:9093` |
| Kafka UI | http://localhost:8080 |

### 1. Клонировать репозиторий (подробно)

```bash
git clone git@github.com:WeissbergAA/notes-infra.git
cd notes-infra
```

### 2. Создать файл окружения

```bash
cp .env.example .env
```

При необходимости отредактируй `.env` (порты, пароли).

### 3. Запустить инфраструктуру

```bash
chmod +x scripts/*.sh   # только при первом клоне, если скрипты не исполняемые
./scripts/up.sh
./scripts/healthcheck.sh
```

Если healthcheck прошёл — Postgres и Kafka готовы.

### 4. Подключить notes-app

В репозитории [`notes-app`](https://github.com/WeissbergAA/notes-app) в `.env` укажи:

```env
DATABASE_URL=postgresql://notes:notes@localhost:5433/notes?schema=public
KAFKA_BROKERS=localhost:9093
```

---

## Структура репозитория

```
notes-infra/
├── docker-compose.dev.yml    # Postgres + Kafka (dev-профиль)
├── docker-compose.yml        # Полный стек (include dev + ELK)
├── .env.example              # Шаблон переменных окружения
├── filebeat/
│   └── filebeat.yml          # Конфиг сбора логов
├── scripts/
│   ├── up.sh                 # Запуск стека
│   ├── down.sh               # Остановка стека
│   └── healthcheck.sh        # Ожидание готовности сервисов
├── docs/
│   ├── setup.md              # Доп. инструкции (Kibana, topics)
│   └── runbook.md            # Типовые проблемы и решения
└── .github/workflows/
    └── validate.yml          # CI: validate compose + shellcheck
```

---

## Переменные окружения (.env)

| Переменная | Описание | Значение по умолчанию |
|------------|----------|------------------------|
| `COMPOSE_PROJECT_NAME` | Префикс имён контейнеров | `notes` |
| `POSTGRES_USER` | Пользователь БД | `notes` |
| `POSTGRES_PASSWORD` | Пароль БД | `notes` |
| `POSTGRES_DB` | Имя базы | `notes` |
| `POSTGRES_PORT` | Порт на хосте | `5433` |
| `KAFKA_PORT` | Порт Kafka на хосте | `9093` |
| `KAFKA_UI_PORT` | Порт Kafka UI | `8080` |
| `ELASTICSEARCH_PORT` | Порт Elasticsearch | `9200` |
| `KIBANA_PORT` | Порт Kibana | `5602` |

---

## Полезные команды

### Запуск и остановка

```bash
# Dev-профиль
./scripts/up.sh
./scripts/down.sh

# Full-профиль
./scripts/up.sh full
./scripts/down.sh full
```

### Проверка состояния контейнеров

```bash
docker compose -f docker-compose.dev.yml ps
docker logs notes-postgres
docker logs notes-kafka
```

### Подключение к PostgreSQL

```bash
docker exec -it notes-postgres psql -U notes -d notes
```

### Список Kafka-топиков

```bash
docker exec notes-kafka kafka-topics.sh --bootstrap-server localhost:9092 --list
```

### Kafka UI

После `./scripts/up.sh` открой http://localhost:8080 — просмотр топиков, сообщений и consumer groups без CLI.

Ожидаемые топики (создаются автоматически при первой публикации из API):

- `notes.created`
- `notes.updated`
- `notes.deleted`
- `forms.submitted`

---

## Kibana (full-профиль)

1. Запусти `./scripts/up.sh full`
2. Открой http://localhost:5602
3. **Stack Management → Index Patterns → Create index pattern**
4. Pattern: `notes-*`, поле времени: `@timestamp`
5. **Discover** — фильтруй по `correlationId`, `level:error`, `service:notes-api`

Логи API и consumer пишутся в stdout в формате JSON. Filebeat забирает их из Docker и отправляет в Elasticsearch.

---

## Связь с notes-app

```mermaid
flowchart LR
    subgraph infra [notes-infra]
        PG[(PostgreSQL)]
        K[Kafka]
        ES[(Elasticsearch)]
        KB[Kibana]
    end

    subgraph app [notes-app]
        API[notes-api]
        CON[notes-consumer]
        WEB[notes-web]
    end

    API --> PG
    API --> K
    CON --> K
    CON --> PG
    WEB --> API
    API --> ES
    CON --> ES
    ES --> KB
```

**Порядок запуска всегда один:**

1. `notes-infra` — `./scripts/up.sh`
2. `notes-app` — миграции БД → API → consumer → web

---

## CI/CD

При push/PR в `main` GitHub Actions:

- валидирует `docker compose config` для dev и full профилей;
- прогоняет `shellcheck` для скриптов в `scripts/`.

---

## Типовые проблемы

| Проблема | Решение |
|----------|---------|
| `Cannot connect to Docker daemon` | Запусти Docker Desktop |
| Порт 5433 занят | Измени `POSTGRES_PORT` в `.env` и обнови `DATABASE_URL` в notes-app |
| Kafka долго стартует | Подожди 30–60 сек, повтори `./scripts/healthcheck.sh` |
| Нет логов в Kibana | Убедись, что запущен `full`-профиль; проверь `docker logs notes-filebeat` |
| Конфликт с рабочим Docker | Используй другие порты в `.env` |

Подробнее: [docs/runbook.md](docs/runbook.md)

---

## Документация

- [docs/setup.md](docs/setup.md) — дополнительные инструкции по настройке
- [docs/runbook.md](docs/runbook.md) — runbook для инцидентов
- [notes-app README](https://github.com/WeissbergAA/notes-app) — запуск приложения

---

## Лицензия и статус

Учебный проект. Используй для практики DevOps, не как production-ready решение без доработок (секреты, бэкапы, мониторинг, HA).
