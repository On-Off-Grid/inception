#!/usr/bin/env bash
# ==============================================================================
# Inception Evaluation Verification Suite
# Automated Mini-Scripts for Each Phase of the Evaluation Sheet
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Automatically locate root directory containing srcs/docker-compose.yml
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/srcs/docker-compose.yml" ]; then
    ROOT_DIR="$SCRIPT_DIR"
elif [ -f "$SCRIPT_DIR/../srcs/docker-compose.yml" ]; then
    ROOT_DIR="$SCRIPT_DIR/.."
else
    ROOT_DIR="."
fi

COMPOSE_FILE="$ROOT_DIR/srcs/docker-compose.yml"
ENV_FILE="$ROOT_DIR/srcs/.env"

if [ -f "$ENV_FILE" ]; then
    DOMAIN=$(grep '^DOMAIN_NAME=' "$ENV_FILE" | cut -d '=' -f2)
    LOGIN=$(grep '^LOGIN=' "$ENV_FILE" | cut -d '=' -f2)
else
    DOMAIN="localhost"
    LOGIN="user"
fi

print_header() {
    echo -e "\n${BLUE}======================================================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}======================================================================${NC}"
}

cmd_pre_eval() {
    print_header "Phase 0: Pre-Evaluation Reset Script"
    echo -e "${YELLOW}Cleaning up all Docker containers, images, volumes, and networks...${NC}"
    docker stop $(docker ps -qa) 2>/dev/null || true
    docker rm $(docker ps -qa) 2>/dev/null || true
    docker rmi -f $(docker images -qa) 2>/dev/null || true
    docker volume rm $(docker volume ls -q) 2>/dev/null || true
    docker network rm $(docker network ls -q) 2>/dev/null || true
    echo -e "${GREEN}✓ Environment cleanly reset.${NC}"
}

cmd_auto_fail() {
    print_header "Phase 1: Automatic Failure Conditions Audit"
    
    echo -n "1. Checking for 'network: host' or 'links:' in docker-compose.yml... "
    if grep -qE "network: host|links:" "$COMPOSE_FILE"; then
        echo -e "${RED}FAIL (Forbidden directives found!)${NC}"
    else
        echo -e "${GREEN}PASS${NC}"
    fi

    echo -n "2. Checking for 'networks' directive in docker-compose.yml... "
    if grep -q "networks:" "$COMPOSE_FILE"; then
        echo -e "${GREEN}PASS${NC}"
    else
        echo -e "${RED}FAIL (Missing networks directive!)${NC}"
    fi

    echo -n "3. Checking for '--link' flag in Makefile and scripts... "
    if grep -rn --exclude="eval_verification.sh" "\--link" "$ROOT_DIR/Makefile" "$ROOT_DIR/srcs/" 2>/dev/null; then
        echo -e "${RED}FAIL ('--link' found!)${NC}"
    else
        echo -e "${GREEN}PASS${NC}"
    fi

    echo -n "4. Checking for background execution or tail -f in ENTRYPOINT... "
    if grep -rn -E "ENTRYPOINT.*(&|tail -f|bash|sh)" "$ROOT_DIR/srcs/requirements/" 2>/dev/null | grep -v "\.sh"; then
        echo -e "${RED}FAIL (Unsafe ENTRYPOINT detected!)${NC}"
    else
        echo -e "${GREEN}PASS${NC}"
    fi

    echo -n "5. Checking for infinite loops (sleep infinity, tail -f /dev/null)... "
    if grep -rn -E "sleep infinity|tail -f /dev/null|tail -f /dev/random" "$ROOT_DIR/srcs/requirements/" 2>/dev/null; then
        echo -e "${RED}FAIL (Infinite loop found!)${NC}"
    else
        echo -e "${GREEN}PASS${NC}"
    fi

    echo -n "6. Checking Makefile execution... "
    if make -C "$ROOT_DIR" --dry-run >/dev/null 2>&1; then
        echo -e "${GREEN}PASS (Makefile valid)${NC}"
    else
        echo -e "${RED}FAIL (Makefile syntax error!)${NC}"
    fi
}

cmd_simple_setup() {
    print_header "Phase 2: Simple Setup Verification"

    echo -e "${YELLOW}Testing HTTPS Access on https://${DOMAIN}...${NC}"
    curl -s -k -I "https://${DOMAIN}" | head -n 5 || true

    echo -e "\n${YELLOW}Testing HTTP Access (Should fail / be unreachable):${NC}"
    if curl --connect-timeout 2 -I "http://${DOMAIN}" 2>/dev/null; then
        echo -e "${RED}FAIL: Website is accessible via HTTP!${NC}"
    else
        echo -e "${GREEN}PASS: Unreachable via HTTP (port 80).${NC}"
    fi
}

cmd_docker_basics() {
    print_header "Phase 3: Docker Basics Verification"
    
    echo -e "${YELLOW}Checking Dockerfiles existence and non-emptiness:${NC}"
    for service in mariadb wordpress nginx; do
        df="$ROOT_DIR/srcs/requirements/${service}/Dockerfile"
        if [ -s "$df" ]; then
            echo -e "  [✓] ${df} exists and is non-empty."
        else
            echo -e "  [✗] ${df} MISSING or EMPTY!"
        fi
    done

    echo -e "\n${YELLOW}Base OS Images Used:${NC}"
    grep -H "^FROM" "$ROOT_DIR"/srcs/requirements/*/Dockerfile

    echo -e "\n${YELLOW}Built Docker Images:${NC}"
    docker images
}

cmd_docker_network() {
    print_header "Phase 4: Docker Network Verification"
    
    echo -e "${YELLOW}Listing Docker Networks:${NC}"
    docker network ls

    echo -e "\n${YELLOW}Inspecting Inception Custom Network:${NC}"
    docker network inspect inception-network 2>/dev/null || docker network ls
}

cmd_nginx() {
    print_header "Phase 5: NGINX with SSL/TLS Verification"
    
    echo -e "${YELLOW}Container Status:${NC}"
    docker compose -f "$COMPOSE_FILE" ps nginx

    echo -e "\n${YELLOW}Verifying SSL/TLS Protocol Version:${NC}"
    echo | openssl s_client -connect "${DOMAIN}:443" -servername "${DOMAIN}" 2>/dev/null | grep -E "Protocol|Cipher" || true
}

cmd_wordpress() {
    print_header "Phase 6: WordPress + PHP-FPM Verification"
    
    echo -e "${YELLOW}Container Status:${NC}"
    docker compose -f "$COMPOSE_FILE" ps wordpress

    echo -e "\n${YELLOW}Checking for forbidden NGINX in WordPress Dockerfile:${NC}"
    if grep -qi "nginx" "$ROOT_DIR/srcs/requirements/wordpress/Dockerfile"; then
        echo -e "${RED}FAIL: NGINX installed in WordPress container!${NC}"
    else
        echo -e "${GREEN}PASS: NGINX not present in WordPress container.${NC}"
    fi

    echo -e "\n${YELLOW}Inspecting WordPress Volume:${NC}"
    docker volume inspect wordpress_data 2>/dev/null || true

    echo -e "\n${YELLOW}Listing WordPress Users:${NC}"
    docker exec -it wordpress wp user list --allow-root --path=/var/www/wordpress 2>/dev/null || true
}

cmd_mariadb() {
    print_header "Phase 7: MariaDB Verification"
    
    echo -e "${YELLOW}Container Status:${NC}"
    docker compose -f "$COMPOSE_FILE" ps mariadb

    echo -e "\n${YELLOW}Checking for forbidden NGINX in MariaDB Dockerfile:${NC}"
    if grep -qi "nginx" "$ROOT_DIR/srcs/requirements/mariadb/Dockerfile"; then
        echo -e "${RED}FAIL: NGINX installed in MariaDB container!${NC}"
    else
        echo -e "${GREEN}PASS: NGINX not present in MariaDB container.${NC}"
    fi

    echo -e "\n${YELLOW}Inspecting MariaDB Volume:${NC}"
    docker volume inspect mariadb_data 2>/dev/null || true

    echo -e "\n${YELLOW}Checking Database Contents (Tables & Posts):${NC}"
    if [ -f "$ROOT_DIR/secrets/db_root_password.txt" ] && [ -s "$ROOT_DIR/secrets/db_root_password.txt" ]; then
        ROOT_PW=$(cat "$ROOT_DIR/secrets/db_root_password.txt")
        docker exec -i mariadb mariadb -u root -p"${ROOT_PW}" -e "SHOW DATABASES; USE wordpress; SHOW TABLES; SELECT COUNT(*) AS total_posts FROM wp_posts;" 2>/dev/null || echo -e "${YELLOW}(Container running, check manually via exec if secrets restricted)${NC}"
    fi
}

cmd_persistence() {
    print_header "Phase 8: Persistence Verification"
    
    echo -e "${YELLOW}Checking Host Mounted Volumes on Disk:${NC}"
    ls -la /home/*/data/mariadb /home/*/data/wordpress 2>/dev/null || ls -la /home/${LOGIN}/data/* 2>/dev/null || true

    echo -e "\n${YELLOW}Checking Data Integrity:${NC}"
    docker compose -f "$COMPOSE_FILE" ps
}

usage() {
    echo "Usage: $0 {pre-eval|auto-fail|simple-setup|docker-basics|docker-network|nginx|wordpress|mariadb|persistence|all}"
    exit 1
}

case "$1" in
    pre-eval)        cmd_pre_eval ;;
    auto-fail)       cmd_auto_fail ;;
    simple-setup)    cmd_simple_setup ;;
    docker-basics)   cmd_docker_basics ;;
    docker-network)  cmd_docker_network ;;
    nginx)           cmd_nginx ;;
    wordpress)       cmd_wordpress ;;
    mariadb)         cmd_mariadb ;;
    persistence)     cmd_persistence ;;
    all)
        cmd_auto_fail
        cmd_simple_setup
        cmd_docker_basics
        cmd_docker_network
        cmd_nginx
        cmd_wordpress
        cmd_mariadb
        cmd_persistence
        ;;
    *) usage ;;
esac
