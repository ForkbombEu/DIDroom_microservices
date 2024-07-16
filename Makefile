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

announce: ANN_PORT?=8000
announce: ncr ## 📡 Create and send a DID request for the service
	@service=$$(ls | grep "authz_server\|credential_issuer\|relying_party" --color=never | awk '{printf "%s ", $$1}'); \
	if [ "$${service}" != "" ]; then echo "🐣 Announce services: $${service}"; else echo "😢 No service found"; false; fi; \
	for s in $${service}; do \
		./ncr -p ${ANN_PORT} -z $$s --public-directory public/$$s & echo $$! > .announce.pid; \
		timeout --foreground 30s bash -c ' \
			until nc -z localhost $$1; do \
				echo "Port $$1 is not yet reachable, waiting..."; \
				sleep 1; \
			done' _ "${ANN_PORT}" \
		|| { \
			echo "Timeout while waiting for port $$1 to be reachable"; \
			exit 1; \
		}; \
		kill `cat .announce.pid` && rm .announce.pid; \
		sleep 1; \
	done

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
up: ncr announce authorize ## 🚀 Up & run the project
	./ncr -p ${UP_PORT} --hostname ${UP_HOSTNAME} --public-directory public


# -- tests --

tests-deps: ## 🧪 Check test dependencies
	$(foreach exec,$(TEST_DEPS),$(if $(shell which $(exec)),,$(error "🥶 `$(exec)` not found in PATH please install it")))

tests-well-known: tmp := $(shell mktemp)
tests-well-known:
# as
	@jq '."well-known_path" = "tests/public/authz_server/.well-known/oauth-authorization-server"' authz_server/.autorun/identity.keys.json > ${tmp} && mv ${tmp} authz_server/.autorun/identity.keys.json
	@jq '."well-known_path" = "tests/public/authz_server/.well-known/oauth-authorization-server"' authz_server/par.keys.json > ${tmp} && mv ${tmp} authz_server/par.keys.json
	@jq '."well-known_path" = "tests/public/authz_server/.well-known/oauth-authorization-server"' authz_server/token.keys.json > ${tmp} && mv ${tmp} authz_server/token.keys.json
	@jq '."well-known_path" = "tests/public/authz_server/.well-known/oauth-authorization-server"' authz_server/ru_to_ac.keys.json > ${tmp} && mv ${tmp} authz_server/ru_to_ac.keys.json
	@jq '."well-known_path" = "tests/public/authz_server/.well-known/oauth-authorization-server"' authz_server/ru_to_toc.keys.json > ${tmp} && mv ${tmp} authz_server/ru_to_toc.keys.json
# ci
	@jq '."well-known_path" = "tests/public/credential_issuer/.well-known/openid-credential-issuer"' credential_issuer/credential.keys.json > ${tmp} && mv ${tmp} credential_issuer/credential.keys.json
	@jq '."well-known_path" = "tests/public/credential_issuer/.well-known/openid-credential-issuer"' credential_issuer/.autorun/identity.keys.json > ${tmp} && mv ${tmp} credential_issuer/.autorun/identity.keys.json
# rp
	@jq '."well-known_path" = "tests/public/relying_party/.well-known/openid-relying-party"' relying_party/verify.keys.json > ${tmp} && mv ${tmp} relying_party/verify.keys.json
	@jq '."well-known_path" = "tests/public/relying_party/.well-known/openid-relying-party"' relying_party/.autorun/identity.keys.json > ${tmp} && mv ${tmp} relying_party/.autorun/identity.keys.json
	@rm -f ${tmp}

tests/mobile_zencode:
	git clone https://github.com/forkbombeu/mobile_zencode tests/mobile_zencode

authz_server_up: ncr
	MS_NAME=test_authz_server MS_URL=http://localhost:3000 ./ncr -p 3000 -z ./authz_server --public-directory tests/public/authz_server & echo $$! > .test.authz_server.pid

credential_issuer_up: ncr
	MS_NAME=test_credential_issuer MS_URL=http://localhost:3001 ./ncr -p 3001 -z ./credential_issuer --public-directory tests/public/credential_issuer & echo $$! > .test.credential_issuer.pid

mobile_zencode_up: ncr
	./ncr -p 3002 -z ./tests/mobile_zencode/wallet & echo $$! > .test.mobile_zencode.pid

relying_party_up: ncr
	MS_NAME=test_relying_party MS_URL=http://localhost:3003 ./ncr -p 3003 -z ./relying_party --public-directory tests/public/relying_party & echo $$! > .test.relying_party.pid

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
	@jq '."firebase_url" = "http://localhost:3366/verify-credential"' relying_party/temp-verify.keys.json > relying_party/verify.keys.json
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
	git restore authz_server/.autorun/identity.keys.json
	git restore authz_server/par.keys.json
	git restore authz_server/token.keys.json
	git restore authz_server/ru_to_ac.keys.json
	git restore authz_server/ru_to_toc.keys.json
	git restore credential_issuer/credential.keys.json
	git restore credential_issuer/.autorun/identity.keys.json
	git restore relying_party/verify.keys.json
	git restore relying_party/.autorun/identity.keys.json

testgen:
	wget http://localhost:3000/oas.json
	npx stepci generate ./oas.json ./tests/oapi.yml
	rm oas.json

clean:
	rm -rf tests/mobile_zencode
	rm -f ncr
	rm -f .env
