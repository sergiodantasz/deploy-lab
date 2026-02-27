# Server

This document describes the configuration used for the production server.

## VM requirements

The virtual machine should have at least:

- **Region:** According to your requirements
- **Image/OS:** Ubuntu Server 24.04 LTS (x64)
- **Size:** According to your requirements
- **Ports:** 22 (SSH), 80 (HTTP), and 443 (HTTPS) open for inbound traffic
- **Disk:** According to your requirements

Optionally, enable **backups** to reduce the risk of data loss. You can also restrict SSH access by configuring the **network interface** to allow connections only from your machine’s IP address.

## SSH key and client config

Generate a new SSH key:

```bash
# Generate an ED25519 key
ssh-keygen -t ed25519 -C "sergio" -f ~/.ssh/deploy-lab

# Print the public key and copy it
cat ~/.ssh/deploy-lab.pub
```

Add the copied key to your VM settings and save. You can then access the server with that key.

For easier access, add the server to your `~/.ssh/config` file (create it if it does not exist):

```bash
# ~/.ssh/config

Host *
  AddKeysToAgent yes

Host github.com
  HostName github.com
  User git
  Port 22
  IdentityFile ~/.ssh/github
  IdentitiesOnly yes

# Your other hosts here...

Host deploy-lab
  HostName <your-vm-ip-or-domain>
  User sergio
  Port 22
  IdentityFile ~/.ssh/deploy-lab
  IdentitiesOnly yes
```

Then connect with:

```bash
ssh deploy-lab
```

## Initial server setup

Update packages and clean up:

```bash
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && sudo snap refresh
```

Reboot the system. After it comes back up, log in again via SSH.

Create the app group and deploy user:

```bash
# Create a group that will own the app directory
sudo groupadd app

# Create a user for deploy-related actions
sudo adduser deploy # Set the password when prompted

# Add both users to the app group
sudo usermod --append --groups app sergio
sudo usermod --append --groups app deploy
```

## Application directory

Avoid putting the application in a user home directory. Use a dedicated path at the root instead:

```bash
# Create the app directory
sudo mkdir /deploy-lab

# Set the group owner
sudo chgrp app /deploy-lab

# Restrict access to owner and group
sudo chmod 770 /deploy-lab

# New files and folders under /deploy-lab inherit the app group (setgid)
sudo chmod g+s /deploy-lab
```

## SSH daemon configuration

Edit the SSH daemon config:

```bash
sudo nano /etc/ssh/sshd_config
```

Apply (or uncomment) these options. Some may already be set or commented; adjust as needed:

```sshconfig
# /etc/ssh/sshd_config

# Other configs...

# Key-based authentication only
PubkeyAuthentication yes        # Enable authentication using SSH public keys
PasswordAuthentication no       # Disable password-based login
KbdInteractiveAuthentication no # Disable keyboard-interactive/PAM-based prompts
AuthenticationMethods publickey # Require public key authentication only

# Security
PermitRootLogin no              # Disallow direct SSH login as root
PermitEmptyPasswords no         # Reject accounts with empty passwords
UsePAM yes                      # Use PAM for session handling, limits, and environment setup

# Optional: restrict which users and groups can log in
AllowUsers sergio deploy        # Only allow these users to log in via SSH
AllowGroups sergio deploy app   # And these groups
```

Save the file and restart SSH:

```bash
sudo systemctl restart ssh
```

Open a second terminal and test `ssh deploy-lab` before closing your current session. If something is wrong, you can still fix it from the existing connection.

## Fail2Ban

Fail2Ban monitors logs and bans IPs that show suspicious behaviour (e.g. many failed SSH attempts). Install and configure it as follows.

Install dependencies and Fail2Ban:

```bash
# Python is required; install if not already present
sudo apt install -y python3

# Install Fail2Ban
sudo apt update && sudo apt install -y fail2ban

# Create and edit the local jail config
sudo nano /etc/fail2ban/jail.local
```

Put this in `/etc/fail2ban/jail.local`:

```ini
# /etc/fail2ban/jail.local

[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5
backend = systemd

[sshd]
enabled = true
port = ssh
```

Restart Fail2Ban:

```bash
sudo systemctl restart fail2ban
```

Check that jails are active:

```bash
# List all jails
sudo fail2ban-client status

# Inspect the sshd jail
sudo fail2ban-client status sshd
```

Watch the log (optional):

```bash
tail -f /var/log/fail2ban.log
```

## Firewall (UFW)

Uncomplicated Firewall (UFW) controls incoming and outgoing traffic. Set it up like this:

```bash
# Install UFW
sudo apt update && sudo apt install -y ufw

# Default policy: block incoming, allow outgoing
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH, HTTP, and HTTPS
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable the firewall
sudo ufw enable

# Verify status
sudo ufw status
```

For a detailed view of rules:

```bash
sudo ufw status verbose
```

## Docker

Install the Docker Engine and Compose so you can run the application in containers. Follow the [official Ubuntu install guide](https://docs.docker.com/engine/install/ubuntu/).

Add Docker’s APT repository and install the packages:

```bash
# Install prerequisites
sudo apt update && sudo apt install -y ca-certificates curl

# Add Docker’s official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the Docker repository to Apt sources
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

# Install Docker
sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Allow your user to run Docker without sudo
sudo usermod --append --groups docker sergio
```

Reboot the system for changes to take effect.
