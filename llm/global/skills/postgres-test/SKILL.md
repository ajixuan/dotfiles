---
name: postgres-test
description: Use when running any postgresql-related work inside this container — integration tests against a real database, schema migrations, ad-hoc SQL, or reproducing a bug that needs a live postgres. A shared postgres container is already running on the docker network; connect to it via the PG* env vars instead of attempting docker-in-docker, pg_ctl, embedded-postgres, or a fresh postgres process.
---

# Shared postgres sidecar

A `postgres:17-alpine` container named `claude-postgres` runs alongside this claude container on the `claude-net` docker network. It is started by `run-claude.sh` via `docker-compose.yml` and persists across sessions (named volume `claude-postgres-data`).

Docker-in-docker is **not available** in this container. Do not try to `docker run postgres`, `docker compose up`, or start a local postgres with `pg_ctl` / `initdb` / `apt install postgresql`. Use the sidecar.

## Connection

These env vars are already exported in the shell:

| Var          | Value      |
| ------------ | ---------- |
| `PGHOST`     | `postgres` |
| `PGPORT`     | `5432`     |
| `PGUSER`     | `claude`   |
| `PGPASSWORD` | `claude`   |
| `PGDATABASE` | `claude`   |

`claude` is a **superuser** — it can `CREATE DATABASE`, `CREATE EXTENSION`, `CREATE ROLE`, etc.

`psql` is installed in this container. With the env vars set, a bare `psql` connects.

## Verifying it works

```bash
psql -c 'select version();'
```

If that fails with "could not translate host name", the sidecar isn't reachable — check with `getent hosts postgres` and fall back to telling the user their compose stack may not be up.

## Recommended pattern for tests

Create an ephemeral database per test run so you don't pollute the default `claude` db and so parallel runs don't collide:

```bash
DB="test_$(date +%s)_$$"
createdb "$DB"
trap 'dropdb --if-exists "$DB"' EXIT
PGDATABASE="$DB" <run migrations / tests>
```

For libraries that take a DSN:

```
postgres://claude:claude@postgres:5432/<dbname>
```

Read credentials from the `PG*` env vars — do not hardcode them into committed test files.

## Migrations / schema tooling

Tools like `migrate`, `sqlx`, `alembic`, `goose`, `flyway`, `dbmate`, etc. all respect either the `PG*` env vars or a DSN. Point them at the shared container; do not have them spin up their own postgres.

## What not to do

- Do not `docker run`, `docker compose up`, or otherwise try to start containers from inside this container — the docker socket is not mounted.
- Do not install postgres via apt and run it locally (`pg_ctlcluster`, `service postgresql start`) — wasted time, and it will not match the sidecar version.
- Do not use `pg_tmp`, `embedded-postgres`, `testcontainers`, or similar — they all require either docker-in-docker or a local postgres build.
- Do not `DROP DATABASE claude` or `DROP ROLE claude` — that's the default database/user.
- Do not publish the port or expose the sidecar outside `claude-net` — it has no host-side binding on purpose.
