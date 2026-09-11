# User Operations Guide & Utilisation Sheet (USER_DOC.md)

This document serves as the complete operational sheet for initializing, managing, testing, and cleaning up the **Inception** multi-container infrastructure stack.

---

## 1. Prerequisites & Environment Setup

### System Requirements
- **Operating System**: Linux Virtual Machine (Debian/Ubuntu recommended).
- **Core Dependencies**: `docker`, `docker compose`, `make`, `curl`, and `sudo` access.
- **Port Availability**: Port `443` on the host machine must be free.

### Domain Configuration
Map the host loopback IP address to your 42 domain name (`login.42.fr`, e.g., `souichou.42.fr`) in `/etc/hosts`:
```bash
sudo sh -c 'echo "127.0.0.1 souichou.42.fr" >> /etc/hosts'
```

---

## 2. Infrastructure Utilisation Sheet

### Step A: Stack Initialization
To set up volume directories, build all custom Docker images, and start containers in detached mode:

```bash
make up
```

> **Note**: `make up` automatically runs `make prepare` first to create persistent data storage paths under `${DATA_PATH}` (e.g., `/home/souichou/data/mariadb` and `/home/souichou/data/wordpress`).

### Step B: Verification & Monitoring
After running `make up`, monitor and verify that all three containers (`mariadb`, `wordpress`, `nginx`) are active and healthy:

1. **Check process status**:
   ```bash
   make ps
   ```
   *All containers should display status `Up` or `Up (healthy)`.*

2. **Stream service logs**:
   ```bash
   make logs
   ```

3. **Verify TLS protocol compliance**:
   ```bash
   # Test TLSv1.2 connection
   curl -v -k --tlsv1.2 https://souichou.42.fr

   # Test TLSv1.3 connection
   curl -v -k --tlsv1.3 https://souichou.42.fr
   ```

4. **Access WordPress Web Interface**:
   Open a web browser and navigate to:
   `https://souichou.42.fr`
   *(Accept the self-signed certificate notice when prompted).*

5. **Evaluation Verification Commands**:
   - **Inspect Named Volumes**:
     ```bash
     docker volume inspect mariadb_data wordpress_data
     ```
     *(Verify `device` path points to `/home/<login>/data/...`)*

   - **Inspect Custom Network**:
     ```bash
     docker network inspect inception-network
     ```
     *(Verify all 3 containers are attached to `inception-network`)*

   - **Log into MariaDB Database**:
     ```bash
     docker exec -it mariadb mysql -u root -p
     ```
     *(Enter password from `secrets/db_root_password.txt`)*

   - **Evaluation Defense Walkthrough**:
     See [EVALUATION_GUIDE.md](file:///home/souhail/Desktop/Desktop/cercle_dzab/inception/EVALUATION_GUIDE.md) for full answers to theoretical questions and complete evaluation criteria checklist.

---

## 3. Routine Lifecycle Operations

| Operation | Command | Description |
| --- | --- | --- |
| **Start Stack** | `make start` | Resumes existing stopped containers without rebuilding. |
| **Stop Stack** | `make stop` | Pauses running containers without destroying them. |
| **Rebuild & Restart** | `make re` | Performs full teardown, rebuilds images, and restarts stack. |
| **View Logs** | `make logs` | Streams real-time stdout/stderr from all containers. |
| **Check Status** | `make ps` | Displays status of all managed containers. |

---

## 4. Stack Cleanup & Teardown

Depending on the desired level of cleanup, execute one of the following procedures:

### Option 1: Basic Teardown (Preserve Data & Images)
Stops containers and removes container instances and network bridges while preserving persistent volume data on disk:
```bash
make down
```

### Option 2: Soft System Prune (Remove Stopped Containers & Build Cache)
Stops containers and prunes unused Docker system resources without deleting persistent volumes:
```bash
make clean
```

### Option 3: Full Purge & Reset (`fclean`)
Stops all services, removes containers, networks, volume definitions, and images, and **completely wipes host persistent data directories** under `/home/login/data`:
```bash
make fclean
```

> ⚠️ **Warning**: Running `make fclean` permanently deletes all WordPress site uploads, database records, and site configurations.

---

## 5. Credentials & Secrets Reference

Confidential parameters are managed via local Docker secrets in the `/secrets/` directory:
- `secrets/db_root_password.txt`: Administrative password for MariaDB `root`.
- `secrets/db_password.txt`: Database password for WordPress MySQL user.
- `secrets/wp_admin_password.txt`: Password for WordPress administrator (`WP_ADMIN_USER`).
- `secrets/wp_user_password.txt`: Password for regular WordPress author user (`WP_USER`).

> 🛑 **Security Requirement**: The administrator username (`WP_ADMIN_USER`) is set to `site_supervisor` in `srcs/.env`. Per 42 rules, admin usernames **must not** contain `admin` or `administrator` in any case format.
