# Deploy Lab

A personal reference repository for notes and experiments on deploying applications to Linux-based systems. It includes a minimal Django/DRF example app, Docker Compose stacks for development and production, server provisioning and hardening steps, and a full continuous deployment (CD) pipeline using GitHub Actions.

Use this repo as a step-by-step guide: start with the server and Docker setup, then run the app locally or on a VM, and finally wire GitHub Actions to deploy on every push to `main`.

## Guides

The following documents form the main path to understand and run the project: the demo application, how to prepare the server, and how to set up continuous deployment. Read them in this order when you are setting things up from scratch.

### Application

[APPLICATION.md](APPLICATION.md) describes the demo application: a small REST API (Django + Django REST Framework) that simulates a task list. It documents the API endpoints, the health check used for monitoring and load balancers, and example `curl` usage. It also explains how to **run the app locally with Docker**: environment setup, Nginx config and certificates via `./scripts/setup.sh`, and starting the stack with `docker compose` (including `--watch` for development so code changes sync and the app restarts automatically.

### Server

[SERVER.md](SERVER.md) covers the **production server** side: VM requirements (e.g. Ubuntu 24.04, open ports 22/80/443), SSH key and client config for access, firewall (UFW), and optional hardening (e.g. Fail2ban, non-root user, `/deploy-lab` directory and permissions). Follow this before deploying the application so the host is secure and ready for Docker and Nginx.

### Deploy

[DEPLOY.md](DEPLOY.md) walks through **continuous deployment (CD)** from an empty server to a live app. It assumes the server is already prepared (see [SERVER.md](SERVER.md)) and covers: marking the repo as a safe directory for Git, configuring GitHub access via SSH (deploy key), environment variables and `.env`, generating Nginx config and dummy SSL for development, running the stack in development and production (Compose files and commands), TLS with Let’s Encrypt/Certbot, creating the `deploy` user and the SSH key used by GitHub Actions, sudoers so `deploy` can run only the deploy command, the GitHub Actions workflow that runs on push to `main`, and how to test and verify the pipeline. Finish here to have push-to-deploy working end-to-end.

## Docker (command reference)

[DOCKER.md](DOCKER.md) is a reference of useful Docker and Docker Compose commands: listing and managing containers, images, volumes, and networks, plus examples of building and running the app with Compose. Handy when you need to inspect, restart, or clean up resources. It is not required to follow the Application → Server → Deploy flow; use it as needed.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for the full text.
