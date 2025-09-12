.PHONY: default

include .env

DOCKER_INFRA = docker compose --env-file .env -f compose/infra/docker-compose.yml
DOCKER_INFRA_PROD = ${DOCKER_INFRA} -f compose/infra/docker-compose.prod.yml

default:
	@echo "Usage:"
	@echo "  make up-infra-prod      Start infra stack (PROD)"
	@echo "  make down-infra-prod    Stop infra stack (PROD)"
	@echo "  make logs-infra-prod    Tail logs (PROD)"
	@echo "  make ps-infra-prod      Show containers (PROD)"
	@echo "  										"
	@echo "  make up-infra      Start infra stack"
	@echo "  make down-infra    Stop infra stack"
	@echo "  make logs-infra    Tail logs"
	@echo "  make ps-infra      Show containers"

# Prod environment

up-infra-prod:
	${DOCKER_INFRA_PROD} up -d

down-infra-prod:
	${DOCKER_INFRA_PROD} down --remove-orphans

logs-infra-prod:
	${DOCKER_INFRA_PROD} logs -f

ps-infra-prod:
	${DOCKER_INFRA_PROD} ps

restart-infra-prod: down-infra-prod up-infra-prod

# Local environment

up-infra:
	${DOCKER_INFRA} --profile headscale up -d

up-infra-traefik:
	${DOCKER_INFRA} --profile base up -d

down-infra:
	${DOCKER_INFRA} --profile headscale down --remove-orphans

logs-infra:
	${DOCKER_INFRA} logs -f

ps-infra:
	${DOCKER_INFRA} ps

restart-infra: down-infra up-infra

gen-certs:
	@echo "Generating certificates for *.$(HOST_DOMAIN) and $(HOST_DOMAIN)"

	mkcert "*.$(HOST_DOMAIN)" "$(HOST_DOMAIN)"
	mv *.pem ${LAB_DIR}/config/traefik/certs/