# Developer Technical Guide (DEV_DOC.md)

## 1. Development & Setup from Scratch

### Environment Setup
All configuration files reside in `srcs/`.
- Edit `srcs/.env` to configure domain name, user logins, and data directory paths.
- Store sensitive values in `secrets/`.

### Building Individual Services
To rebuild a single service (e.g., `nginx`) without re-building the entire stack:
```bash
docker compose -f srcs/docker-compose.yml build nginx
docker compose -f srcs/docker-compose.yml up -d nginx
```

---

## 2. Container Architecture & Dockerfiles

### MariaDB Service (`srcs/requirements/mariadb`)
- **Base**: `debian:bullseye`
- **Configuration**: `/etc/mysql/mariadb.conf.d/50-server.cnf` (binds to `0.0.0.0`, port 3306).
- **Initialization**: `/usr/local/bin/mariadb-init.sh` runs `mysql_install_db` and configures root / user passwords from `/run/secrets/`.

### WordPress + PHP-FPM Service (`srcs/requirements/wordpress`)
- **Base**: `debian:bullseye`
- **Configuration**: `/etc/php/7.4/fpm/pool.d/www.conf` (listens on `0.0.0.0:9000`).
- **Initialization**: Uses `wp-cli` in `/usr/local/bin/wp-config-create.sh` to download WordPress core, connect to MariaDB, and register 2 users (1 non-admin admin, 1 author).

### NGINX Service (`srcs/requirements/nginx`)
- **Base**: `debian:bullseye`
- **Configuration**: `/etc/nginx/conf.d/default.conf` (listens on port 443 with TLS 1.2/1.3 only).
- **Initialization**: Generates self-signed certificates dynamically using OpenSSL in `/usr/local/bin/nginx-entrypoint.sh`.

---

## 3. Storage & Persistence Layout

Data persists on the host system via Docker volume bind options:
- Database files: `${DATA_PATH}/mariadb` -> mounted to `/var/lib/mysql`
- WordPress files: `${DATA_PATH}/wordpress` -> mounted to `/var/www/wordpress`

To verify persistence:
1. Create a post in WordPress via web UI or WP-CLI.
2. Run `make down`.
3. Run `make up`.
4. Verify the post remains stored.

---

## 4. Debugging & Inspection

Inspect running process logs:
```bash
docker logs mariadb
docker logs wordpress
docker logs nginx
```

Execute shell in container for troubleshooting:
```bash
docker exec -it wordpress bash
docker exec -it mariadb bash
docker exec -it nginx bash
```
