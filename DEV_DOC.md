# Developer Technical Guide (DEV_DOC.md)

## 1. Development & Setup from Scratch

### Environment Setup
All configuration files reside under `srcs/`.
- Edit `srcs/.env` to configure domain name, user logins, and data directory paths.
- Store sensitive values in `secrets/`.

### Building Individual Services
To rebuild a single service (e.g., `wordpress` or `nginx`) without rebuilding the entire stack:
```bash
docker compose -f srcs/docker-compose.yml --env-file srcs/.env build wordpress
docker compose -f srcs/docker-compose.yml --env-file srcs/.env up -d wordpress
```

---

## 2. Container Architecture & Dockerfiles

### MariaDB Service (`srcs/requirements/mariadb`)
- **Base Image**: `debian:bullseye`
- **Configuration**: `/etc/mysql/mariadb.conf.d/50-server.cnf` (binds to `0.0.0.0`, port 3306).
- **Initialization**: `/usr/local/bin/mariadb-init.sh` runs `mysql_install_db` and configures root / user passwords from `/run/secrets/`.

### WordPress + PHP-FPM Service (`srcs/requirements/wordpress`)
- **Base Image**: `debian:bookworm` (Upgraded to support native PHP 8.2 & resolve PHP 7.4 end-of-life deprecation notices).
- **Configuration**: `/etc/php/8.2/fpm/pool.d/www.conf` (listens on `0.0.0.0:9000`).
- **Initialization**: Uses `wp-cli` in `/usr/local/bin/wp-config-create.sh` to download WordPress core, connect to MariaDB, and register 2 users (1 non-admin admin, 1 author).

### NGINX Service (`srcs/requirements/nginx`)
- **Base Image**: `debian:bullseye`
- **Configuration**: `/etc/nginx/conf.d/default.conf` (listens on port 443 with TLS 1.2/1.3 only).
- **Initialization**: Generates self-signed certificates dynamically using OpenSSL in `/usr/local/bin/nginx-entrypoint.sh`.

---

## 3. Storage & Persistence Layout

Data persists on the host system via Docker named volume bind driver options:
- Database files: `${DATA_PATH}/mariadb` -> mounted to `/var/lib/mysql`
- WordPress files: `${DATA_PATH}/wordpress` -> mounted to `/var/www/wordpress`

To verify persistence:
1. Create a post in WordPress via web UI (`https://souichou.42.fr`) or WP-CLI.
2. Run `make down`.
3. Run `make up`.
4. Verify the post remains stored in MariaDB/WordPress files on disk.

---

## 4. Initialization & Cleanup Workflow for Developers

### Developer Initialization Sequence
1. Prepare host volume directories:
   ```bash
   make prepare
   ```
2. Build and launch debug stack:
   ```bash
   make up
   ```
3. Inspect startup logs:
   ```bash
   make logs
   ```

### Developer Cleanup Sequence
1. **Stop & Remove Stack Containers**:
   ```bash
   make down
   ```
2. **Remove Unused Docker Resources & Cache**:
   ```bash
   make clean
   ```
3. **Full Hard Reset (Remove Images & Host Data)**:
   ```bash
   make fclean
   ```

---

## 5. Debugging & Inspection

Inspect running process logs:
```bash
docker logs mariadb
docker logs wordpress
docker logs nginx
```

Execute interactive shell in container for troubleshooting:
```bash
docker exec -it wordpress bash
docker exec -it mariadb bash
docker exec -it nginx bash
```
