.PHONY: default

include .env

default:
	@echo "Usage:"
	@echo "  make up-infra      Start infra stack"
	@echo "  make down-infra    Stop infra stack"
	@echo "  make logs-infra    Tail logs"
	@echo "  make ps-infra      Show containers"

up-infra:
	docker compose --env-file .env -f compose/infra/docker-compose.yml up -d

down-infra:
	docker compose --env-file .env -f compose/infra/docker-compose.yml down --remove-orphans

logs-infra:
	docker compose --env-file .env -f compose/infra/docker-compose.yml logs -f

ps-infra:
	docker compose --env-file .env -f compose/infra/docker-compose.yml ps

restart-infra: down-infra up-infra

gen-certs:
	@echo "Generating certificates for *.$(HOST_DOMAIN) and $(HOST_DOMAIN)"

	mkcert "*.$(HOST_DOMAIN)" "$(HOST_DOMAIN)"
	mv *.pem ${LAB_DIR}/config/traefik/certs/