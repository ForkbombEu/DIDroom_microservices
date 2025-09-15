# env variables
ifneq ($(wildcard .env),)
	include .env
	export
else
	ifneq ($(wildcard .env.example),)
		include .env.example
		export
	endif
endif

.DEFAULT_GOAL := up
.PHONY: help
TEST_DEPS := git jq npx
DEPLOY_DEPS := wget jq awk wc
NCR_VERSION := 1.43.1
NCR_URL := https://github.com/ForkbombEu/ncr/releases/download/v$(NCR_VERSION)/ncr

hn=$(shell hostname)

# detect the operating system
OSFLAG 				:=
ifneq ($(OS),Windows_NT)
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S),Linux)
		OSFLAG += LINUX
	endif
	ifeq ($(UNAME_S),Darwin)
		OSFLAG += OSX
	endif
endif

deps:
	$(foreach exec,$(DEPLOY_DEPS),$(if $(shell which $(exec)),,$(error "🥶 `$(exec)` not found in PATH please install it")))

help: ## 🛟  Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(firstword $(MAKEFILE_LIST)) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-10s\033[0m %s\n", $$1, $$2}'

ncr: deps ## 📦 Install and setup the server
	@if [ ! -x ./ncr ] || [ "$$(./ncr -v)" != "${NCR_VERSION}" ]; then \
		wget -q --show-progress $(NCR_URL) -O ncr; \
		chmod +x ./ncr; \
	fi
	@echo "📦 Setup is done! Ncr version ${NCR_VERSION} installed"

authorize: deps ## 📦 Setup the authorize page
	@chmod +x scripts/authorize.sh
	@./scripts/authorize.sh

credential: deps ## 📦 Setup the credential issuer
	@chmod +x scripts/credential.sh
	@./scripts/credential.sh

up: UP_PORT?=3000
up: ncr authorize credential ## 🚀 Up & run the project
	$(if ${MS_URL},,$(error "Set MS_URL in .env with the url of the service"),)
	@chmod +x scripts/up.sh
	@./scripts/up.sh ${UP_PORT} ${MS_NAME}

# -- tests --

tests-deps: # 🧪 Check test dependencies
	$(foreach exec,$(TEST_DEPS),$(if $(shell which $(exec)),,$(error "🥶 `$(exec)` not found in PATH please install it")))

tests/mobile_zencode:
	git clone https://github.com/forkbombeu/mobile_zencode tests/mobile_zencode
	cd tests/mobile_zencode && git checkout feat/draft_15

mobile_zencode_up: ncr tests/mobile_zencode
	./ncr -p 3003 -z ./tests/mobile_zencode/wallet & echo $$! > .test.mobile_zencode.pid
	./ncr -p 3004 -z ./tests/mobile_zencode/verifier & echo $$! > .test.verifier.pid

test_custom_code:
	@cp tests/custom_code/as/* authz_server/custom_code/
	@cp tests/custom_code/ci/* credential_issuer/custom_code/

test_wk:
	@./scripts/wk.sh setup

test: tests-deps test_custom_code test_wk up mobile_zencode_up # 🧪 Run e2e tests on the APIs
# modify wallet contract to not use capacitor
	@cat tests/mobile_zencode/wallet/ver_qr_to_info.zen | sed "s/.*Given I connect to 'pb_url' and start capacitor pb client.*/Given I connect to 'pb_url' and start pb client\nGiven I send my_credentials 'my_credentials' and login/" > tests/mobile_zencode/wallet/temp_ver_qr_to_info.zen
	@cp tests/mobile_zencode/wallet/ver_qr_to_info.keys.json tests/mobile_zencode/wallet/temp_ver_qr_to_info.keys.json
	@cp tests/mobile_zencode/wallet/ver_qr_to_info.schema.json tests/mobile_zencode/wallet/temp_ver_qr_to_info.schema.json
# start tests
	@for port in 3000 3001 3002 3003 3004 3366; do \
		timeout 30s bash -c 'port=$$1; until nc -z localhost $$port; do \
			echo "Port $$port is not yet reachable, waiting..."; \
			sleep 1; \
			done' _ "$$port" || { \
				echo "Timeout while waiting for port $$port to be reachable"; \
				exit 1; \
			}; \
	done
	npx stepci run tests/e2e.yml
	@kill `cat .credential_issuer.pid` && rm .credential_issuer.pid
	@kill `cat .authz_server.pid` && rm .authz_server.pid
	@kill `cat .verifier.pid` && rm .verifier.pid
	@kill `cat .test.mobile_zencode.pid` && rm .test.mobile_zencode.pid
	@kill `cat .test.verifier.pid` && rm .test.verifier.pid
	@rm -fr tests/mobile_zencode
	@rm -f authz_server/custom_code/*
	@rm -f credential_issuer/custom_code/*
	@./scripts/wk.sh cleanup

testgen:
	wget http://localhost:3000/oas.json
	npx stepci generate ./oas.json ./tests/oapi.yml
	rm oas.json

clean: ## 🧹 Clean
	rm -rf tests/mobile_zencode
	rm -f ncr
	rm -f .env
	rm -f .test.*.pid
	rm -f .*.pid
	rm -rf credential_issuer/nonces/ relying_party/temp-verify.keys.json

deepclean: clean # 🧹 Deep clean (stops all ncr, remove keys and restore well-knowns)
	git restore */.autorun/identity.metadata.json public/*/.well-known
	git clean -fd */custom_code public/*/.well-known
	git restore credential_issuer/credential.chain.yaml public/authz_server/authorize relying_party/verify.keys.json
	rm -f */secrets.keys
	pkill ncr || true
