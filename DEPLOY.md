# Deploy

This document describes the configuration required on the deployment server after it has been provisioned and prepared. The goal is to have a clear, reproducible flow from an empty VM to a working application in both development and production modes.

> [!TIP]
> Before you start, make sure your server is prepared as described in `SERVER.md` (SSH hardening, firewall, Docker/Compose installed, `/deploy-lab` directory and permissions, etc.). This document assumes that all those prerequisites are already in place and focuses only on what is specific to this repository.

## Mark repository as safe in Git

On some environments Git can treat a path as “unsafe”, blocking commands such as `git status` or `git pull`. To avoid these warnings and ensure Git works correctly in `/deploy-lab`, mark the directory as safe on the server:

```bash
# Register /deploy-lab as a safe directory for all users
git config --global --add safe.directory /deploy-lab
```

## Repository access (GitHub over SSH)

Configure read-only access from the server to your GitHub repository using SSH so the server can pull code directly from GitHub.

### Generate an SSH key on the server

On the server, create an SSH key for repository access:

```bash
# Generate an ED25519 key for repository access
ssh-keygen -t ed25519 -C "sergio" -f ~/.ssh/repository

# Print the public key and copy it
cat ~/.ssh/repository.pub
```

### Add the key as a Deploy Key in GitHub

On your local machine, open GitHub in the browser and access the project repository. Using a Deploy Key gives GitHub a way to trust this specific server key without granting full user-level access.

Navigate to **Settings → Deploy keys → Add deploy key**, paste the copied public key, give it a clear, descriptive title (for example, `deploy-lab read-only`), make sure **Allow write access** is **unchecked**, and then click **Add key** to save it.

If you later rotate the server key (for example, after a compromise), remember to remove the old Deploy Key from this page.

### Configure SSH for GitHub on the server

Back on the server, create (or update) the SSH config file so the `git` and `ssh` commands know which key to use when connecting to GitHub.

Create the SSH config file if it does not exist, and then restrict permissions:

```bash
# Create the config file
touch ~/.ssh/config

# Restrict access so only your user can read/write it
chmod 600 ~/.ssh/config
```

Then edit `~/.ssh/config` and add:

```bash
# ~/.ssh/config

Host *
  AddKeysToAgent yes

Host github.com
  HostName github.com
  User git
  Port 22
  IdentityFile ~/.ssh/repository
  IdentitiesOnly yes
```

Add GitHub to `known_hosts` to avoid interactive prompts on first connect:

```bash
ssh-keyscan github.com >> ~/.ssh/known_hosts
```

### Clone the repository into the application directory

Finally, clone the repository into the application directory (assuming the `/deploy-lab` directory already exists and has the correct permissions as described in `SERVER.md`). This is where Docker, Nginx, and the application code will live.

```bash
git clone git@github.com:<your-username>/<your-repo>.git /deploy-lab
cd /deploy-lab
```

## Configure environment variables

Before starting the application, configure the environment variables in a `.env` file used by Docker Compose and the app.

Inside `/deploy-lab`, copy `.env.example` to `.env` and adjust the values as needed:

```bash
# Copy the example file
cp .env.example .env

# Open and edit it
nano .env
```

Key variables (summary):

- **`CURRENT_ENV`**: `development` or `production` (controls which Nginx templates are rendered and how TLS is handled).
- **`DOMAIN`**: public domain used by Nginx and (in production) by Certbot/Let's Encrypt.
- **`EMAIL`**: email used by Let's Encrypt (production only; used for expiry notices etc.).
- **`NGINX_UPSTREAM_SERVICE`**: internal name Nginx uses to reach the app (default: `app` in the Compose network).

> [!NOTE]
> The values in `.env.example` are placeholders. When you copy it, do not keep the defaults in production: replace them with real values (database name/user/password, domain, email, secret key, etc.) and review the rest of the `.env` file to keep related variables consistent.

> [!CAUTION]
> Start with `CURRENT_ENV=development` to validate the full stack with a self-signed certificate before switching to production.

## Generate dummy SSL certificates

In development mode, Nginx uses a self-signed certificate so you can exercise the HTTPS flow without Let's Encrypt.

Make sure `CURRENT_ENV=development` is set in `.env`, then generate the appropriate Nginx configuration:

```bash
./scripts/setup.sh
```

You can check `./nginx/conf.d/dev` to ensure it was generated correctly.

## First run (development)

With `CURRENT_ENV=development`, start the full stack using the base compose file plus the dev override (which adds Nginx and the development TLS configuration):

```bash
docker compose -f compose.yaml -f compose.dev.yaml up -d --build
```

What happens:

1. **PostgreSQL (`psql`)** starts and becomes healthy (ready to accept connections).
2. **App (`deploy-lab`)** starts, runs migrations, and launches Gunicorn.
3. **Nginx** starts and, if `./nginx/certs/dev.crt`/`./nginx/certs/dev.key` do not exist yet, it generates a self-signed certificate (valid for 10 years) and then serves HTTPS.

Traffic flow:

- Host ports 80/443 → Nginx.
- Nginx terminates TLS and proxies requests to the app over the internal Compose network (`app` service).

If any of these containers fail, check logs (see the [Logs and shutdown](#logs-and-shutdown) section below).

### Quick verification

To verify the deployment from the VM itself using `curl`:

```bash
curl -i http://localhost/health/        # HTTP should redirect to HTTPS
curl -iLk http://localhost/health/      # Self-signed cert: use -k
curl -ik https://localhost/health/      # Direct HTTPS (still with -k)
```

To test using the server IP or domain instead of `localhost`:

```bash
curl -iLk http://<your-server-ip-or-domain>/health/
```

### Logs and shutdown

You can access the logs:

```bash
docker compose -f compose.yaml -f compose.dev.yaml logs -f
```

To follow logs from specific services only (for example, `app` and `nginx`):

```bash
docker compose -f compose.yaml -f compose.dev.yaml logs -f app nginx
```

If everything looks good, bring the containers down:

```bash
docker compose -f compose.yaml -f compose.dev.yaml down
```

## Run in production

Once you are satisfied with the development setup, you can move to the production flow using `compose.prod.yaml`.

### Prerequisites

Before you start the production stack:

- Your `DOMAIN` must point to the server public IP (A/AAAA records).
- The firewall (UFW, cloud provider security group, etc.) must allow inbound traffic on ports 80 and 443.

Key `.env` settings for production (overview):

- **`CURRENT_ENV`**: `production`
- **`DEBUG`**: `OFF`
- **`ALLOWED_HOSTS`**: `<your-domain>` (no `*`; include only the real domain or subdomains you use)
- **`SECRET_KEY`**: long, random, unique; treat it as a secret, not committed to Git
- **`DOMAIN`**: `<your-domain>` (must match the DNS record used for HTTPS)
- **`EMAIL`**: `<your-email>` (address that will receive Let's Encrypt expiry notices, etc.)

> [!IMPORTANT]
> In production, Nginx does not generate a self-signed certificate. The certificate is issued and renewed by the `certbot` container and mounted into Nginx.

### First production start (certificate issuance phase)

With `CURRENT_ENV=production`, render Nginx config. If there is no existing certificate yet, `setup.sh` will choose `challenge.conf`:

```bash
./scripts/setup.sh
```

Start the production stack:

```bash
docker compose -f compose.yaml -f compose.prod.yaml up -d --build
```

Follow Certbot logs until the certificate is issued:

```bash
docker compose -f compose.yaml -f compose.prod.yaml logs -f certbot
```

After issuance, you should have:

- `./certbot/conf/live/${DOMAIN}/fullchain.pem`
- `./certbot/conf/live/${DOMAIN}/privkey.pem`

### Switch Nginx from challenge to app config (after cert exists)

Once the certificate exists, switch Nginx from the temporary challenge configuration to the full app configuration.

If `setup.sh` keeps saying that the certificate does not exist even though the files are present under `certbot/conf/live/${DOMAIN}`, it is usually a permission issue on the host. A safer approach is to use a dedicated group instead of granting execute to "others". On the server, you can do:

```bash
# Create a group that will have access to Certbot files
sudo groupadd certbot-access

# Make sure your user is in that group (log out/in after this)
sudo usermod --append --groups certbot-access sergio

# Set group ownership for the certbot directory
sudo chgrp -R certbot-access certbot

# Grant execute permission on directories (so the group can traverse the tree)
sudo chmod -R g+X certbot
```

After re-logging into the server (so the new group membership takes effect), rerun the setup:

```bash
# Re-render Nginx configuration for production (now using app.conf)
./scripts/setup.sh
```

This updates the Nginx configuration to point to the real certificate. Then restart the Nginx service in the stack:

```bash
# Restart only the Nginx service in the production stack
docker compose -f compose.yaml -f compose.prod.yaml restart nginx
```

### Production verification

To confirm that the application is correctly served over HTTPS with a valid certificate using the production domain, run:

```bash
curl -i http://<your-production-domain>/health/    # Check HTTP → HTTPS redirect
curl -i https://<your-production-domain>/health/   # Check health endpoint over HTTPS
```

### Day-2 operations

From the app directory (e.g. `/deploy-lab`), use the same compose override as in production.

**Stream logs:**

```bash
docker compose -f compose.yaml -f compose.prod.yaml logs -f
```

**Update code and rebuild:**

```bash
git pull
docker compose -f compose.yaml -f compose.prod.yaml up -d --build
```

**Stop and remove containers:**

```bash
docker compose -f compose.yaml -f compose.prod.yaml down
```

## GitHub Actions

This repository uses two workflows:

- **CI** (`.github/workflows/ci.yaml`) — Runs on every push and pull request to `main`: Ruff lint/format, Django check, migrations, and tests. No secrets required.
- **Deploy** (`.github/workflows/deploy.yaml`) — Runs only after CI passes on `main`. Connects to the server via SSH and runs the deploy script.

The deploy workflow does not run if CI fails. To configure the deploy workflow, follow the steps below.

### Deploy workflow setup

Firstly, let's login with the `deploy` user created earlier.

```bash
su - deploy
```

### SSH key for the `deploy` user

With the `deploy` user logged in, generate an SSH key and add it as a Deploy Key in GitHub for this same project repository, just like you did before under [Repository access (GitHub over SSH)](#repository-access-github-over-ssh), but now running the commands as `deploy` (for example, you can name this key `deploy-lab github-actions` in GitHub).

#### Testing the key

To confirm that the `deploy` user can access the repository over SSH, clone it into a temporary directory and then remove it:

```bash
# Clone into a disposable directory under /tmp
git clone git@github.com:<your-username>/<your-repo>.git /tmp/deploy-lab-test

# If the clone succeeded, remove the test directory
rm -rf /tmp/deploy-lab-test
```

If the clone fails (e.g. host key or permission errors), check the Deploy Key and SSH config for the `deploy` user before continuing.

### Safe directory configuration for `deploy`

Finally, make sure Git also treats `/deploy-lab` as a safe directory for the `deploy` user. Logged in as `deploy`, repeat the same step used earlier to mark the repository as safe:

```bash
git config --global --add safe.directory /deploy-lab
```

### SSH key for the GitHub Action

The deploy workflow connects to the server via SSH as the `deploy` user (using `appleboy/ssh-action`). You need a dedicated key pair: the **private** key is stored in a GitHub Actions secret; the **public** key is added to the `deploy` user’s `authorized_keys` on the server.

#### Generate the key on your local machine

On your local machine, generate an ED25519 key pair and print both keys so you can use them in the next steps.

```bash
# Generate key pair with no passphrase
ssh-keygen -t ed25519 -C "deploy" -f ~/.ssh/deploy-action-key -N ""

# Copy the public key; you will add it to the server in the next subsection
cat ~/.ssh/deploy-action-key.pub

# Copy the private key; you will add it as the KEY secret in GitHub Actions
cat ~/.ssh/deploy-action-key
```

#### Configure the key on the server

Log in to the server as the `deploy` user (or run `su - deploy`). Ensure `~/.ssh` exists, then create `~/.ssh/authorized_keys` and set permissions to `600` (required by SSH):

```bash
# Create the file
touch ~/.ssh/authorized_keys

# Estrict to owner read/write (SSH ignores the file otherwise)
chmod 600 ~/.ssh/authorized_keys

# Open the file
nano ~/.ssh/authorized_keys
```

Add a single line: the public key with options that restrict this key to running a specific command. Replace `<public-key>` with the exact line you got from `cat ~/.ssh/deploy-action-key.pub`:

```bash
# ~/.ssh/authorized_keys

command="/usr/local/bin/deploy.sh",restrict,no-port-forwarding,no-agent-forwarding,no-X11-forwarding,no-pty <public-key>
```

### GitHub Actions secrets

The deploy workflow reads connection details and the private key from repository secrets. In the repository, go to **Settings → Secrets and variables → Actions** and create a **New repository secret** for each of the following; the names must match what the workflow uses.

| Secret   | Description                                                               |
| -------- | ------------------------------------------------------------------------- |
| **KEY**  | Private SSH key. Paste the full output of `cat ~/.ssh/deploy-action-key`. |
| **HOST** | Hostname or IP address of the server.                                     |
| **USER** | SSH user name (e.g. `deploy`).                                            |
| **PORT** | SSH port (typically `22`).                                                |

After you have added the private key to GitHub and the public key on the server, you can remove the key files from your local machine:

```bash
rm ~/.ssh/deploy-action-key ~/.ssh/deploy-action-key.pub
```

Restart the virtual machine to ensure everything is working correctly.

### Deploy script

Logged in on the server with the VM's main user (in my case `sergio`), copy the script and set ownership and permissions:

```bash
sudo cp ./scripts/deploy.sh /usr/local/bin/deploy.sh
sudo chown root:root /usr/local/bin/deploy.sh
sudo chmod 755 /usr/local/bin/deploy.sh
```

### Configure sudoers for `deploy` user

Lock the `deploy` account so it cannot be used with a password (SSH key only):

```bash
sudo usermod -L deploy
```

Allow `deploy` to run the deploy command as root without a password. Do not edit `/etc/sudoers` directly; use a drop-in file instead:

```bash
sudo visudo -f /etc/sudoers.d/deploy
```

Add the following to the file. It allows `deploy` to run only this compose command as root, without a password. The `--remove-orphans` flag cleans up containers that are no longer in the compose file (e.g. after renaming or removing a service):

```bash
# /etc/sudoers.d/deploy

Cmnd_Alias DOCKER_COMPOSE_UP = /usr/bin/docker compose -f compose.yaml -f compose.prod.yaml up -d --build
deploy ALL=(root) NOPASSWD: DOCKER_COMPOSE_UP
```

### CI workflow

The deploy workflow runs only after CI passes. If you are setting up this repository from scratch, the CI workflow file will not exist yet. Create it first.

Create `.github/workflows/ci.yaml` (create the `.github/workflows` directory if needed) and paste:

```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Install uv
        uses: astral-sh/setup-uv@v4
        with:
          version: "v0.9.29"

      - name: Set up Python
        run: uv python install 3.14

      - name: Install dependencies
        run: uv sync --locked
        working-directory: .

      - name: Ruff check
        run: uv run ruff check src/

      - name: Ruff format
        run: uv run ruff format --check src/

      - name: Django check
        env:
          CI: "1"
          SECRET_KEY: ci-secret-key-for-testing-only
          DEBUG: "ON"
          ALLOWED_HOSTS: "*"
          CURRENT_ENV: development
        run: uv run python src/manage.py check
        working-directory: .

      - name: Run migrations (verify)
        env:
          CI: "1"
          SECRET_KEY: ci-secret-key-for-testing-only
          DEBUG: "ON"
          ALLOWED_HOSTS: "*"
          CURRENT_ENV: development
        run: uv run python src/manage.py migrate --noinput
        working-directory: .

      - name: Run tests
        env:
          CI: "1"
          SECRET_KEY: ci-secret-key-for-testing-only
          DEBUG: "ON"
          ALLOWED_HOSTS: "*"
          CURRENT_ENV: development
        run: uv run pytest src/
        working-directory: .
```

Commit and push. Verify the CI workflow runs in the **Actions** tab. No secrets are required for CI.

### Deploy workflow (after CI passes)

When CI completes successfully on `main`, the deploy workflow connects to your server via SSH (using the `appleboy/ssh-action`) and runs `deploy.sh`, which updates the repo and brings up Docker Compose. Ensure the secrets **HOST**, **USER**, **KEY**, and **PORT** are set in the repository (see [GitHub Actions secrets](#github-actions-secrets)).

Create `.github/workflows/deploy.yaml` with:

```yaml
name: Deploy
on:
  workflow_run:
    workflows: ["CI"]
    types: [completed]
    branches: [main]
jobs:
  deploy:
    if: github.event.workflow_run.conclusion == 'success'
    runs-on: ubuntu-latest
    steps:
      - name: Run deploy script on server
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.HOST }}
          username: ${{ secrets.USER }}
          key: ${{ secrets.KEY }}
          port: ${{ secrets.PORT }}
          script: deploy.sh
```

### Test the deploy workflow

Push a commit to the `main` branch (or merge a PR). The CI workflow runs first; when it completes successfully, the Deploy workflow runs. Open **Actions** in the repository and confirm both workflows succeed.

Optionally, on the server, check that the app is on the expected commit and that the health endpoint responds:

```bash
# Verify which commit is currently deployed
cd /deploy-lab && git rev-parse --short HEAD

# Health check: should print 200
curl -s -o /dev/null -w "%{http_code}\n" https://<your-domain>/health/
```

### Verify containers

On the server, confirm that every service from your compose files is running:

```bash
docker ps -a
```

You should see one row per service (e.g. app, postgres, nginx, certbot if you use them), all with status "Up" or "Up (healthy)". If any are missing or exited, recreate and start everything from the app directory:

```bash
# From the app directory, rebuild images and recreate all containers
cd /deploy-lab
docker compose -f compose.yaml -f compose.prod.yaml up -d --build --force-recreate --remove-orphans
```

If problems persist after a reboot, run `sudo reboot` and check again with `docker ps -a` once the server is back up.

## You're all set

Congratulations! You now have a server with **continuous deployment (CD)** using GitHub Actions: every push to `main` triggers an automatic deploy (SSH + `deploy.sh`), so the production stack stays in sync with the repository without manual steps.
