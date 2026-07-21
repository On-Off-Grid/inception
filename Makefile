NAME = inception
COMPOSE_FILE = srcs/docker-compose.yml
ENV_FILE = srcs/.env

# Extract LOGIN and DATA_PATH from srcs/.env
LOGIN ?= $(shell grep '^LOGIN=' $(ENV_FILE) 2>/dev/null | cut -d '=' -f2)
DATA_PATH ?= $(shell grep '^DATA_PATH=' $(ENV_FILE) 2>/dev/null | cut -d '=' -f2)

ifeq ($(DATA_PATH),)
    DATA_PATH = /home/$(LOGIN)/data
endif

.PHONY: all prepare up down start stop status logs ps build clean fclean re

all: up

prepare:
	@echo "Creating volume directories at $(DATA_PATH)..."
	@mkdir -p $(DATA_PATH)/mariadb
	@mkdir -p $(DATA_PATH)/wordpress

up: prepare
	docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) up -d --build

down:
	docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) down

start:
	docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) start

stop:
	docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) stop

status ps:
	docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) ps

logs:
	docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) logs -f

build:
	docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) build

clean: down
	docker system prune -a --force

fclean:
	@echo "Stopping stack and removing volumes..."
	docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) down -v --rmi all
	docker system prune -a --volumes --force
	@echo "Cleaning host data directories..."
	sudo rm -rf $(DATA_PATH)/mariadb/* $(DATA_PATH)/wordpress/* 2>/dev/null || rm -rf $(DATA_PATH)/mariadb/* $(DATA_PATH)/wordpress/* 2>/dev/null || true

re: fclean all
