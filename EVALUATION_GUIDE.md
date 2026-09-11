# Inception — Evaluation & Defense Guide (`EVALUATION_GUIDE.md`)

This document serves as the comprehensive evaluation sheet walkthrough and defense guide for the **42 / 1337 Inception** project based on `inception-eval-sheet.md`.

---

## 1. Theoretical Defense Questions & Conceptual Answers

During the evaluation defense, the evaluator will ask four core theoretical questions. Below are clear, concise answers to provide:

### Q1: How do Docker and Docker Compose work?
- **Docker**: Containerization engine that uses Linux kernel features (`namespaces` for PID/Network/IPC isolation and `cgroups` for resource allocation limits) to run isolated application processes in lightweight containers sharing the host OS kernel.
- **Docker Compose**: Orchestration tool for defining and running multi-container applications using a declarative YAML file (`docker-compose.yml`). It manages container lifecycles, service dependencies (`depends_on`), custom virtual bridge networks, and persistent storage volumes in a single workflow (`make up` / `docker compose up`).

### Q2: What is the difference between a Docker image used WITH Docker Compose vs WITHOUT Docker Compose?
- **Without Docker Compose (`docker run`)**: Each container image must be built and executed individually with long CLI commands manually specifying port mappings (`-p`), network links (`--network`), environment files (`--env-file`), volume mounts (`-v`), and container names (`--name`).
- **With Docker Compose**: Container build contexts, image names, volume bind paths, secret mounts, network isolation, and service startup order are central in `docker-compose.yml`. Running `docker compose up` coordinates all service builds and startup cleanly in a unified environment.

### Q3: What is the benefit of Docker compared to Virtual Machines (VMs)?
- **Resource Footprint**: VMs require a full hypervisor layer (VirtualBox/KVM) and duplicate an entire Guest OS kernel per VM (consuming gigabytes of RAM/disk). Docker containers share the host kernel and run as isolated user-space processes (consuming megabytes of RAM).
- **Startup Speed**: Containers start in milliseconds/seconds, whereas VMs take minutes to boot a full OS kernel.
- **Portability & Isolation**: Docker guarantees runtime parity across development and production environments through immutable container images.

### Q4: What is the pertinence of the required directory structure?
- `srcs/`: Encapsulates all configuration, secret declarations, and build sources at the root.
- `srcs/requirements/`: Ensures complete service isolation. Each service (`mariadb`, `wordpress`, `nginx`) has its dedicated subdirectory containing its custom `Dockerfile`, service-specific configuration files (`50-server.cnf`, `www.conf`, `nginx.conf`), and initialization entrypoint scripts (`mariadb-init.sh`, `wp-config-create.sh`, `nginx-entrypoint.sh`).
- `secrets/`: Local directory holding passwords out of version control (`.gitignore`), mounted securely into containers via Docker secrets (`/run/secrets/`).

---

## 2. Pre-Evaluation & Reset Checklist

Before starting the evaluation, execute the full cleanup sequence in your terminal to ensure a clean environment:

```bash
# 1. Reset all containers, images, volumes, and networks
docker stop $(docker ps -qa) 2>/dev/null || true
docker rm $(docker ps -qa) 2>/dev/null || true
docker rmi -f $(docker images -qa) 2>/dev/null || true
docker volume rm $(docker volume ls -q) 2>/dev/null || true
docker network rm $(docker network ls -q) 2>/dev/null || true

# 2. Re-create volume paths on host
make prepare
```

---

## 3. Automatic Failure Verification Checklist

Ensure none of the forbidden patterns exist:

| # | Rule / Check | Status | Verification Command / Location |
|---|---|---|---|
| 1 | `docker-compose.yml` does **not** contain `network: host` or `links:` | ✅ PASS | Inspected `srcs/docker-compose.yml` (uses `networks: inception-network`) |
| 2 | `docker-compose.yml` **must** contain `networks` | ✅ PASS | Defined `inception-network` bridge |
| 3 | No `--link` flag in `Makefile` or scripts | ✅ PASS | Grepped repository for `--link` (0 matches) |
| 4 | No `tail -f` or background daemons in `ENTRYPOINT` | ✅ PASS | Entrypoints end with `exec "$@"` forwarding to PID 1 foreground process |
| 5 | No forbidden background process tricks (`nginx & bash`) | ✅ PASS | NGINX runs `nginx -g "daemon off;"`, PHP-FPM runs `php-fpm8.2 -F`, MariaDB runs `mysqld --user=mysql` |
| 6 | No infinite loops (`sleep infinity`, `tail -f /dev/null`) | ✅ PASS | Verified all shell scripts |
| 7 | `Makefile` compiles and runs cleanly | ✅ PASS | Verified via `make up` |

---

## 4. Mandatory Part Evaluation Walkthrough

### 4.1 Simple Setup & Port Checks
1. **Launch Infrastructure**:
   ```bash
   make up
   ```
2. **Verify NGINX is accessible ONLY via HTTPS Port 443**:
   ```bash
   # Test TLSv1.2 (Must succeed - 200 OK)
   curl -v -k --tlsv1.2 https://<user_login>.42.fr

   # Test TLSv1.3 (Must succeed - 200 OK)
   curl -v -k --tlsv1.3 https://<user_login>.42.fr

   # Test HTTP Port 80 (Must FAIL / connection refused)
   curl -v http://<user_login>.42.fr
   ```

### 4.2 Docker Basics & Docker Network Checks
1. **Verify Custom Images Built locally from `debian:bookworm`**:
   ```bash
   docker images
   # Output displays mariadb:v1.0, wordpress:v1.0, nginx:v1.0
   ```
2. **Verify Custom Bridge Network**:
   ```bash
   docker network ls
   docker network inspect inception-network
   # Output shows mariadb, wordpress, and nginx connected to 172.18.0.0/16 bridge
   ```

### 4.3 WordPress & MariaDB Volume Checks
Per subject specifications, persistent data volumes must bind to host path `/home/<user_login>/data/`:

```bash
docker volume ls
docker volume inspect mariadb_data
docker volume inspect wordpress_data
```
*Expected Output: `device: "/home/<user_login>/data/mariadb"` and `device: "/home/<user_login>/data/wordpress"`.*

### 4.4 WordPress User & Admin Verification
1. Access WordPress via web browser at `https://<user_login>.42.fr`.
2. Log into Admin Dashboard:
   - **Username**: `site_supervisor` *(Rule check: Username does NOT contain `admin` or `administrator`)*.
   - **Password**: Found in `secrets/wp_admin_password.txt`.
3. Edit a post or page in the dashboard.
4. Log into the regular user (`regular_author` / `secrets/wp_user_password.txt`) and post a comment.

### 4.5 MariaDB Database Verification
1. **Execute interactive shell in MariaDB container**:
   ```bash
   docker exec -it mariadb mysql -u root -p
   ```
   *(Enter root password from `secrets/db_root_password.txt`)*
2. **Verify Database is populated**:
   ```sql
   SHOW DATABASES;
   USE wordpress_db;
   SHOW TABLES;
   SELECT option_name, option_value FROM wp_options WHERE option_name = 'siteurl';
   EXIT;
   ```

---

## 5. Persistence Test Protocol

To prove volume persistence across system reboots / restarts during evaluation:

1. Edit a page or publish a post on WordPress at `https://<user_login>.42.fr`.
2. Stop the stack:
   ```bash
   make down
   ```
3. Restart the stack (or reboot the VM):
   ```bash
   make up
   ```
4. Refresh `https://<user_login>.42.fr`. All published posts, page edits, and database records remain intact on disk under `/home/<user_login>/data`.
