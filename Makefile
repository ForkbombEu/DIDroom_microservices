# env variables
$(if $(wildcard .env),, $(shell cp .env.example .env))
include .env

.DEFAULT_GOAL := up
.PHONY: help
TEST_DEPS := git jq npx
DEPLOY_DEPS := wget jq awk

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

all:
	$(foreach exec,$(DEPLOY_DEPS),$(if $(shell which $(exec)),,$(error "🥶 `$(exec)` not found in PATH please install it")))

help: ## 🛟  Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(firstword $(MAKEFILE_LIST)) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-10s\033[0m %s\n", $$1, $$2}'

ncr: ## 📦 Install and setup the server
	@wget -q --show-progress https://github.com/forkbombeu/ncr/releases/latest/download/ncr
	@chmod +x ./ncr
	@echo "📦 Setup is done!"

authorize: tmp := $(shell mktemp)
authorize: tmp_zen := $(shell mktemp)
authorize: tmp_schema := $(shell mktemp)
authorize: tmp_keys := $(shell mktemp)
authorize: AUTHZ_FILE?=public/authz_server/authorize
authorize: ## 📦 Setup the authorize page
authorize:
	@echo "{}" > ${tmp_schema}
	@echo "{}" > ${tmp_zen}
	@echo "{}" > ${tmp_keys}
	@if [ -d authz_server/custom_code ] && [ -f ${AUTHZ_FILE} ]; then \
		for f in authz_server/custom_code/*; do \
			name=$$(echo $$f | rev | cut -d'/' -f1 | rev | cut -d'.' -f1); \
			ext=$$(echo $$f | cut -d'.' -f2-); \
			if [ -f $$f ] && [ "$$ext" = "schema.json" ]; then \
			jq --arg name $$name '.[$$name] = input ' ${tmp_schema} $$f > ${tmp} && mv ${tmp} ${tmp_schema}; \
			elif [ -f $$f ] && [ "$$ext" = "zen" ]; then \
			jq --arg name $$name --arg contract "$$(sed -z 's/\n/\\n/g' $$f)" '.[$$name] = $$contract ' ${tmp_zen} > ${tmp} && mv ${tmp} ${tmp_zen}; \
			elif [ -f $$f ] && [ "$$ext" = "keys.json" ]; then \
			jq --arg name $$name '.[$$name] = input ' ${tmp_keys} $$f > ${tmp} && mv ${tmp} ${tmp_keys}; \
			fi; \
		done; \
		awk -v c="$$(jq -r tostring ${tmp_zen})" '{gsub ("const contracts = .*", "const contracts = " c); print}' ${AUTHZ_FILE} > ${tmp} && mv ${tmp} ${AUTHZ_FILE}; \
		awk -v s="$$(jq -r tostring ${tmp_schema})"  '{gsub ("const schemas = .*", "const schemas = " s); print}' ${AUTHZ_FILE} > ${tmp} && mv ${tmp} ${AUTHZ_FILE}; \
		awk -v k="$$(jq -r tostring ${tmp_keys})"          '{gsub ("const keys = .*", "const keys = " k); print}' ${AUTHZ_FILE} > ${tmp} && mv ${tmp} ${AUTHZ_FILE}; \
	fi;
	@rm ${tmp_schema} ${tmp_zen} ${tmp_keys}

up: UP_PORT?=3000
up: UP_HOSTNAME?=${hn}
up: ncr authorize ## 🚀 Up & run the project
	$(if ${MS_URL},,$(error "Set MS_URL in .env with the url of the service"),)
	@chmod +x scripts/autorun_search.sh
	@chmod +x scripts/autorun_store.sh
	service=$$(ls | grep "authz_server\$$\|credential_issuer\$$\|relying_party\$$" --color=never | awk '{printf "%s ", $$1}'); \
	if [ -z "$${service}" ]; then \
		echo "😢 No service found"; \
		exit 1; \
	fi; \
	port=${UP_PORT}; \
	for s in $${service}; do \
		echo "🐣 Starting service: $${s}"; \
		name=${MS_NAME}; \
		if [ -z "$${name}" ]; then name=$$s; fi; \
		MS_NAME=$$name BASEPATH='/'$$s ./ncr -p $$port -z $$s --public-directory public/$$s & echo $$! > $$s.pid; \
		port=$$((port+1)); \
	done

# -- tests --

tests-deps: ## 🧪 Check test dependencies
	$(foreach exec,$(TEST_DEPS),$(if $(shell which $(exec)),,$(error "🥶 `$(exec)` not found in PATH please install it")))

tests-well-known:
	./scripts/wk.sh setup

tests/mobile_zencode:
	git clone https://github.com/forkbombeu/mobile_zencode tests/mobile_zencode

authz_server_up: ncr
	rm -rf authz_server/secrets.keys
	MS_NAME=test_authz_server MS_URL=http://localhost:3000 ./ncr -p 3000 -z ./authz_server --public-directory public/authz_server & echo $$! > .test.authz_server.pid

credential_issuer_up: ncr
	rm -rf credential_issuer/secrets.keys
	MS_NAME=test_credential_issuer MS_URL=http://localhost:3001 ./ncr -p 3001 -z ./credential_issuer --public-directory public/credential_issuer & echo $$! > .test.credential_issuer.pid

mobile_zencode_up: ncr
	./ncr -p 3002 -z ./tests/mobile_zencode/wallet & echo $$! > .test.mobile_zencode.pid

relying_party_up: ncr
	rm -rf relying_party/secrets.keys
	MS_NAME=test_relying_party MS_URL=http://localhost:3003 ./ncr -p 3003 -z ./relying_party --public-directory public/relying_party & echo $$! > .test.relying_party.pid

verifier_up: ncr
	./ncr -p 3004 -z ./tests/mobile_zencode/verifier & echo $$! > .test.verifier.pid

push_server_up: ncr
	./ncr -p 3366 -z ./tests/test_push_server & echo $$! > .test.push_server.pid

test_custom_code:
# custom code
	@for f in authz_server/custom_code/*.example; do \
		name=$$(echo $$f | rev | cut -d'.' -f2- | rev); \
		cp $$f $${name}; \
	done;
	@for f in credential_issuer/custom_code/*.example; do \
		name=$$(echo $$f | rev | cut -d'.' -f2- | rev); \
		cp $$f $${name}; \
	done;

test: test_custom_code tests-deps tests-well-known tests/mobile_zencode authz_server_up credential_issuer_up mobile_zencode_up relying_party_up verifier_up push_server_up ## 🧪 Run e2e tests on the APIs
# modify wallet contract to not use capacitor
	@cat tests/mobile_zencode/wallet/ver_qr_to_info.zen | sed "s/.*Given I connect to 'pb_url' and start capacitor pb client.*/Given I connect to 'pb_url' and start pb client\nGiven I send my_credentials 'my_credentials' and login/" > tests/mobile_zencode/wallet/temp_ver_qr_to_info.zen
	@cp tests/mobile_zencode/wallet/ver_qr_to_info.keys.json tests/mobile_zencode/wallet/temp_ver_qr_to_info.keys.json
	@cp tests/mobile_zencode/wallet/ver_qr_to_info.schema.json tests/mobile_zencode/wallet/temp_ver_qr_to_info.schema.json
	@cp relying_party/verify.keys.json relying_party/temp-verify.keys.json
	@jq '.keys_0.firebase_url = "http://localhost:3366/verify-credential"' relying_party/temp-verify.keys.json > relying_party/verify.keys.json
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
	@kill `cat .test.credential_issuer.pid` && rm .test.credential_issuer.pid
	@kill `cat .test.authz_server.pid` && rm .test.authz_server.pid
	@kill `cat .test.mobile_zencode.pid` && rm .test.mobile_zencode.pid
	@kill `cat .test.relying_party.pid` && rm .test.relying_party.pid
	@kill `cat .test.verifier.pid` && rm .test.verifier.pid
	@kill `cat .test.push_server.pid` && rm .test.push_server.pid
	rm -fr tests/mobile_zencode
	@mv relying_party/temp-verify.keys.json relying_party/verify.keys.json
	@./scripts/wk.sh cleanup

testgen:
	wget http://localhost:3000/oas.json
	npx stepci generate ./oas.json ./tests/oapi.yml
	rm oas.json

clean:
	rm -rf tests/mobile_zencode
	rm -f ncr
	rm -f .env
	rm -f *.pid
	rm -f */secrets.keys