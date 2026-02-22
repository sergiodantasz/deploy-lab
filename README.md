# Deploy Lab

A personal reference repository for notes and experiments on deploying applications to Linux-based systems.

## Application

This project contains a small demonstration web API built with **Django** and **Django REST Framework (DRF)**.

The application simulates a simple task management service, allowing clients to create, list, update, and delete tasks through a RESTful interface. It is intentionally minimal and designed primarily for learning, testing deployments, and experimenting with infrastructure setups.

Project dependencies are managed using **uv**, which is used to install, lock, and synchronize the Python environment.

### API

| Action        | HTTP method | Endpoint           |
| ------------- | ----------- | ------------------ |
| List tasks    | `GET`       | `/api/tasks/`      |
| Create task   | `POST`      | `/api/tasks/`      |
| Retrieve task | `GET`       | `/api/tasks/{id}/` |
| Replace task  | `PUT`       | `/api/tasks/{id}/` |
| Update task   | `PATCH`     | `/api/tasks/{id}/` |
| Delete task   | `DELETE`    | `/api/tasks/{id}/` |

### Health check

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

### Usage example

Below are example `curl` requests for a local instance running on `localhost`.

#### Create a task

```bash
curl -X POST http://localhost:8000/api/tasks/ \
  -H "Content-Type: application/json" \
  -d '{"title":"Study Django","done":false}'
```

#### List all tasks

```bash
curl http://localhost:8000/api/tasks/
```

#### Retrieve a single task

```bash
curl http://localhost:8000/api/tasks/1/
```

#### Update a task partially

```bash
curl -X PATCH http://localhost:8000/api/tasks/1/ \
  -H "Content-Type: application/json" \
  -d '{"done":true}'
```

#### Replace a task completely

```bash
curl -X PUT http://localhost:8000/api/tasks/1/ \
  -H "Content-Type: application/json" \
  -d '{"title":"Study DRF","done":true}'
```

#### Delete a task

```bash
curl -X DELETE http://localhost:8000/api/tasks/1/
```

#### Check service health

```bash
curl http://localhost:8000/health/
```
