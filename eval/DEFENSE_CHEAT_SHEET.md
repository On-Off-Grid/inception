# Inception Defense Cheat Sheet & Evaluation Field Answers

This document provides exact, direct, field-by-field answers for every item in [inception-eval-sheet.md](file:///home/souhail/Desktop/Desktop/cercle_dzab/inception/eval/inception-eval-sheet.md), along with the high-level DevOps narrative analogy and instructions for running the evaluation scripts.

---

## 1. Pre-Evaluation Checks
* **All files required inside `srcs` folder at root:**  
  *Answer:* All configuration files (`docker-compose.yml`, `.env`, service build directories) reside in `srcs/` at repository root.
* **`Makefile` located at root of repository:**  
  *Answer:* The root `Makefile` manages the stack via `docker compose`.
* **Run pre-evaluation cleanup command:**  
  *Answer:* Run `./eval_verification.sh pre-eval` to reset all containers, images, volumes, and networks before evaluation.

---

## 2. Automatic Failure Conditions
* **Check 1: `docker-compose.yml` must NOT contain `network: host` or `links:`**  
  *Answer:* Verified. Services use explicit custom bridge network definitions (`networks: - inception-network`). Neither `network: host` nor `links:` exists.
* **Check 2: `docker-compose.yml` MUST contain `network` or `networks`**  
  *Answer:* Verified. `networks:` is declared globally and under each service in `docker-compose.yml`.
* **Check 3: No `--link` flag in `Makefile` or scripts**  
  *Answer:* Verified. Service communication relies exclusively on Docker built-in DNS resolution over the custom bridge network.
* **Check 4: No `tail -f` or background commands in `ENTRYPOINT`**  
  *Answer:* Verified. Primary server applications run natively in foreground as PID 1 (`nginx -g 'daemon off;'`, `php-fpm7.4 -F`, `mariadbd`).
* **Check 5: No `bash` or `sh` in `ENTRYPOINT` unless running a script**  
  *Answer:* Verified. `ENTRYPOINT` calls binary executables directly or executes explicit shell setup scripts (e.g., `["/usr/local/bin/docker-entrypoint.sh"]`).
* **Check 6: If `ENTRYPOINT` is a script, it must NOT run programs in background**  
  *Answer:* Verified. Entrypoint scripts perform setup tasks and finish with `exec "$@"` or `exec server_binary`, replacing the shell with the main process.
* **Check 7: No infinite loops in any scripts (`sleep infinity`, `tail -f /dev/null`)**  
  *Answer:* Verified. Containers stay alive strictly because their primary service process stays attached in the foreground.
* **Check 8: `Makefile` runs successfully without crashes**  
  *Answer:* Verified. Running `make` creates host directories, builds custom images, and launches the stack reliably.

---

## 3. Mandatory Part — Project Overview
* **Docker & Docker Compose explanation:**  
  *Answer:* Docker uses Linux Kernel features (namespaces for isolation, cgroups for resource limits) to run applications in lightweight containers. Docker Compose is an orchestration tool that automates building, networking, volume mounting, and starting multi-container stacks defined in a YAML configuration file.
* **Image usage difference (with vs without Docker Compose):**  
  *Answer:* Without Docker Compose, each container must be manually built, configured, linked, mounted, and started with long CLI commands (`docker run -v ... -p ... --net ...`). With Docker Compose, the complete infrastructure (networks, volumes, builds, depends_on, environment files) is declared declaratively and launched via a single command (`docker compose up`).
* **Docker vs VM benefits:**  
  *Answer:* VMs virtualize full hardware and run complete guest operating systems, incurring heavy RAM/CPU overhead and slow boot times. Docker virtualizes only the OS layer, sharing the host Linux kernel, resulting in near-instant boot, minimal RAM footprint, and lightweight reproducible builds.
* **Directory structure justification:**  
  *Answer:* Encapsulates application configuration in `srcs/`, cleanly isolates each microservice context inside `srcs/requirements/<service>`, keeps secrets secure in `secrets/`, and exposes a simple root `Makefile` entry point.

---

## 4. Simple Setup
* **Check 1: NGINX accessible ONLY via port 443 (HTTPS):**  
  *Answer:* Only port `443:443` is exposed in `docker-compose.yml`. Port 80 is not published or listening.
* **Check 2: SSL/TLS certificate is used:**  
  *Answer:* Self-signed RSA/ECDSA TLS certificate generated via OpenSSL and loaded in NGINX configuration (`/etc/nginx/ssl/`).
* **Check 3: WordPress properly installed (no install page visible):**  
  *Answer:* `wp-cli` automates database connection and core installation on first boot; navigating to the URL renders the live website directly.
* **Check 4: Accessible via `https://login.42.fr/`:**  
  *Answer:* Mapped `127.0.0.1 sbejaoui.42.fr` inside `/etc/hosts`. Accessing `https://sbejaoui.42.fr` successfully loads the site.
* **Check 5: NOT accessible via `http://login.42.fr/`:**  
  *Answer:* HTTP port 80 is blocked/unbound, causing HTTP requests to fail with connection refused or timeout.

---

## 5. Docker Basics
* **Check 1: One Dockerfile per service (no empty files):**  
  *Answer:* Individual non-empty Dockerfiles exist in `nginx/`, `wordpress/`, and `mariadb/`.
* **Check 2: Student wrote their own Dockerfiles (no ready-made DockerHub images):**  
  *Answer:* Every image starts from clean Alpine base OS (`FROM alpine:3.19`), installing dependencies from scratch using `apk add`.
* **Check 3: Built from penultimate stable version of Alpine/Debian:**  
  *Answer:* Built from `alpine:3.19` (penultimate stable release).
* **Check 4: Docker image names match corresponding service names:**  
  *Answer:* Images are tagged as `nginx:v1.0`, `wordpress:v1.0`, and `mariadb:v1.0`.
* **Check 5: `Makefile` sets up all services via Docker Compose:**  
  *Answer:* `make` handles pre-creation of host volume paths and executes `docker compose up -d --build` cleanly.

---

## 6. Docker Network
* **Check 1: `docker-network` is used in `docker-compose.yml`:**  
  *Answer:* Configured explicit bridge network `inception-network` in `docker-compose.yml`.
* **Check 2: Custom network visible in `docker network ls`:**  
  *Answer:* Running `docker network ls` displays `inception-network` active with `bridge` driver.
* **Check 3: Simple explanation of Docker networks:**  
  *Answer:* Docker networks act as virtual software switches. They isolate container communications and provide automatic internal DNS resolution so containers can locate each other securely by service name (e.g. `mariadb:3306`) without exposing ports to the public host network.

---

## 7. NGINX with SSL/TLS
* **Check 1: Dockerfile exists for NGINX:**  
  *Answer:* Located at `srcs/requirements/nginx/Dockerfile`.
* **Check 2: Container was created (`docker compose ps`):**  
  *Answer:* Verified container state is `Up` and healthy.
* **Check 3: Cannot access via HTTP (port 80):**  
  *Answer:* Verified `curl -I http://sbejaoui.42.fr` fails.
* **Check 4: Access via `https://login.42.fr/` displays WordPress site:**  
  *Answer:* NGINX terminates TLS 443 and passes PHP requests to `wordpress:9000` via FastCGI.
* **Check 5: TLS v1.2 or v1.3 certificate used:**  
  *Answer:* NGINX config explicitly sets `ssl_protocols TLSv1.2 TLSv1.3;`.

---

## 8. WordPress with php-fpm and Its Volume
* **Check 1: Dockerfile exists for WordPress:**  
  *Answer:* Located at `srcs/requirements/wordpress/Dockerfile`.
* **Check 2: No NGINX in WordPress Dockerfile:**  
  *Answer:* Contains only `php-fpm` and required PHP extensions. NGINX is not installed.
* **Check 3: Container was created (`docker compose ps`):**  
  *Answer:* Verified container state is `Up`.
* **Check 4: Volume contains `/home/login/data/`:**  
  *Answer:* `docker volume inspect wordpress_data` displays host mount `/home/sbejaoui/data/wordpress`.
* **Check 5: Can add a comment using regular WordPress user:**  
  *Answer:* Logged in as regular subscriber/author user and submitted a post comment live.
* **Check 6: Admin username does NOT include `admin` or `Admin`:**  
  *Answer:* Admin account is created as `wpmaster` (strictly adhering to forbidden substring rules).
* **Check 7: Edit a page from Admin dashboard and verify live changes:**  
  *Answer:* Edited sample page content in `/wp-admin`; changes updated instantly on the public HTTPS frontend.

---

## 9. MariaDB and Its Volume
* **Check 1: Dockerfile exists for MariaDB:**  
  *Answer:* Located at `srcs/requirements/mariadb/Dockerfile`.
* **Check 2: No NGINX in MariaDB Dockerfile:**  
  *Answer:* Only `mariadb` and `mariadb-client` packages are installed.
* **Check 3: Container was created (`docker compose ps`):**  
  *Answer:* Verified container state is `Up`.
* **Check 4: Volume contains `/home/login/data/`:**  
  *Answer:* `docker volume inspect mariadb_data` displays host mount `/home/sbejaoui/data/mariadb`.
* **Check 5: Explain how to log into database:**  
  *Answer:* Run `docker exec -it mariadb mariadb -u <db_user> -p` using credentials passed securely from Docker secrets.
* **Check 6: Database is NOT empty:**  
  *Answer:* Executed `SHOW TABLES;` inside `wordpress` database showing populated WordPress schemas (`wp_posts`, `wp_users`, `wp_options`).

---

## 10. Persistence!
* **Check 1: Reboot the virtual machine:**  
  *Answer:* Machine reboot simulated/executed (`sudo reboot`).
* **Check 2: Launch Docker Compose again after reboot:**  
  *Answer:* Ran `make` or `docker compose up -d`.
* **Check 3: WordPress and MariaDB functional and configured:**  
  *Answer:* All containers re-attach seamlessly to persistent storage directories.
* **Check 4: Previous WordPress changes still present:**  
  *Answer:* Data stored on host bind mounts (`/home/sbejaoui/data`) survived container destroy/reboot cycles without loss.

---

# DevOps Narrative Analogy

```
 [ PUBLIC CLIENT / BROWSER ]
             │ (HTTPS request on Port 443)
             ▼
┌─────────────────────────────────────────────────────────────┐
│ 1. NGINX (The Front Receptionist & Gatekeeper)             │
│    • Checks TLS credentials (SSL Certificate)               │
│    • Rejects unencrypted walk-ins (No Port 80)               │
│    • Routes order tickets to the kitchen via FastCGI        │
└────────────────────────────┬────────────────────────────────┘
                             │ (Private Walkie-Talkie Intercom: 
                             │  inception-network)
                             ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. WORDPRESS + PHP-FPM (The Master Kitchen Chef)           │
│    • Receives order specs & executes business application   │
│    • Runs in total isolation (No web server inside kitchen) │
│    • Requests ingredients from database storehouse          │
└────────────────────────────┬────────────────────────────────┘
                             │ (Internal DB Protocol on Port 3306)
                             ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. MARIADB (The Locked Recipe & Pantry Vault)              │
│    • Stores permanent records (posts, user accounts)        │
│    • Fully shielded from external internet                  │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼ (Host Bind Mount Bindings)
┌─────────────────────────────────────────────────────────────┐
│ 4. HOST STORAGE DISK (/home/login/data/)                   │
│    • Storage Lockers outside the restaurant building        │
│    • If kitchen burns down (container crash/reboot), pantry │
│      data remains 100% safe & intact                        │
└────────────────────────────┴────────────────────────────────┘
```
