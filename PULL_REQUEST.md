# Pull Request: Implementation of Inception Multi-Container Infrastructure Stack

## 📌 Summary of Changes

This Pull Request introduces the complete architecture, container definitions, network policies, storage drivers, security parameters, and lifecycle tooling for the **42 Inception** infrastructure project. 

The stack is designed according to strict system administration rules:
- **Zero pre-built application images**: Built entirely from custom `Dockerfile` specifications using `debian:bullseye`.
- **Microservice Isolation**: Each service runs in its own dedicated container (`nginx`, `wordpress`, `mariadb`).
- **Encrypted Entrypoint**: Traffic is restricted exclusively to NGINX on HTTPS (port 443) using TLS v1.2 and v1.3.
- **Secure Secret Management**: Sensitive credentials are read at runtime via Docker secrets (`/run/secrets/`), avoiding cleartext leakages.
- **Host Persistence**: WordPress site files and database tables persist on host storage under `/home/login/data`.

---

## 🛠️ Detailed Implementation Breakdown

### 1. Service Infrastructure (`srcs/requirements/`)

#### A. MariaDB Database (`srcs/requirements/mariadb/`)
- **Base Image**: `debian:bullseye`
- **Config ([50-server.cnf](file:///home/souhail/Desktop/Desktop/inception/srcs/requirements/mariadb/conf/50-server.cnf))**: Binds to `0.0.0.0` on port `3306` to allow intra-network traffic from the WordPress container.
- **Initialization Script ([mariadb-init.sh](file:///home/souhail/Desktop/Desktop/inception/srcs/requirements/mariadb/tools/mariadb-init.sh))**:
  - Automatically loads root and application database passwords from `/run/secrets/`.
  - Runs `mysqld --bootstrap` to securely initialize database users, tables, and permissions without leaving open network sockets during initialization.
  - Ensures clean process execution with PID 1 delegating directly to `mysqld`.

#### B. WordPress + PHP-FPM (`srcs/requirements/wordpress/`)
- **Base Image**: `debian:bullseye`
- **Config ([www.conf](file:///home/souhail/Desktop/Desktop/inception/srcs/requirements/wordpress/conf/www.conf))**: Configures PHP 7.4-FPM pool listening on `0.0.0.0:9000` (FastCGI).
- **Automation Script ([wp-config-create.sh](file:///home/souhail/Desktop/Desktop/inception/srcs/requirements/wordpress/tools/wp-config-create.sh))**:
  - Validates that the administrator's username (`WP_ADMIN_USER`) does **not** contain forbidden substrings (`admin`/`administrator`).
  - Waits for MariaDB health check (`mysqladmin ping`) prior to setup.
  - Automates WordPress installation via `WP-CLI`, creating both the site administrator and a regular author user.

#### C. NGINX Reverse Proxy (`srcs/requirements/nginx/`)
- **Base Image**: `debian:bullseye`
- **Config ([nginx.conf](file:///home/souhail/Desktop/Desktop/inception/srcs/requirements/nginx/conf/nginx.conf))**:
  - Strictly enforces `ssl_protocols TLSv1.2 TLSv1.3;`.
  - Disables unencrypted HTTP listeners (only port 443 is exposed).
  - Routes PHP FastCGI requests directly to `wordpress:9000`.
- **Entrypoint Script ([nginx-entrypoint.sh](file:///home/souhail/Desktop/Desktop/inception/srcs/requirements/nginx/tools/nginx-entrypoint.sh))**:
  - Dynamically generates self-signed TLS certificates for the designated domain (`${DOMAIN_NAME}`).

---

### 2. Orchestration & Networking (`srcs/docker-compose.yml`)

- **Custom Network (`inception-network`)**: User-defined bridge network providing isolated DNS name resolution between containers. No `--link` or host network directives are used.
- **Persistent Volumes**:
  - `mariadb_data` mapped to `${DATA_PATH}/mariadb` (`/home/login/data/mariadb`).
  - `wordpress_data` mapped to `${DATA_PATH}/wordpress` (`/home/login/data/wordpress`).
- **Secrets Wiring**:
  - Mounted from the root `/secrets` directory into container `/run/secrets/`.
- **Restart Policies**: All containers have `restart: always` to ensure resilient crash recovery.

---

### 3. Automation Tooling (`Makefile`)

The root `Makefile` standardizes build lifecycle management:
- `make up`: Creates host data directories (`/home/login/data/...`), builds images, and starts containers in detached mode.
- `make down`: Gracefully stops and removes containers.
- `make fclean`: Cleans containers, networks, images, persistent volumes, and wipes host data directories.
- `make re`: Full clean rebuild cycle.

---

## 🔍 Validation & Testing Checklist

- [x] **No pre-built app images**: Images built exclusively from custom Dockerfiles (`debian:bullseye`).
- [x] **No `latest` tag**: All images explicitly tagged (e.g., `mariadb:v1.0`, `wordpress:v1.0`, `nginx:v1.0`).
- [x] **Port exposure**: Only port 443 is published to the host machine.
- [x] **Security compliance**: No hardcoded passwords in Dockerfiles or compose configs; secrets managed via Docker secrets.
- [x] **Admin username compliance**: Admin username checked against regex `admin|administrator` during setup.
- [x] **Data persistence**: Verified data remains intact across `docker compose down` and stack restarts.
- [x] **Daemon execution**: PID 1 processes run daemons directly without hacky `tail -f` or infinite loop entrypoint scripts.

---

## 🚀 Deployment Instructions

```bash
# 1. Add local host mapping
echo "127.0.0.1 sologin.42.fr" | sudo tee -a /etc/hosts

# 2. Launch the infrastructure
make up

# 3. Verify TLS protocols
curl -v -k --tlsv1.2 https://sologin.42.fr
curl -v -k --tlsv1.3 https://sologin.42.fr
```
