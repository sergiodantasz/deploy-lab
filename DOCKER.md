# Docker

Below are useful Docker commands and what they do.

## Container listing

- `docker ps`
  Lists running containers.

- `docker ps -a`
  Lists all containers (running + stopped).

- `docker ps -q`
  Shows only container IDs (quiet mode).

- `docker ps -aq`
  Shows IDs of all containers (very useful for scripting / bulk removal).

## Container lifecycle

- `docker start <container>`
  Starts an existing stopped container.

- `docker stop <container>`
  Gracefully stops a running container.

- `docker restart <container>`
  Stops and then starts the container.

- `docker kill <container>`
  Force-stops the container immediately.

- `docker rm <container>`
  Removes a stopped container.

- `docker rm -f <container>`
  Force-removes a container (even if running).

## Running containers

- `docker run <image>`
  Creates and starts a container from an image.

### Common flags

- `docker run -it <image>`
  Interactive terminal (`-i` keeps stdin open, `-t` allocates a pseudo-TTY).

- `docker run -d <image>`
  Runs the container in detached or background mode.

- `docker run --name mycontainer <image>`
  Assigns a custom container name.

- `docker run -p 8080:80 <image>`
  Maps host port to container port (host:container).

- `docker run --rm <image>`
  Automatically removes the container after it stops.

## Logs and inspection

- `docker logs <container>`
  Shows container logs.

- `docker logs -f <container>`
  Follows logs in real time.

- `docker inspect <container>`
  Shows detailed container information in JSON.

- `docker stats`
  Displays live CPU and memory usage.

## Executing commands inside containers

- `docker exec -it <container> bash`
  Opens a bash shell inside a running container.

- `docker exec <container> <command>`
  Runs a command inside the container.

## Images

- `docker images`
  Lists local images.

- `docker pull <image>`
  Downloads an image from a registry.

- `docker rmi <image>`
  Removes an image.

## Building images

- `docker build .`
  Builds an image from the `Dockerfile` in the current directory.

- `docker build -t myimage .`
  Builds and assigns a name and tag to the image.

- `docker build -t myimage:1.0 .`
  Builds and tags the image with a specific version.

- `docker build -f Dockerfile.dev .`
  Uses a custom Dockerfile.

- `docker build --no-cache .`
  Forces rebuilding everything (ignores cached layers).

- `docker build --pull .`
  Always pulls the latest base image before building.

### Build context

```bash
docker build .
```

The `.` specifies the build context.

It means Docker uses the current directory as the build context, and only files inside this directory (and its subdirectories) can be accessed during the build (for example via `COPY` or `ADD`).

Example:

```bash
docker build -t myapp ./backend
```

Here the context is `./backend`.

### Tagging after build

You can also tag later:

```bash
docker tag myimage myrepo/myimage:latest
```

### Typical real workflow

Build image:

```bash
docker build -t myapi .
```

Run container:

```bash
docker run -p 8000:8000 myapi
```

## Cleanup shortcuts

Remove all stopped containers:

```
docker container prune
```

Remove unused dangling images:

```
docker image prune
```

Remove all images not used by any container:

```
docker image prune -a
```

Remove everything unused:

```
docker system prune
```

## Useful scripting tricks

Remove all containers:

```
docker rm $(docker ps -aq)
```

Stop all running containers:

```
docker stop $(docker ps -q)
```

## Docker Compose

Docker Compose is used to define and run multi-container applications using a `compose.yaml` (or `docker-compose.yaml`) file.

### Starting services

- `docker compose up`
  Creates and starts all services.

- `docker compose up -d`
  Starts services in detached/background mode.

- `docker compose up --build`
  Builds images before starting containers.

### Stopping services

- `docker compose stop`
  Stops running services (containers remain).

- `docker compose down`
  Stops and removes containers, networks, and default resources.

- `docker compose down -v`
  Same as above, but also removes volumes.

### Viewing status

- `docker compose ps`
  Lists compose-managed containers.

- `docker compose logs`
  Shows logs from all services.

- `docker compose logs -f`
  Follows logs in real time.

- `docker compose top`
  Displays running processes.

### Running commands

- `docker compose exec <service> bash`
  Opens a shell inside a running service container.

- `docker compose exec <service> <command>`
  Runs a command inside a service container.

- `docker compose run <service> <command>`
  Runs a one-off command in a new container.

### Building images

- `docker compose build`
  Builds images for services.

- `docker compose build --no-cache`
  Forces rebuilding without cache.

### Pulling images

- `docker compose pull`
  Pulls images defined in the compose file.

### Typical workflow

Start project:

```bash
docker compose up -d
```

Check logs:

```bash
docker compose logs -f
```

Stop and clean:

```bash
docker compose down
```
