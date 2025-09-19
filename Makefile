# Default env file (can override: make ENV_FILE=.env.prod)
ENV_FILE ?= .env
include .env

# List of templates
TEMPLATES = \
    config/adguard/confdir/AdGuardHome.example.yaml \
	config/headplane/config.example.yaml \
	config/headscale/config/config.example.yaml \

CONFIGS = $(TEMPLATES:.example.yaml=.yaml)

.PHONY: all config clean

all: help

help:
	@echo "Usage: "
	@echo "make config - Generates config using .env file"
	@echo "make step-ca - Configures Smallstep CA files"
	@echo

local:
	./c down infra/step-ca
	./c down infra/traefik

	./c up infra/step-ca
	./c up infra/traefik

step-ca:
	@echo Removing previous config...

	@sudo rm ${LAB_DIR}/config/traefik/letsencrypt/acme-stepca.json
	@sudo touch ${LAB_DIR}/config/traefik/letsencrypt/acme-stepca.json
	@sudo chmod 600 ${LAB_DIR}/config/traefik/letsencrypt/acme-stepca.json

	@rm ${LAB_DIR}/config/step-ca -rf
	@mkdir ${LAB_DIR}/config/step-ca

	@echo Stopping previous instances...
	@docker stop step-ca-setup > /dev/null 2>&1 || true
	@docker rm step-ca-setup > /dev/null 2>&1 || true

	@echo Starting config...
	@docker run -d -v ${LAB_DIR}/config/step-ca:/home/step \
		-p 127.0.0.1:9000:9000 \
		-e "DOCKER_STEPCA_INIT_NAME=Smallstep" \
		-e "DOCKER_STEPCA_INIT_DNS_NAMES=localhost,$(hostname -f),step-ca" \
		--name step-ca-setup \
       smallstep/step-ca > /dev/null

	@sleep 5s
	@echo Adding ACME provider...
	@docker exec step-ca-setup sh -c "step ca provisioner add acme --type ACME" > /dev/null 2>&1

	@sleep 1s
	@echo
	@docker logs step-ca-setup 2>&1 | grep -iE "Your CA administrative password is|Serving HTTPS on"
	@echo

	@echo Cleaning...
	@docker stop step-ca-setup > /dev/null
	@docker rm step-ca-setup > /dev/null
	@echo Done!

config: $(CONFIGS)

# Rule: generate config from template with envsubst
%.yaml: %.example.yaml $(ENV_FILE)
	@echo "Using $(ENV_FILE) to generate $@"
	@env $$(grep -v '^#' $(ENV_FILE) | xargs) \
		envsubst < $< > $@

clean:
	@rm -f $(CONFIGS)
