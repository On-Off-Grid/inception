# Inception Minimal VM Setup & Resource Allocation Guide

This document provides a comprehensive, step-by-step guide for setting up a resource-optimized Linux Virtual Machine (VM) tailored specifically for running the **42 / 1337 Inception** multi-container infrastructure on cluster hardware.

> **Evaluation Reference**: To review defense answers and compliance against `inception-eval-sheet.md`, consult [EVALUATION_GUIDE.md](file:///home/souhail/Desktop/Desktop/cercle_dzab/inception/EVALUATION_GUIDE.md).

---

## 1. Minimal Resource Allocation Matrix

To run the Inception stack smoothly (Debian + Docker + NGINX + MariaDB + WordPress/PHP-FPM) without causing Out-Of-Memory (OOM) errors or thrashing the cluster host system, use the following resource specifications:

| Resource | Recommended Allocation | Justification & Impact |
| :--- | :--- | :--- |
| **Operating System** | **Debian 12 (Bookworm)** or **Debian 11 (Bullseye)** | 64-bit Netinst ISO. Minimal footprint, standard for 42 curriculum. |
| **CPU / vCPU** | **2 vCPUs** | 1 vCPU slows down Docker image compilation. 2 vCPUs allow multi-threaded container builds without overloading cluster hosts. |
| **RAM (Memory)** | **2048 MB (2 GB)** | Minimal headless Debian uses ~150 MB. Active stack uses ~400–600 MB. 2 GB leaves safety margin for Docker build cache and prevents OOM panics. |
| **Storage / Disk** | **20 GB (Dynamically Allocated)** | VDI/QCOW2 dynamic allocation. Actual initial space consumed on host is only ~4–6 GB. |
| **Video RAM (VRAM)** | **16 MB (VMSVGA)** | GUI desktop is disabled (CLI server setup), minimizing graphics overhead. |
| **Network** | **NAT with Port Forwarding** | Allows guest VM internet access while exposing HTTPS (443) and SSH (22) to cluster host loopback. |

---

## 2. Hypervisor Setup (VirtualBox / UTM)

### 2.1 Create the VM Instance
1. Open **VirtualBox** (or UTM / KVM).
2. Click **New** and configure:
   - **Name**: `Inception_VM`
   - **Type**: `Linux`
   - **Version**: `Debian (64-bit)`
   - **ISO Image**: Select your downloaded `debian-xx.x.x-amd64-netinst.iso`.
3. Set **Base Memory** to `2048 MB` and **Processors** to `2`.
4. Create a **Virtual Hard Disk** (`VDI`, Dynamically Allocated) with a size of `20 GB`.

### 2.2 Configure Network Port Forwarding
Navigate to **VM Settings** ➔ **Network** ➔ **Adapter 1 (NAT)** ➔ **Advanced** ➔ **Port Forwarding**:

Add the following forwarding rules:

| Rule Name | Protocol | Host IP | Host Port | Guest IP | Guest Port |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **SSH** | TCP | `127.0.0.1` | `2222` | *(blank)* | `22` |
| **HTTPS** | TCP | `127.0.0.1` | `443` | *(blank)* | `443` |

---

## 3. Minimal Headless Debian OS Installation

1. Start the VM and select **Install** or **Graphical Install**.
2. Select Language, Location, Keyboard, and set Hostname (e.g., `inception`).
3. Set a secure **Root password**.
4. Create a regular non-root user (e.g., `<user_login>`).
5. **Partitioning**: Select **Guided - use entire disk** ➔ **All files in one partition**.
6. **Software Selection (CRITICAL STEP)**:
   - ❌ **Uncheck** `Debian desktop environment` (GNOME, XFCE, etc.). *Do not install a GUI!*
   - ✅ **Check** `SSH server`
   - ✅ **Check** `standard system utilities`
7. Complete installation, install GRUB on the primary drive, and reboot into the command line interface (CLI).

---

## 4. Post-Install User Privileges & Dependencies

Log in to the VM as `root` (or via console) to enable `sudo` and install required utilities:

```bash
# 1. Install base utilities
apt update && apt install -y sudo git curl make ca-certificates gnupg

# 2. Add user to sudoers group
usermod -aG sudo <user_login>

# 3. Switch to your user session
su - <user_login>
```

---

## 5. Install Docker Engine & Docker Compose inside VM

Execute the official Docker Engine installation steps inside the VM CLI:

```bash
# 1. Set up Docker GPG repository key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# 2. Add Docker repository source
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 3. Install Docker Packages
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 4. Configure Docker group permissions for non-root user
sudo usermod -aG docker $USER
newgrp docker
```

Verify installation:
```bash
docker --version
docker compose version
```

---

## 6. Inception Environment & Host Setup

### 6.1 Domain Resolution (`/etc/hosts`)
Inception requires mapping your login domain (e.g., `souichou.42.fr`) to loopback.

**Inside VM:**
```bash
sudo sh -c 'echo "127.0.0.1 <user_login>.42.fr" >> /etc/hosts'
```

**On Host Machine (Cluster Workstation):**
*(If accessing the site through a browser on your workstation via NAT port forwarding)*:
```bash
sudo sh -c 'echo "127.0.0.1 <user_login>.42.fr" >> /etc/hosts'
```

### 6.2 Volume Directory Storage Creation
Per project requirements, host volumes must store persistent data under `/home/<user_login>/data`:

```bash
mkdir -p /home/<user_login>/data/mariadb
mkdir -p /home/<user_login>/data/wordpress
```

---

## 7. Build, Deploy & Verify Inception Stack

1. Navigate to the project root directory inside the VM:
   ```bash
   cd /path/to/inception
   ```

2. Ensure environment secrets and `.env` file exist:
   - `srcs/.env` with `DOMAIN_NAME=<user_login>.42.fr`, `DATA_PATH=/home/<user_login>/data`
   - `secrets/db_password.txt`, `secrets/db_root_password.txt`, `secrets/wp_admin_password.txt`, `secrets/wp_user_password.txt`

3. Build images and launch services:
   ```bash
   make up
   ```

4. Verify service status and logging:
   ```bash
   make ps
   make logs
   ```

5. Test TLS compliance:
   ```bash
   curl -v -k --tlsv1.2 https://<user_login>.42.fr
   curl -v -k --tlsv1.3 https://<user_login>.42.fr
   ```

---

## 8. Resource Optimization & Maintenance Tips

- **Prune Build Cache**: Docker build cache can grow over time. Clear unused build layers with:
  ```bash
  docker builder prune -f
  ```
- **Check RAM & Disk Usage**:
  ```bash
  free -h
  df -h
  ```
