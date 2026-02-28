# Deploy Lab

Personal reference for deploying applications to Linux-based systems. Includes a minimal Django/DRF API, Docker Compose stacks for development and production, server provisioning and hardening steps, tests (pytest), CI and CD pipelines using GitHub Actions.

Use this repo as a step-by-step guide: start with the server setup, run the app locally or on a VM, run tests, then wire GitHub Actions so CI runs on every push/PR and deploy runs on `main` only after CI passes.

## Guides

### Application

[APPLICATION.md](APPLICATION.md) — Describes the demo REST API (task list), its endpoints, the health check used for monitoring, and how to run tests. Explains how to run locally with Docker: environment setup via `./scripts/setup.sh`, Nginx config and certificates, and starting the stack with `docker compose` (including `--watch` for development so code changes sync and the app restarts automatically).

### Server

[SERVER.md](SERVER.md) — Covers the production server: VM requirements (Ubuntu 24.04, ports 22/80/443), SSH key and client config, UFW firewall, Fail2ban for SSH protection, and Docker install. Also covers the `/deploy-lab` directory and permissions. Follow this before deploying so the host is secure and ready.

### Deploy

[DEPLOY.md](DEPLOY.md) — Walks through CD from an empty server to a live app. Covers Git safe directory, deploy key for GitHub, environment variables and `.env`, Nginx config and dummy SSL for development, running the stack in dev and production, TLS with Let's Encrypt/Certbot, the `deploy` user and restricted SSH key for GitHub Actions, and the **Build and Deploy** workflow: the `ci` job (lint, format, Django check, migrations, tests) runs on push/PR; the `deploy` job runs on `main` only after CI passes.

### Docker

[DOCKER.md](DOCKER.md) — Reference of useful Docker and Compose commands: containers, images, volumes, networks. Handy for inspecting, restarting, or cleaning up. Not required for the main flow; use as needed.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for the full text.
