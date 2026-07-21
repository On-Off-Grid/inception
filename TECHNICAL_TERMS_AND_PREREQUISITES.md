# Technical Terms and Prerequisites Guide

This document provides a comprehensive breakdown of the technical terms, concepts, system primitives, and prerequisites required to understand, build, and maintain the **Inception** infrastructure project.

---

## 📋 System & Environment Prerequisites

Before building or running the project infrastructure, the host environment must satisfy the following prerequisites:

### 1. Host Operating System & Virtualization
- **Virtual Machine (VM)**: A Linux distribution (e.g., Debian 11/12, Ubuntu 22.04 LTS, or Alpine Linux) running inside VirtualBox, UTM, or QEMU.
- **Root / Sudo Privileges**: Required for creating persistent data directories under `/home/login/data` and binding domain mappings in `/etc/hosts`.

### 2. Software Requirements

| Tool | Minimum Version | Purpose |
| --- | --- | --- |
| **Docker Engine** | `20.10+` | Container runtime engine managing Linux namespaces and cgroups. |
| **Docker Compose** | `v2.0+` | Multi-container application orchestrator reading `docker-compose.yml`. |
| **GNU Make** | `4.0+` | Build automation system executing targets specified in `Makefile`. |
| **OpenSSL** | `1.1.1+` | Cryptographic tool used for TLS certificate generation. |
| **cURL** | `7.0+` | CLI tool for verifying HTTP/HTTPS headers and TLS version enforcement. |

### 3. Network & Host Configuration
- **DNS Resolution**: The target domain (e.g., `sologin.42.fr`) must resolve to the loopback IP (`127.0.0.1`) or VM IP address in `/etc/hosts`:
  ```text
  127.0.0.1 sologin.42.fr
  ```
- **Port Availability**: Port `443` (HTTPS) on the host machine must be free and not bound by other web servers (such as Apache or host NGINX).

---

## 📚 Technical Terms Glossary

### 1. Virtualization & Container Primitives

- **Containerization**: OS-level virtualization method that allows running multiple isolated user-space instances (containers) sharing a single host Linux kernel.
- **Linux Namespaces**: Kernel feature providing process isolation (PID, NET, IPC, MNT, UTS, USER). For instance, PID namespaces ensure processes inside a container cannot see processes in other containers or on the host.
- **Control Groups (cgroups)**: Linux kernel feature that limits, accounts for, and isolates resource usage (CPU, memory, disk I/O, network) for a collection of processes.
- **Base Image**: The starting filesystem layer for a Docker image (e.g., `debian:bullseye`). In this project, base images must be explicit, versioned, and stable releases of Debian or Alpine (no `latest` tags allowed).

### 2. Networking & Traffic Routing

- **Reverse Proxy**: A proxy server positioned in front of web servers that forwards client requests to the appropriate backend container (e.g., NGINX forwarding PHP requests to PHP-FPM).
- **Custom Docker Bridge Network**: An isolated virtual network created by Docker Compose. Containers on the same bridge network can communicate using their container names as hostnames via Docker's embedded DNS server.
- **FastCGI**: A binary protocol for interfacing interactive programs (like PHP-FPM) with a web server (like NGINX). FastCGI maintains persistent processes to handle multiple requests efficiently.

### 3. Cryptography & Security

- **TLS (Transport Layer Security)**: Cryptographic protocol designed to provide communications security over a computer network. The subject mandates enforcing **TLSv1.2** and **TLSv1.3** only.
- **Self-Signed Certificate**: An X.509 certificate signed by its own creator rather than a trusted Certificate Authority (CA). Used for local HTTPS development.
- **Docker Secrets**: A secure mechanism for passing sensitive data (passwords, private keys) to containers. Secrets are mounted into memory (`/run/secrets/`) as temporary files (`tmpfs`), avoiding exposure in environment variables or command logs.

### 4. Process Management & Daemons

- **PID 1 (Process ID 1)**: The first process executed inside a container namespace. PID 1 has special duties in Linux (such as reaping zombie processes and handling system signals like `SIGTERM`).
- **Foreground Daemon Execution**: Running a daemon process directly in the foreground (e.g., `nginx -g "daemon off;"` or `php-fpm -F`) so that PID 1 remains active and container lifecycle is properly tracked by Docker.
- **Anti-Pattern Hacks**: Forbidden command patterns such as `tail -f /dev/null`, `sleep infinity`, or `while true; do sleep 1000; done` used to keep containers alive artificially without running an actual application process as PID 1.

### 5. Storage & Persistence

- **Docker Named Volume**: Data storage managed directly by Docker. Named volumes decouple container runtime lifecycles from persistent data.
- **Volume Driver (`local` with `bind` options)**: A Docker volume configuration option that maps container volume storage to a specific directory path on the host system (e.g., `/home/login/data/mariadb`).

---

## 🛠️ Architecture Component Mapping

| Service | Technology | Role & Behavior | Network Port |
| --- | --- | --- | --- |
| **Proxy Entrypoint** | NGINX | Accepts TLS 1.2/1.3 traffic on port 443; terminates SSL; forwards FastCGI requests to WordPress. | `443` (Exposed to Host) |
| **Application Server** | PHP-FPM + WordPress | Processes PHP scripts; executes WordPress core logic; communicates with MariaDB. | `9000` (Internal Bridge Only) |
| **Database Backend** | MariaDB | Stores WordPress tables, posts, user profiles, and configuration settings. | `3306` (Internal Bridge Only) |
