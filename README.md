# Inception System Administration Project

## Architectural Overview

This project implements a fully isolated, secure multi-container web infrastructure using Docker, Docker Compose, NGINX, WordPress (with PHP-FPM), and MariaDB.

```
                  +-----------------------------------+
                  |            VM / Host              |
                  |          (login.42.fr)            |
                  +-----------------------------------+
                                    |
                                HTTPS (443)
                                TLS 1.2 / 1.3
                                    v
                 +--------------------------------------+
                 |          NGINX Container             |
                 |       (sole public entrypoint)       |
                 +--------------------------------------+
                                    |
                            FastCGI (port 9000)
                            inception-network
                                    v
                 +--------------------------------------+
                 |         WordPress Container          |
                 |       (PHP 8.2-FPM on Debian)        |
                 +--------------------------------------+
                                    |
                            MySQL (port 3306)
                            inception-network
                                    v
                 +--------------------------------------+
                 |          MariaDB Container           |
                 |           (Database)                 |
                 +--------------------------------------+
```

---

## Directory Structure

```
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── PULL_REQUEST.md
├── secrets/
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── .env
    ├── .env.example
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/50-server.cnf
        │   └── tools/mariadb-init.sh
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/nginx.conf
        │   └── tools/nginx-entrypoint.sh
        └── wordpress/
            ├── Dockerfile
            ├── conf/www.conf
            └── tools/wp-config-create.sh
```

---

## Quick Utilisation & Cleanup Sheet

Detailed operations documentation is available in [USER_DOC.md](file:///home/souhail/Desktop/Desktop/inception/USER_DOC.md) and developer specs in [DEV_DOC.md](file:///home/souhail/Desktop/Desktop/inception/DEV_DOC.md).

### 1. Initialization
```bash
# Step 1: Map host IP to domain
echo "127.0.0.1 souichou.42.fr" | sudo tee -a /etc/hosts

# Step 2: Build images, create data directories, and launch container stack
make up

# Step 3: Check running containers
make ps
```

### 2. Operational Access
- **Web Application**: `https://souichou.42.fr`
- **TLS 1.2 Verification**: `curl -v -k --tlsv1.2 https://souichou.42.fr`
- **TLS 1.3 Verification**: `curl -v -k --tlsv1.3 https://souichou.42.fr`

### 3. Cleanup & Reset Options
```bash
# Stop running containers:
make stop

# Stop containers and remove network/volume definitions (keep persistent data):
make down

# Clean unused Docker system resources:
make clean

# Complete Purge: Remove containers, networks, images, and wipe all host data:
make fclean
```

---

## Technical Design & Comparative Analysis

### 1. Virtual Machines vs. Docker Containers
- **Virtual Machines**: Emulate an entire hardware system and run a complete guest OS on top of a hypervisor. This incurs high resource overhead (CPU, RAM, disk) and slower boot times.
- **Docker Containers**: Share the host kernel and isolate processes using Linux `namespaces` and `cgroups`. Containers are lightweight, boot in seconds, and share resources efficiently while maintaining process isolation.

### 2. Docker Secrets vs. Environment Variables
- **Environment Variables**: Useful for non-sensitive configuration settings (domain names, user names, ports). However, environment variables can leak via process listings (`ps aux`), child processes, or inspect logs (`docker inspect`).
- **Docker Secrets**: Injects sensitive data (passwords, private keys) in-memory inside `/run/secrets/` as mounted tmpfs files, ensuring credentials are never exposed in Dockerfiles, shell command histories, or environment dumps.

### 3. Custom Docker Bridge Network vs. Host Network
- **Host Network (`--net=host`)**: Binds container ports directly to the host interface, bypassing container isolation and risking port conflicts or exposed internal services.
- **Custom Bridge Network**: Provides isolated network space where services communicate securely using container names (DNS resolution). Only specified ports (e.g., NGINX port 443) are published to the host.

### 4. Docker Named Volumes vs. Bind Mounts
- **Bind Mounts**: Directly expose host directory paths to containers. Host permission misconfigurations can break container execution.
- **Docker Named Volumes**: Managed by Docker with explicit storage configuration. In this project, named volumes map persistent data to `/home/login/data` on the host machine using local volume drivers, guaranteeing data persistence across stack rebuilds.
