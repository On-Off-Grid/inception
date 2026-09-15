# Inception — Defense & Evaluation Master Guide (`EVALUATION_GUIDE.md`)

This guide is tailored step-by-step to `inception-eval-sheet.md` for the defense of the **Inception** project (`souichou.42.fr`). It covers theoretical explanations, practical commands, and file links.

---

## 1. 🧹 Pre-Evaluation Reset & Setup

Run these commands in your terminal **before** the evaluator starts:

```bash
# Stop and remove all containers, images, volumes, and custom networks
docker stop $(docker ps -qa) 2>/dev/null || true
docker rm $(docker ps -qa) 2>/dev/null || true
docker rmi -f $(docker images -qa) 2>/dev/null || true
docker volume rm $(docker volume ls -q) 2>/dev/null || true
docker network rm $(docker network ls -q) 2>/dev/null || true

# Verify /etc/hosts includes the domain mapping
grep "souichou.42.fr" /etc/hosts || echo "127.0.0.1 souichou.42.fr" | sudo tee -a /etc/hosts
```

> ⚠️ **Note for Cluster Evaluation**: Set `DATA_PATH=/home/souichou/data` in `srcs/.env` when evaluating on school cluster machines!

---

## 2. 🚫 Automatic Failure Checks (Instant Fail Rules)

Verify that your project strictly obeys these mandatory rules:

| # | Requirement | Compliance in Project | File / Code Location |
|---|---|---|---|
| **1** | `docker-compose.yml` must **not** contain `network: host` or `links:` | ✅ Uses isolated bridge `networks: inception-network` | [srcs/docker-compose.yml](file:///home/souhail/Desktop/Desktop/cercle_dzab/inception/srcs/docker-compose.yml#L18) |
| **2** | `docker-compose.yml` **must** contain `networks` | ✅ Declared globally and assigned to services | [srcs/docker-compose.yml](file:///home/souhail/Desktop/Desktop/cercle_dzab/inception/srcs/docker-compose.yml#L59-L62) |
| **3** | No `--link` flag in `Makefile` or scripts | ✅ Zero occurrences of `--link` across repo | [Makefile](file:///home/souhail/Desktop/Desktop/cercle_dzab/inception/Makefile) |
| **4** | No `tail -f` or background tasks in `ENTRYPOINT` | ✅ Entrypoints hand over process execution using `exec "$@"` | [nginx-entrypoint.sh](file:///home/souhail/Desktop/Desktop/cercle_dzab/inception/srcs/requirements/nginx/tools/nginx-entrypoint.sh#L18) |
| **5** | No `bash`/`sh` daemon wrapper (`nginx & bash`) | ✅ Daemons run as foreground PID 1 (`nginx -g "daemon off;"`, `php-fpm8.2 -F`, `mysqld --user=mysql`) | [nginx/Dockerfile](file:///home/souhail/Desktop/Desktop/cercle_dzab/inception/srcs/requirements/nginx/Dockerfile#L16) |
| **6** | Entrypoint scripts don't run background processes | ✅ Setup completed synchronously before running `exec "$@"` | [wp-config-create.sh](file:///home/souhail/Desktop/Desktop/cercle_dzab/inception/srcs/requirements/wordpress/tools/wp-config-create.sh#L66) |
| **7** | No infinite loops (`sleep infinity`, `tail -f /dev/null`) | ✅ Waiting scripts poll health checks (`mysqladmin ping`) | [wp-config-create.sh](file:///home/souhail/Desktop/Desktop/cercle_dzab/inception/srcs/requirements/wordpress/tools/wp-config-create.sh#L26) |
| **8** | `Makefile` compiles and runs cleanly | ✅ `make` builds and starts all services without crashing | [Makefile](file:///home/souhail/Desktop/Desktop/cercle_dzab/inception/Makefile#L22-L23) |

---

## 3. 📘 Theoretical Defense Questions & Explanations

### Q1: How do Docker and Docker Compose work?
* **Docker**: A containerization platform that uses Linux kernel features (`namespaces` for process, network, and mount isolation, and `cgroups` for resource limiting) to run applications inside isolated containers sharing the host OS kernel.
* **Docker Compose**: An orchestration tool that defines multi-container applications declaratively in a single YAML configuration (`docker-compose.yml`). It automates building images, launching containers, setting up custom networks, and managing volumes in dependency order.

### Q2: What is the difference between a Docker image used WITH vs WITHOUT Docker Compose?
* **Without Docker Compose (`docker run`)**: Each container must be built manually (`docker build`) and started with long CLI commands specifying ports (`-p`), networks (`--network`), environment variables (`-e`), and volumes (`-v`).
* **With Docker Compose**: All service configurations, build contexts, environment variables (`.env`), secrets, custom networks, and volumes are centralized in `docker-compose.yml`. A single command (`make` / `docker compose up -d`) builds and links all services automatically.

### Q3: What is the benefit of Docker compared to Virtual Machines (VMs)?
* **Architecture**: A VM requires a hypervisor (e.g., KVM, VirtualBox) running an entire guest OS kernel per machine. Docker containers share the host Linux kernel and isolate processes at the OS level.
* **Performance**: Containers launch in seconds, consume megabytes of RAM (instead of gigabytes), and run at near bare-metal execution speed.

### Q4: What is the pertinence of the required directory structure?
* **Separation of Concerns**: Each service (`mariadb`, `wordpress`, `nginx`) has its dedicated folder inside `srcs/requirements/` containing its custom `Dockerfile`, service configuration (`conf/`), and entrypoint scripts (`tools/`).
* **Clean Root**: The root directory contains only top-level orchestrators ([Makefile](file:///home/souhail/Desktop/Desktop/cercle_dzab/inception/Makefile)) and documentation.

---

## 4. 🧪 Step-by-Step Evaluation Walkthrough

### 4.1 Simple Setup & Port Checks
1. **Build and start stack**:
   ```bash
   make
   ```
2. **Verify NGINX is accessible ONLY via HTTPS Port 443**:
   ```bash
   curl -kI https://souichou.42.fr
   ```
   *Output*: `HTTP/1.1 200 OK` or `HTTP/2 200`.

3. **Verify Port 80 (HTTP) Unreachability**:
   ```bash
   curl -I http://souichou.42.fr
   ```
   *Output*: Connection refused (`Failed to connect to souichou.42.fr port 80`).

---

### 4.2 Docker Basics & Docker Network
1. **Show Dockerfiles**:
   Show evaluator the three individual Dockerfiles built from `debian:bookworm` (penultimate stable Debian release):
   - [srcs/requirements/mariadb/Dockerfile](file:///home/souhail/Desktop/Desktop/cercle_dzab/inception/srcs/requirements/mariadb/Dockerfile)
   - [srcs/requirements/wordpress/Dockerfile](file:///home/souhail/Desktop/Desktop/cercle_dzab/inception/srcs/requirements/wordpress/Dockerfile)
   - [srcs/requirements/nginx/Dockerfile](file:///home/souhail/Desktop/Desktop/cercle_dzab/inception/srcs/requirements/nginx/Dockerfile)

2. **Verify Built Images**:
   ```bash
   docker images
   ```
   *Expected Output*: `mariadb:v1.0`, `wordpress:v1.0`, `nginx:v1.0`.

3. **Verify Custom Bridge Network**:
   ```bash
   docker network ls
   docker network inspect inception-network
   ```
   Show evaluator that `mariadb`, `wordpress`, and `nginx` are connected to `inception-network`.

---

### 4.3 NGINX with SSL/TLS
1. **Show TLS Configuration**:
   Open [srcs/requirements/nginx/conf/nginx.conf](file:///home/souhail/Desktop/Desktop/cercle_dzab/inception/srcs/requirements/nginx/conf/nginx.conf#L6-L7):
   ```nginx
   ssl_protocols TLSv1.2 TLSv1.3;
   ```
2. **Show SSL Generation**:
   Open [srcs/requirements/nginx/tools/nginx-entrypoint.sh](file:///home/souhail/Desktop/Desktop/cercle_dzab/inception/srcs/requirements/nginx/tools/nginx-entrypoint.sh#L8-L11).
3. **Browser Verification**:
   Navigate to `https://souichou.42.fr` in browser. Accept security warning for self-signed certificate and inspect TLS details (TLS 1.2 / TLS 1.3 verified).

---

### 4.4 WordPress with php-fpm & Volume
1. **Verify No NGINX in WordPress container**:
   Show [srcs/requirements/wordpress/Dockerfile](file:///home/souhail/Desktop/Desktop/cercle_dzab/inception/srcs/requirements/wordpress/Dockerfile) (contains `php8.2-fpm` on port 9000, no Nginx).
2. **Verify Host Volume Binding**:
   ```bash
   docker volume inspect wordpress_data
   ```
   *Output contains*: `device: "/home/souhail/data/wordpress"` (or `/home/souichou/data/wordpress`).
3. **Verify Admin Username Constraint**:
   Show [srcs/.env](file:///home/souhail/Desktop/Desktop/cercle_dzab/inception/srcs/.env#L20):
   `WP_ADMIN_USER=site_supervisor` (Does **not** contain `admin` or `administrator`).
4. **Dashboard Demonstration**:
   - Access `https://souichou.42.fr/wp-login.php`.
   - Log in with `site_supervisor` and password from [secrets/wp_admin_password.txt](file:///home/souhail/Desktop/Desktop/cercle_dzab/inception/secrets/wp_admin_password.txt).
   - Edit site title or publish a blog post.
   - Log in as second user (`regular_author` / [secrets/wp_user_password.txt](file:///home/souhail/Desktop/Desktop/cercle_dzab/inception/secrets/wp_user_password.txt)) and submit a comment.

---

### 4.5 MariaDB & Volume
1. **Verify Host Volume Binding**:
   ```bash
   docker volume inspect mariadb_data
   ```
   *Output contains*: `device: "/home/souhail/data/mariadb"` (or `/home/souichou/data/mariadb`).
2. **Log into Database via CLI**:
   ```bash
   docker exec -it mariadb mysql -u wp_user -p
   ```
   *(Enter password from [secrets/db_password.txt](file:///home/souhail/Desktop/Desktop/cercle_dzab/inception/secrets/db_password.txt))*
3. **Verify Non-Empty Database**:
   ```sql
   SHOW DATABASES;
   USE wordpress_db;
   SHOW TABLES;
   SELECT option_name, option_value FROM wp_options WHERE option_name = 'siteurl';
   EXIT;
   ```

---

### 4.6 Persistence Verification Test
Demonstrate that changes persist across container teardowns:

1. **Publish a comment or edit a post** on `https://souichou.42.fr`.
2. **Stop and destroy stack**:
   ```bash
   make down
   ```
3. **Restart stack**:
   ```bash
   make up
   ```
4. **Reload `https://souichou.42.fr`**:
   Verify that all pages, comments, and database entries remain intact without triggering WordPress re-installation.
