# Inception Mandatory Part Requirements and Implementation Roadmap

## Overview

This report analyzes the "Mandatory part" of the Inception system administration project and summarizes all technical and organizational requirements that must be met for validation.[^1]
It then proposes a practical, staged roadmap to implement the required Docker-based infrastructure cleanly and in compliance with the subject constraints.[^1]

[^1]

## Mandatory Requirements Summary

### Execution environment and tooling

- The entire project must run inside a virtual machine; all development and testing of the infrastructure are expected to happen there.[^1]
- The stack must be orchestrated using Docker Compose, with all configuration files stored under a `srcs` directory and a root `Makefile` that builds images and launches the stack via `docker-compose.yml`.[^1]
- Each service must have its own Docker image with the same name as the service, and each service must run in its own dedicated container.[^1]

### Base images and image-building rules

- Containers must be built from either the penultimate stable version of Alpine or Debian, chosen consistently per service; using other base distributions or arbitrary images is not allowed.[^1]
- Every image must be built from a custom Dockerfile written as part of the project, one Dockerfile per service, referenced by `docker-compose.yml` and built via the `Makefile`.[^1]
- Pulling prebuilt application images (except the allowed Alpine/Debian base images) or using services such as Docker Hub for ready-made images is explicitly forbidden.[^1]

### Core services to implement

- An NGINX container serving as the public entrypoint, configured to accept only TLSv1.2 or TLSv1.3 over HTTPS on port 443.[^1]
- A WordPress container running WordPress with php-fpm only (no NGINX in this container), with WordPress fully installed and configured.[^1]
- A MariaDB container running only MariaDB (no NGINX), providing the database backend for WordPress.[^1]

### Storage and persistence

- A Docker named volume that stores the WordPress database data.[^1]
- A second Docker named volume that stores the WordPress site files (core, themes, plugins, uploads, etc.).[^1]
- Both named volumes must persist their data under `/home/login/data` on the host machine, where `login` is replaced with the learner’s own 42 login.[^1]
- Bind mounts are not permitted for these two persistent storages; only named volumes are allowed for database and WordPress files.[^1]

### Networking and container behavior

- A custom Docker network must be created to connect all containers; this network must be explicitly defined in `docker-compose.yml`.[^1]
- `network: host`, `--link`, or `links:` directives are forbidden; connectivity must rely on the user-defined Docker network and proper service names and ports.[^1]
- Containers must be configured with restart policies so that they automatically restart in case of a crash.[^1]
- Containers must not be started with hacky infinite-loop commands such as `tail -f`, `bash`, `sleep infinity`, or `while true`, including in entrypoints or entrypoint scripts.[^1]

### WordPress database and users

- The WordPress database must contain at least two users, one of whom is the administrator of the WordPress site.[^1]
- The administrator’s username must not contain the substrings `admin`, `Admin`, `administrator`, or `Administrator` in any form (e.g., `admin`, `administrator`, `Admin-123` are all invalid).[^1]

### Domain name and access

- A domain name of the form `login.42.fr` must be configured so that it resolves to the local IP address of the virtual machine, where `login` is the learner’s own 42 login.[^1]
- The NGINX container must be the sole entrypoint to the infrastructure from the outside, listening only on port 443 with TLSv1.2 or TLSv1.3, and proxying traffic to the internal WordPress/PHP-FPM and database services.[^1]

### Security, environment, and secrets

- The `latest` tag must not be used for Docker images; explicit, versioned tags are required.[^1]
- No passwords may appear in any Dockerfile; sensitive data must not be hardcoded in images.[^1]
- Environment variables are mandatory for configuration, and a `.env` file must be used to store them for Docker Compose consumption.[^1]
- It is strongly recommended to use Docker secrets or similar mechanisms to store credentials, API keys, and passwords, and any such confidential information must not be committed to the Git repository.[^1]
- Any credentials, API keys, or passwords found in the Git repository (outside of properly configured secrets) will cause the project to fail.[^1]

### Directory structure and supporting files

- The project must follow a directory structure similar to the example, with `srcs/docker-compose.yml`, `srcs/.env`, and per-service subdirectories under `srcs/requirements` (e.g., `nginx`, `mariadb`, `wordpress`), each containing its Dockerfile, configuration, and tools.[^1]
- A `secrets` directory is expected at the project root (outside `srcs`), containing local-only files such as passwords and credentials that are ignored by Git and used by Docker secrets or environment-loading mechanisms.[^1]

## Implementation Roadmap

### Phase 1 – Understand the subject and prepare the VM

1. Carefully read the entire Inception subject, focusing on the "Mandatory part" plus the security notes and directory examples to internalize all constraints and naming rules.[^1]
2. Create or reuse a Linux virtual machine (e.g., on VirtualBox, UTM, or a cloud VM) and ensure Docker Engine and Docker Compose are installed and working correctly.
3. Set up Git in the VM, create the project repository, and configure `.gitignore` to exclude secrets (e.g., `secrets/`, `.env`, password files) from version control in line with the subject’s security requirements.[^1]

### Phase 2 – Initialize project structure and tooling

1. At the repository root, create the `Makefile`, `srcs/`, and `secrets/` directories, plus the `srcs/requirements` hierarchy with subfolders for `nginx`, `mariadb`, and `wordpress` (and optionally `tools`).[^1]
2. Draft a minimal `srcs/docker-compose.yml` defining the three core services, a user-defined Docker network, and two named volumes (e.g., `wp_db_data` and `wp_site_data`).[^1]
3. Add a placeholder `srcs/.env` file with variables for database credentials, domain name, and other configuration, ensuring it is excluded from Git and will later be used by Docker Compose.[^1]
4. In the `secrets/` directory, create local files for database root password, database user password, and application credentials, and wire them into the compose file via environment variables or Docker secrets without committing them.[^1]

### Phase 3 – Implement the MariaDB service

1. In `srcs/requirements/mariadb/`, write a Dockerfile based on the penultimate stable Alpine or Debian image, installing and configuring MariaDB server.[^1]
2. Configure MariaDB initialization scripts (e.g., in a `tools` or `conf` subdirectory) to create the WordPress database, the dedicated WordPress DB user, and at least two WordPress users in the application’s schema, ensuring credentials are injected from environment variables.[^1]
3. Mount the named volume for database storage in the MariaDB service configuration so that data persists under `/home/login/data` on the host, respecting the host-path mapping rules in `docker-compose.yml`.[^1]
4. Set an appropriate restart policy (such as `restart: always` or `on-failure`) and avoid any hacky `tail -f` entrypoints; rely on the database daemon process as PID 1.[^1]

### Phase 4 – Implement the WordPress + php-fpm service

1. In `srcs/requirements/wordpress/`, create a Dockerfile from the chosen base (Alpine or Debian), installing PHP, php-fpm, and all required PHP extensions for WordPress.[^1]
2. Download and configure WordPress during image build or container startup, using environment variables for database connection details and admin user information.[^1]
3. Ensure the container exposes the php-fpm port (e.g., 9000) and does not run any web server; it should only run php-fpm as the main process.[^1]
4. Mount the named volume for WordPress files to the correct directory (e.g., `/var/www/wordpress`), mapping it to `/home/login/data` on the host via a named volume.[^1]
5. Configure at least two WordPress users, including an administrator whose username does not contain any forbidden `admin` or `administrator` substrings, created either via CLI scripts or initial setup automation.[^1]

### Phase 5 – Implement the NGINX TLS reverse proxy

1. In `srcs/requirements/nginx/`, create a Dockerfile from Alpine or Debian installing NGINX and OpenSSL (or equivalent tools) needed to manage TLS certificates.[^1]
2. Generate or import TLS certificates for the `login.42.fr` domain, keeping private keys in the `secrets/` directory or equivalent secure storage and mounting them read-only into the NGINX container.[^1]
3. Write NGINX configuration to listen on port 443 only, enforce TLSv1.2 and TLSv1.3 protocols, and proxy PHP requests to the WordPress php-fpm container via the internal Docker network.[^1]
4. Configure NGINX as the sole public entrypoint in `docker-compose.yml` by publishing only port 443 on the host, with no other service exposing ports to the host.[^1]
5. Add appropriate health or basic checks if desired, and ensure the container uses a proper daemon process rather than any infinite-loop shell tricks.[^1]

### Phase 6 – Compose, networking, and restart policies

1. Finalize the `docker-compose.yml` file to
   - Define the custom Docker network.
   - Attach all three services to it.
   - Configure the two named volumes with host paths under `/home/login/data`.
   - Define image names matching service names.
   - Set explicit image tags (no `latest`).[^1]
2. Ensure each service has a `restart` policy and that no `network: host`, `--link`, or `links:` options are used anywhere in the configuration.[^1]
3. Configure dependencies between services (e.g., `depends_on`) so that MariaDB is available before WordPress tries to connect, while still handling restarts gracefully.

### Phase 7 – Makefile, domain, and environment integration

1. Implement the root `Makefile` with targets such as `make up`, `make down`, `make build`, and `make clean`, which call Docker Compose to build the images and manage the containers using the `srcs/docker-compose.yml` file.[^1]
2. Configure the `.env` file to hold variables like `DOMAIN_NAME=login.42.fr`, database credentials, and other settings, and ensure Docker Compose correctly injects these into containers.[^1]
3. On the VM host, update `/etc/hosts` (or local DNS) so that `login.42.fr` resolves to the VM’s IP address, matching the subject requirement.[^1]

### Phase 8 – Testing, hardening, and clean-up

1. Rebuild and start the full stack using the Makefile, then verify that
   - NGINX serves the site over HTTPS using TLSv1.2 or TLSv1.3.
   - The WordPress site is reachable via `https://login.42.fr`.
   - Database data and WordPress files persist across container restarts and rebuilds.
   - Containers restart automatically after simulated crashes.[^1]
2. Inspect container logs and configuration to confirm there are no hardcoded passwords in Dockerfiles, no use of the `latest` tag, and no disallowed network directives or entrypoint hacks such as `tail -f`.[^1]
3. Perform a full teardown (`docker compose down -v`) and redeploy to ensure the environment can be reliably recreated from the repository plus local secrets and `.env` files.

### Phase 9 – Documentation and final polish

1. Write or finalize the `README.md` describing the stack, how to run it, Docker usage, and design choices and comparisons (VM vs Docker, secrets vs env vars, Docker network vs host network, Docker volumes vs bind mounts), respecting the subject’s README requirements.[^1]
2. Create `USER_DOC.md` and `DEV_DOC.md` at the repository root, documenting user operations (start/stop, access, credential management, health checks) and developer workflows (setup from scratch, building, managing containers and volumes, data persistence locations).[^1]
3. Run a final self-review against the subject checklist to verify every mandatory requirement is met and that no forbidden practices (public credentials, `latest` tags, wrong admin username, non-TLS access, etc.) remain.[^1]

---

## References

1. [Inceptionn.pdf](https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/collection_90d94f5a-4690-4007-97a1-d886c4ba91d2/e4e9f883-8f8d-4160-b1de-054da1932109/Inceptionn.pdf?AWSAccessKeyId=ASIA2F3EMEYESJGKDBHV&Signature=TgxVKHYg5%2F%2BrsynUKpgA66sLBqc%3D&x-amz-security-token=IQoJb3JpZ2luX2VjEPX%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaCXVzLWVhc3QtMSJHMEUCIBJiSwm73xkQzQ0gfEbcrXXnMkld6dRugUtL796hc0IIAiEA2EaRG%2BFrRC8E7gtSsa7j9DX%2BhGlbmYkgQisuwc20zuoq%2FAQIvv%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FARABGgw2OTk3NTMzMDk3MDUiDJu%2BPnWEFbytXnjKGyrQBBJPS%2FWwhdFVBJBmk743c2jzIT57DY5OAXWz7l3FSckWlWFIjNMDKBXtRNMPzSEix%2ByALLt4keQfv2Yl3mysFXM%2B%2BPvoJh2UDttfaaFfcgygg52hAEpADAWyrNoJkgjwziZgqPLiJydm5XyBi%2FqYCyW%2BP8oc7W7UoVdcB2Jen%2FddI3kzrGuSE6mBE2YG4%2BvMzHdxkA%2FOwTtpP5i%2FfqBf7CDCBePMu1mdEeY6suq9tJVdXIsWU78z3%2BSgZxrON7N%2FgifztVQx0wDQOkTwUehHfBwoENESp6lOtLNl6oqTrih%2BskLHdcE%2B2%2BUcRGC1qSJse5nEabTENeWTXchtITwFcLgsScOLSyOiM%2FJG3cJ0%2BCGYMM1kGfjXtzVOgAbuT6xdhpgVyZz6dtiZrz5nD1uDQVegvvouMM4wIRT8he1NRNeRKaghmYIWIcnEpIXGps0zrMLwliokVgznGzwpg9o0V%2BmXKu6f1SeXDUAiNgzEDzyim19HjYTq6m0uIPUe2VBcA3Wx3iIaYiz22C%2FibbiJ2eR9QFomUk5zVV653ICB05As3Ad%2FbGBYNNwOHjuFSZlbbo%2BqCK6jo95Bc2ZUlxN3JCjU6Yan81wwsn159xYjjAqBgjiE5KKHQFG01qOaEuucC3CMUha4288d25bM0awl0P1De0L3e4bzobNVHzTMq3Djzcbq2z%2BCYYMhyYHKoTEXP%2FmiFiOpILrMt0Ti0mHNkXkx4wS7co3pCVZVezSM%2B9PGWPGFgT%2Fs9ge1S6W27aSlCqJ2X%2BnEzdQGp26rhYFauD0w0Mr90gY6mAGSOLNncZwPF605Q1JYOgqx9x9oCeI5uJbqkchL7tqNWpbSEvEf9dvhgudODUG1Jb4f0DLkQXN1OWros8BS%2Fcoi4EraqFE5UsR1Di03D6cf4MZCiY%2BzD3D3QWc7m5aPY14ip66AVj7sGtXn0izez1SztKphJfzsMFTisUoP%2FZwn1%2F%2F0i%2FZHHF6kqRGgPlfXcQ2Ut5QEX1sO6g%3D%3D&Expires=1784640291) - ![Inception](image_path_1)

# Inception

Summary: This document is a System Administration related e...

