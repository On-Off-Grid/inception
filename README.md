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
                 |              (PHP-FPM)               |
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

---

## How to Run

1. **Configure local DNS (`/etc/hosts`)**:
   ```bash
   echo "127.0.0.1 sologin.42.fr" | sudo tee -a /etc/hosts
   ```

2. **Build and launch the stack**:
   ```bash
   make up
   ```

3. **Access the application**:
   Open browser at `https://sologin.42.fr`
