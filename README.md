*This project has been created as part of the 42 curriculum by souichou.*

# Inception System Administration Project

## Description

Inception is a system-administration project that builds a small web infrastructure using Docker and Docker Compose. The objective is to understand containerization, service isolation, networking, persistent storage, TLS, and the relationships between a web server, PHP-FPM, WordPress, and a database.

The infrastructure contains three dedicated services:

- **NGINX**: the only public entrypoint, exposed through HTTPS on port 443 and configured for TLS 1.2 and TLS 1.3.
- **WordPress + PHP-FPM**: the application service. It contains WordPress and PHP-FPM, but not NGINX.
- **MariaDB**: the database service. It contains MariaDB only.

All application images are built locally from custom Dockerfiles based on Debian. The services communicate through a dedicated Docker bridge network. WordPress files and MariaDB data are stored in Docker named volumes whose host data is located under `/home/souichou/data`.

## Architecture

```text
                         Client / Browser
                                |
                         HTTPS :443
                         TLS 1.2 / 1.3
                                |
                    +-----------------------+
                    |   NGINX container     |
                    |   Public entrypoint   |
                    +-----------------------+
                                |
                         FastCGI :9000
                    inception-network
                                |
                    +-----------------------+
                    | WordPress + PHP-FPM   |
                    +-----------------------+
                                |
                          MariaDB :3306
                    inception-network
                                |
                    +-----------------------+
                    |   MariaDB container   |
                    +-----------------------+
```

## Project structure

```text
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── PULL_REQUEST.md
├── secrets/                         # local only; excluded from Git
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

## Design choices

### Why Docker is used

Docker packages each service and its runtime dependencies into an isolated container. This makes the infrastructure reproducible while keeping NGINX, WordPress/PHP-FPM, and MariaDB independent. Each service can be built, started, stopped, inspected, and restarted separately.

The project uses custom Dockerfiles rather than ready-made WordPress, NGINX, or MariaDB images. This makes the installation and configuration steps explicit and satisfies the project requirement to build the service images locally.

### Virtual machines vs Docker

| Virtual machines | Docker containers |
|---|---|
| Virtualize a complete guest operating system. | Isolate application processes while sharing the host kernel. |
| Usually require more CPU, memory, and disk space. | Usually start faster and use fewer resources. |
| Provide strong OS-level separation. | Provide process, filesystem, and network isolation. |
| Suitable when different operating systems or kernels are required. | Suitable for packaging and connecting application services. |

The Inception project uses both concepts for different reasons: the project runs inside a VM, while Docker provides the service-level infrastructure inside that VM.

### Secrets vs environment variables

| Secrets | Environment variables |
|---|---|
| Intended for passwords, private keys, and other confidential values. | Suitable for non-sensitive configuration such as domain names and service names. |
| Mounted or exposed to a container as protected files, commonly under `/run/secrets/`. | Injected into the process environment and can be visible through inspection or debugging tools. |
| Reduce the risk of accidentally embedding credentials in an image. | Convenient for configuration and Compose substitution. |

This project keeps passwords in local files under `secrets/` and excludes them from Git. The `.env` file is used for configuration values and Compose substitution. Credentials must never be written into Dockerfiles or committed to the repository.

### Docker network vs host network

| Docker network | Host network |
|---|---|
| Gives containers an isolated network namespace. | Makes a container use the host’s network namespace. |
| Containers can communicate through service names such as `mariadb` and `wordpress`. | Services bind directly to host network interfaces. |
| Only explicitly published ports are reachable from outside. | Isolation is reduced and port conflicts are more likely. |

The project uses a user-defined bridge network named `inception-network`. Only NGINX publishes port 443; MariaDB and PHP-FPM remain reachable only inside the Docker network.

### Docker named volumes vs bind mounts

| Docker named volumes | Bind mounts |
|---|---|
| Managed by Docker and referenced by a stable volume name. | Directly maps a chosen host path into a container. |
| Designed for persistent application data. | Useful when the host must directly edit or provide files. |
| Hide many host filesystem details from the application configuration. | More dependent on host paths, ownership, and permissions. |

This project uses two named volumes: one for MariaDB data and one for WordPress files. Their data is stored under `/home/souichou/data`, as required by the subject. Bind mounts are not used for these persistent storages.

## Instructions

### Prerequisites

- A Linux virtual machine.
- Docker Engine.
- Docker Compose plugin, providing the `docker compose` command.
- Git.
- Permission to run Docker commands, either through the Docker group or with `sudo`.

### Configure the domain

Add the local domain to the VM’s hosts file:

```bash
echo "127.0.0.1 souichou.42.fr" | sudo tee -a /etc/hosts
```

If the VM is accessed from another machine, replace `127.0.0.1` with the VM’s reachable IP address.

### Configure local secrets

Create the required files inside `secrets/` and place one value in each file:

```text
secrets/db_password.txt
secrets/db_root_password.txt
secrets/wp_admin_password.txt
secrets/wp_user_password.txt
```

Do not commit these files. Confirm that they are ignored by Git before pushing the repository.

### Configure environment variables

Copy the example environment file and adjust it to the local setup:

```bash
cp srcs/.env.example srcs/.env
```

At minimum, verify the domain name, database name, database user, WordPress administrator username, and WordPress regular username. The administrator username must not contain `admin` or `administrator`.

### Build and launch

From the repository root:

```bash
make up
```

The Makefile creates the required data directories, builds the custom images, and starts the Compose project.

Check the service status:

```bash
make ps
# or
cd srcs && docker compose ps
```

View logs:

```bash
cd srcs && docker compose logs -f
```

### Access the application

- Website: [https://souichou.42.fr](https://souichou.42.fr)
- WordPress administration panel: [https://souichou.42.fr/wp-admin](https://souichou.42.fr/wp-admin)

Because the certificate is local or self-signed, a browser may display a certificate warning during development.

Test TLS versions:

```bash
curl -v -k --tlsv1.2 https://souichou.42.fr
curl -v -k --tlsv1.3 https://souichou.42.fr
```

### Stop and clean the project

```bash
make stop      # stop running containers
make down      # stop containers and remove the Compose resources
make clean     # remove unused Docker resources, according to the Makefile
make fclean    # full reset, including project data, according to the Makefile
```

Check the Makefile before running `make fclean`, because the full reset deletes persistent project data.

## Verification checklist

- Only NGINX publishes a host port, and that port is 443.
- NGINX accepts TLS 1.2 and TLS 1.3 only.
- WordPress and MariaDB are separate containers.
- WordPress uses PHP-FPM and does not contain NGINX.
- MariaDB data and WordPress files survive container recreation.
- The two persistent storages are Docker named volumes.
- Containers use the custom `inception-network`, not host networking or links.
- Services restart after a failure.
- No Dockerfile contains a password.
- No `latest` tag is used.
- Secrets and `.env` files containing credentials are not committed.
- The WordPress administrator username does not contain `admin` or `administrator`.

## Resources

The following resources were selected to explain the concepts used in this project from beginner level through implementation details.

### Docker fundamentals

- [Docker: Get started](https://docs.docker.com/get-started/) — official beginner tutorial covering the first containers and basic workflow.
- [Docker overview](https://docs.docker.com/get-started/docker-overview/) — official explanation of images, containers, the Docker daemon, networks, and volumes.
- [Docker Getting Started repository](https://github.com/docker/getting-started) — practical exercises for running containers, building images, using volumes, networking, and Compose.
- [Docker tutorial for beginners](https://spacelift.io/blog/docker-tutorial) — an additional beginner-friendly explanation of images, containers, and common commands.

### Dockerfiles and Compose

- [Dockerfile reference](https://docs.docker.com/reference/dockerfile/) — syntax and behavior of Dockerfile instructions such as `FROM`, `RUN`, `COPY`, `CMD`, and `ENTRYPOINT`.
- [How Compose works](https://docs.docker.com/compose/intro/compose-application-model/) — official explanation of services, networks, volumes, secrets, and Compose files.
- [Docker Compose CLI reference](https://docs.docker.com/reference/cli/docker/compose/) — commands for building, starting, stopping, inspecting, and viewing logs.
- [Docker volumes documentation](https://docs.docker.com/engine/storage/volumes/) — official reference for persistent named volumes.
- [Docker networking documentation](https://docs.docker.com/engine/network/) — official explanation of container networks and service communication.
- [Docker secrets documentation](https://docs.docker.com/engine/swarm/secrets/) — official reference for managing sensitive values as secrets.

### NGINX, FastCGI, and TLS

- [NGINX Beginner’s Guide](https://nginx.org/en/docs/beginners_guide.html) — explains NGINX processes, configuration blocks, static files, proxying, and FastCGI.
- [NGINX documentation](https://nginx.org/en/docs/) — official documentation and administration reference.
- [Configuring HTTPS servers with NGINX](https://nginx.org/en/docs/http/configuring_https_servers.html) — official certificate, private-key, and TLS protocol configuration guide.
- [NGINX proxy module](https://nginx.org/en/docs/http/ngx_http_proxy_module.html) — reference for forwarding requests to another service.
- [PHP-FPM manual](https://www.php.net/manual/en/install.fpm.php) — official explanation of PHP’s FastCGI Process Manager.
- [PHP-FPM configuration](https://www.php.net/manual/en/install.fpm.configuration.php) — reference for foreground execution and process-pool configuration.
- [How to configure PHP-FPM with NGINX](https://www.digitalocean.com/community/tutorials/php-fpm-nginx) — practical explanation of the NGINX-to-PHP-FPM request flow.

### WordPress and MariaDB

- [WordPress documentation](https://wordpress.org/documentation/) — official documentation for installation, administration, publishing, and site maintenance.
- [Get started with WordPress](https://wordpress.org/documentation/article/get-started-with-wordpress/) — official overview of planning, installing, and configuring WordPress.
- [WordPress administration and users](https://wordpress.org/documentation/category/dashboard/) — documentation for the dashboard, users, roles, settings, and site management.
- [Learn WordPress: Beginner WordPress User](https://learn.wordpress.org/course/beginner-wordpress-user/) — official beginner course with guided lessons.
- [MariaDB documentation](https://mariadb.com/docs/) — official documentation for installation, SQL, users, privileges, and administration.
- [MariaDB getting started resources](https://mariadb.com/docs/general-resources) — entry point for MariaDB documentation and learning materials.

### Video resources

- [The Only Docker Tutorial You Need To Get Started](https://www.youtube.com/watch?v=DQdB7wFEygo) — beginner-oriented Docker walkthrough.
- [How to Install Linux on a Virtual Machine using VirtualBox](https://www.youtube.com/watch?v=YjG1yG2l9v0) — useful before beginning the VM-based project.
- [WordPress Tutorial for Beginners](https://www.youtube.com/watch?v=zd5_MN-6kqs) — introduces WordPress installation, the dashboard, themes, plugins, and basic site management.

### How AI was used

AI was used as a learning and review assistant, not as a substitute for understanding or testing. It was used for:

- Breaking down the Inception subject into mandatory requirements and an implementation roadmap.
- Explaining unfamiliar concepts such as Docker images, containers, Compose services, named volumes, bridge networks, NGINX, TLS, PHP-FPM, and MariaDB.
- Suggesting beginner-friendly documentation, articles, and videos for further study.
- Reviewing the README structure against the official project requirements.
- Helping identify documentation gaps and improve the clarity of commands and explanations.

All AI-suggested commands and configuration decisions were reviewed, tested in the VM, and understood before inclusion in the project. Official Docker, NGINX, PHP, WordPress, and MariaDB documentation remains the authoritative reference.

## Author

- **souichou** — 42 student
