# Application

This project contains a small demonstration web API built with **Django** and **Django REST Framework (DRF)**.

The application simulates a simple task management service, allowing clients to create, list, update, and delete tasks through a RESTful interface. It is intentionally minimal and designed primarily for learning, testing deployments, and experimenting with infrastructure setups.

Project dependencies are managed using **uv** to install, lock, and synchronize the Python environment.

## API

| Action        | HTTP method | Endpoint           |
| ------------- | ----------- | ------------------ |
| List tasks    | `GET`       | `/api/tasks/`      |
| Create task   | `POST`      | `/api/tasks/`      |
| Retrieve task | `GET`       | `/api/tasks/{id}/` |
| Replace task  | `PUT`       | `/api/tasks/{id}/` |
| Update task   | `PATCH`     | `/api/tasks/{id}/` |
| Delete task   | `DELETE`    | `/api/tasks/{id}/` |

## Health check

The service exposes a health check endpoint used to verify whether the application is running correctly and able to access its dependencies (such as the database).

**Endpoint:**

```
GET /health/
```

**Response format:**

```json
{
  "status": "ok",
  "uptime": 123
}
```

**Possible status values:**

- `ok` — the application is healthy and operational
- `error` — one or more internal checks failed (for example, database unavailable)

The `uptime` field represents the number of seconds since the application process started.

This endpoint is intended for monitoring tools, container health checks, load balancers, and deployment verification.

## Run locally with Docker

To run the application on your machine using Docker (app + PostgreSQL + Nginx with a self-signed certificate), copy `.env.example` to `.env` and set `CURRENT_ENV=development`. Adjust other values if needed (e.g. database password). From the project root, run the setup script so Nginx gets the development config and certificates:

```bash
./scripts/setup.sh
```

Then start the stack. For local development, use `--watch` instead of `-d` so that code changes are synced into the container and the app restarts automatically:

```bash
docker compose -f compose.yaml -f compose.dev.yaml up --watch --build
```

Open `https://localhost` in the browser (accept the self-signed cert) or use `curl -k https://localhost/health/`. The API is under `https://localhost/api/` (e.g. `https://localhost/api/tasks/`). The process stays in the foreground and shows logs; press Ctrl+C to stop. If you prefer a detached run without watching, use `up -d --build` instead.

For more detail (verification, production setup), see [DEPLOY.md](DEPLOY.md).

## Usage example

The following are example `curl` requests for a local instance. If you ran the stack with Nginx (see [Run locally with Docker](#run-locally-with-docker)), use `https://localhost` and the paths below (e.g. `https://localhost/api/tasks/`). If the app is exposed directly on port 8000, use `http://localhost:8000` instead.

### Create a task

```bash
curl -X POST http://localhost:8000/api/tasks/ \
  -H "Content-Type: application/json" \
  -d '{"title":"Study Django","done":false}'
```

### List all tasks

```bash
curl http://localhost:8000/api/tasks/
```

### Retrieve a single task

```bash
curl http://localhost:8000/api/tasks/1/
```

### Update a task partially

```bash
curl -X PATCH http://localhost:8000/api/tasks/1/ \
  -H "Content-Type: application/json" \
  -d '{"done":true}'
```

### Replace a task completely

```bash
curl -X PUT http://localhost:8000/api/tasks/1/ \
  -H "Content-Type: application/json" \
  -d '{"title":"Study DRF","done":true}'
```

### Delete a task

```bash
curl -X DELETE http://localhost:8000/api/tasks/1/
```

### Check service health

```bash
curl http://localhost:8000/health/
```
