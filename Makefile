# Default env file (can override: make ENV_FILE=.env.prod)
ENV_FILE ?= .env

# List of templates
TEMPLATES = \
    config/adguard/confdir/AdGuardHome.example.yaml \
	config/headplane/config.example.yaml \
	config/headscale/config/config.example.yaml \

CONFIGS = $(TEMPLATES:.example.yaml=.yaml)

.PHONY: all config clean

all: config

config: $(CONFIGS)

# Rule: generate config from template with envsubst
%.yaml: %.example.yaml $(ENV_FILE)
	@echo "Using $(ENV_FILE) to generate $@"
	@env $$(grep -v '^#' $(ENV_FILE) | xargs) \
		envsubst < $< > $@

clean:
	@rm -f $(CONFIGS)
