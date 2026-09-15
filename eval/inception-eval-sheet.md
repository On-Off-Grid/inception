# Inception — Evaluation Sheet (Markdown Version)

> **General instruction:**  
> For the entire evaluation process, if you don't know how to check a requirement or verify anything, the evaluated student **must help you**.

---

## ✅ Pre-Evaluation Checks

Before starting the evaluation, ensure the following:

- [ ] All files required to configure the application are located inside a `srcs` folder.  
  - The `srcs` folder must be located at the **root of the repository**.
- [ ] A `Makefile` is located at the **root of the repository**.
- [ ] Run this command in the terminal **before starting**:

```bash
docker stop $(docker ps -qa)
docker rm $(docker ps -qa)
docker rmi -f $(docker images -qa)
docker volume rm $(docker volume ls -q)
docker network rm $(docker network ls -q) 2>/dev/null
```

---

## 🚫 Automatic Failure Conditions

If any of the following is true, **the evaluation ends immediately**:

| Check | Requirement | Pass? |
|-------|-------------|-------|
| 1 | `docker-compose.yml` must **not** contain `network: host` or `links:` | ☐ Yes ☐ No |
| 2 | `docker-compose.yml` **must** contain `network` or `networks` | ☐ Yes ☐ No |
| 3 | No `--link` flag in `Makefile` or any Docker-related scripts | ☐ Yes ☐ No |
| 4 | No `tail -f` or background commands in `ENTRYPOINT` sections of Dockerfiles | ☐ Yes ☐ No |
| 5 | No `bash` or `sh` in `ENTRYPOINT` unless running a script (e.g., `nginx & bash` is forbidden) | ☐ Yes ☐ No |
| 6 | If `ENTRYPOINT` is a script (e.g., `["sh", "my_entrypoint.sh"]`), it must **not** run any program in background | ☐ Yes ☐ No |
| 7 | No infinite loops in any scripts (e.g., `sleep infinity`, `tail -f /dev/null`, `tail -f /dev/random`) | ☐ Yes ☐ No |
| 8 | `Makefile` runs successfully without crashes | ☐ Yes ☐ No |

---

## 📘 Mandatory Part

This project consists in setting up a small infrastructure composed of different services using Docker Compose.

### Project Overview

The evaluated student must explain in simple terms:

- How Docker and Docker Compose work
- The difference between a Docker image used **with** Docker Compose and **without** Docker Compose
- The benefit of Docker compared to VMs
- The pertinence of the required directory structure (as shown in the subject’s PDF)

| Question | Understood? |
|----------|-------------|
| Docker & Docker Compose explanation | ☐ Yes ☐ No |
| Image usage difference | ☐ Yes ☐ No |
| Docker vs VM benefits | ☐ Yes ☐ No |
| Directory structure justification | ☐ Yes ☐ No |

---

### Simple Setup

| Check | Requirement | Pass? |
|-------|-------------|-------|
| 1 | NGINX accessible **only** via port **443** (HTTPS) | ☐ Yes ☐ No |
| 2 | SSL/TLS certificate is used | ☐ Yes ☐ No |
| 3 | WordPress website is properly installed and configured (no installation page visible) | ☐ Yes ☐ No |
| 4 | Accessible via `https://login.42.fr/` (replace `login` with student’s login) | ☐ Yes ☐ No |
| 5 | **Not** accessible via `http://login.42.fr/` | ☐ Yes ☐ No |

> ⚠️ If anything fails here, **evaluation ends**.

---

### Docker Basics

| Check | Requirement | Pass? |
|-------|-------------|-------|
| 1 | One Dockerfile per service (no empty files) | ☐ Yes ☐ No |
| 2 | Student wrote their own Dockerfiles and built their own images (no DockerHub or ready-made images) | ☐ Yes ☐ No |
| 3 | Every container is built from the **penultimate stable version** of Alpine/Debian (e.g., `FROM alpine:X.X.X` or `FROM debian:XXXXX`) | ☐ Yes ☐ No |
| 4 | Docker image names match their corresponding service names | ☐ Yes ☐ No |
| 5 | `Makefile` sets up all services via Docker Compose (containers built, no crashes) | ☐ Yes ☐ No |

> ⚠️ If any check fails, **evaluation ends**.

---

### Docker Network

| Check | Requirement | Pass? |
|-------|-------------|-------|
| 1 | `docker-network` is used (check `docker-compose.yml`) | ☐ Yes ☐ No |
| 2 | Run `docker network ls` — a custom network is visible | ☐ Yes ☐ No |
| 3 | Student can give a simple explanation of Docker networks | ☐ Yes ☐ No |

> ⚠️ If any check fails, **evaluation ends**.

---

### NGINX with SSL/TLS

| Check | Requirement | Pass? |
|-------|-------------|-------|
| 1 | A Dockerfile exists for NGINX | ☐ Yes ☐ No |
| 2 | Container was created (check with `docker compose ps`; `-p` flag allowed if needed) | ☐ Yes ☐ No |
| 3 | Cannot access via HTTP (port 80) | ☐ Yes ☐ No |
| 4 | Can access via `https://login.42.fr/` and see configured WordPress site | ☐ Yes ☐ No |
| 5 | TLS v1.2 or v1.3 certificate is used (self-signed is acceptable) | ☐ Yes ☐ No |

> ⚠️ If any check fails, **evaluation ends**.

---

### WordPress with php-fpm and Its Volume

| Check | Requirement | Pass? |
|-------|-------------|-------|
| 1 | A Dockerfile exists for WordPress | ☐ Yes ☐ No |
| 2 | No NGINX in the WordPress Dockerfile | ☐ Yes ☐ No |
| 3 | Container was created (`docker compose ps`) | ☐ Yes ☐ No |
| 4 | A volume exists: run `docker volume ls` then `docker volume inspect <volume name>` — output must contain `/home/login/data/` | ☐ Yes ☐ No |
| 5 | Can add a comment using the available WordPress user | ☐ Yes ☐ No |
| 6 | Admin username does **not** include `admin` or `Admin` (e.g., no `admin`, `administrator`, `Admin-login`, etc.) | ☐ Yes ☐ No |
| 7 | Can edit a page from Admin dashboard and see changes on the website | ☐ Yes ☐ No |

> ⚠️ If any check fails, **evaluation ends**.

---

### MariaDB and Its Volume

| Check | Requirement | Pass? |
|-------|-------------|-------|
| 1 | A Dockerfile exists for MariaDB | ☐ Yes ☐ No |
| 2 | No NGINX in the MariaDB Dockerfile | ☐ Yes ☐ No |
| 3 | Container was created (`docker compose ps`) | ☐ Yes ☐ No |
| 4 | A volume exists: run `docker volume ls` then `docker volume inspect <volume name>` — output must contain `/home/login/data/` | ☐ Yes ☐ No |
| 5 | Student can explain how to log into the database | ☐ Yes ☐ No |
| 6 | Database is **not empty** | ☐ Yes ☐ No |

> ⚠️ If any check fails, **evaluation ends**.

---

### Persistence!

| Check | Requirement | Pass? |
|-------|-------------|-------|
| 1 | Reboot the virtual machine | ☐ Yes ☐ No |
| 2 | After reboot, launch Docker Compose again | ☐ Yes ☐ No |
| 3 | WordPress and MariaDB are functional and configured | ☐ Yes ☐ No |
| 4 | Previous WordPress changes (e.g., edited page) are still present | ☐ Yes ☐ No |

> ⚠️ If any check fails, **evaluation ends**.

---

## 📝 Notes

- Replace `login` with the evaluated student’s actual 42 login.
- All “evaluation ends now” conditions are **automatic failures**.
- Use this sheet to tick ✅ or ❌ as you go.