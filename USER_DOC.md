# User Operations Guide (USER_DOC.md)

## 1. Quick Start Guide

### Prerequisites
- Linux OS / Virtual Machine with Docker and Docker Compose installed.
- `sudo` access to edit `/etc/hosts` and create host volume directories.

### Setup Steps
1. Map host IP to domain in `/etc/hosts`:
   ```bash
   sudo sh -c 'echo "127.0.0.1 sologin.42.fr" >> /etc/hosts'
   ```

2. Start the infrastructure:
   ```bash
   make up
   ```

3. Access WordPress:
   Open `https://sologin.42.fr` in your browser. Accept the self-signed TLS certificate warning.

---

## 2. Infrastructure Operations

| Action | Command |
| --- | --- |
| **Start stack** | `make up` |
| **Stop stack** | `make stop` |
| **Restart stack** | `make down && make up` |
| **Check running status** | `make ps` |
| **Stream container logs** | `make logs` |
| **Purge stack & data** | `make fclean` |

---

## 3. Credential & Secrets Management

Passwords and secrets are located in the `secrets/` directory:
- `secrets/db_password.txt`: Password for MariaDB database user.
- `secrets/db_root_password.txt`: Password for MariaDB root user.
- `secrets/wp_admin_password.txt`: Password for WordPress administrator.
- `secrets/wp_user_password.txt`: Password for WordPress secondary user.

> **Important Constraint**: The WordPress administrator username (`WP_ADMIN_USER` in `srcs/.env`) **must not** contain the words `admin` or `administrator`.

---

## 4. Basic Health & Diagnostics

Check status of containers:
```bash
make status
```

Verify TLS protocol enforcement (TLSv1.2 / TLSv1.3):
```bash
curl -v -k --tlsv1.2 https://sologin.42.fr
curl -v -k --tlsv1.3 https://sologin.42.fr
```

Verify non-TLS (HTTP) is refused / restricted:
```bash
curl -v http://sologin.42.fr
```
