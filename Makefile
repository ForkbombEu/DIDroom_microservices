# env variables
$(if $(wildcard ".env"),,$(shell cp .env.example .env))
include .env

.DEFAULT_GOAL := up
.PHONY: help
TEST_DEPS := git jq npx

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

WGET := $(shell command -v wget 2> /dev/null)

all:
ifndef WGET
    $(error "🥶 wget is not available! Please retry after you install it")
endif

help: ## 🛟  Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(firstword $(MAKEFILE_LIST)) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-10s\033[0m %s\n", $$1, $$2}'

ncr: ## 📦 Install and setup the server
	@wget -q --show-progress https://github.com/forkbombeu/ncr/releases/latest/download/ncr
	@chmod +x ./ncr
	@echo "📦 Setup is done!"

announce: ANN_PORT?=8000
announce: ANN_AS_PORT?=8000
announce: ANN_CI_PORT?=8001
announce: ANN_RP_PORT?=8002
announce: SERVICE?=all
announce: ncr ## 📡 Create and send a DID request for the oracle [SERVICE]
	@case ${SERVICE} in \
		all) \
			./ncr -p ${ANN_AS_PORT} -z ./authz_server --public-directory public/authz_server & echo $$! > .announce.as.pid; \
			./ncr -p ${ANN_CI_PORT} -z ./credential_issuer --public-directory public/credential_issuer & echo $$! > .announce.ci.pid; \
			./ncr -p ${ANN_RP_PORT} -z ./relying_party --public-directory public/relying_party & echo $$! > .announce.rp.pid; \
			for port in ${ANN_AS_PORT} ${ANN_CI_PORT} ${ANN_RP_PORT}; do \
				timeout 30s bash -c 'port=$$1; until nc -z localhost $$port; do \
					echo "Port $$port is not yet reachable, waiting..."; \
					sleep 1; \
					done' _ "$$port" || { \
						echo "Timeout while waiting for port $$port to be reachable"; \
						exit 1; \
					}; \
			done; \
			kill `cat .announce.as.pid` && rm .announce.as.pid; \
			kill `cat .announce.ci.pid` && rm .announce.ci.pid; \
			kill `cat .announce.rp.pid` && rm .announce.rp.pid; \
			;; \
		authz_server|credential_issuer|relying_party) \
			./ncr -p ${ANN_PORT} -z ./${SERVICE} --public-directory public/${SERVICE} & echo $$! > .announce.pid; \
			timeout 30s bash -c 'port=$$1; until nc -z localhost $$port; do \
				echo "Port $$port is not yet reachable, waiting..."; \
				sleep 1; \
				done' _ "${ANN_PORT}" || { \
					echo "Timeout while waiting for port $$port to be reachable"; \
					exit 1; \
				}; \
			kill `cat .announce.pid` && rm .announce.pid; \
			;; \
		*) \
			echo "Unknown service: ${SERVICE}. Known service are: authz_server, credential_issuer, relying_party or all"; \
			exit 1; \
			;; \
	esac

authorize: tmp := $(shell mktemp)
authorize: tmp_zen := $(shell mktemp)
authorize: tmp_schema := $(shell mktemp)
authorize: tmp_keys := $(shell mktemp)
authorize: ## 📦 Setup the authorize page
authorize:
	@echo "{}" > ${tmp_schema}
	@echo "{}" > ${tmp_zen}
	@echo "{}" > ${tmp_keys}
	@if [ -d authz_server/custom_code ] && [ -f public/authz_server/authorize ]; then \
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
		awk -v c="$$(jq -r tostring ${tmp_zen})" '{gsub ("const contracts = .*", "const contracts = " c); print}' public/authz_server/authorize > ${tmp} && mv ${tmp} public/authz_server/authorize; \
		awk -v s="$$(jq -r tostring ${tmp_schema})"  '{gsub ("const schemas = .*", "const schemas = " s); print}' public/authz_server/authorize > ${tmp} && mv ${tmp} public/authz_server/authorize; \
		awk -v k="$$(jq -r tostring ${tmp_keys})"          '{gsub ("const keys = .*", "const keys = " k); print}' public/authz_server/authorize > ${tmp} && mv ${tmp} public/authz_server/authorize; \
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
	@jq '."well-known_path" = "tests/public/authz_server/.well-known/oauth-authorization-server"' authz_server/authorize.keys.json > ${tmp} && mv ${tmp} authz_server/authorize.keys.json
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
	./ncr -p 3000 -z ./authz_server --public-directory tests/public/authz_server & echo $$! > .test.authz_server.pid

credential_issuer_up: ncr
	./ncr -p 3001 -z ./credential_issuer --public-directory tests/public/credential_issuer & echo $$! > .test.credential_issuer.pid

mobile_zencode_up: ncr
	./ncr -p 3002 -z ./tests/mobile_zencode/wallet & echo $$! > .test.mobile_zencode.pid

relying_party_up: ncr
	./ncr -p 3003 -z ./relying_party --public-directory tests/public/relying_party & echo $$! > .test.relying_party.pid

verifier_up: ncr
	./ncr -p 3004 -z ./tests/mobile_zencode/verifier & echo $$! > .test.verifier.pid

push_server_up: ncr
	./ncr -p 3366 -z ./tests/test_push_server & echo $$! > .test.push_server.pid

test: tests-deps tests-well-known tests/mobile_zencode authz_server_up credential_issuer_up mobile_zencode_up relying_party_up verifier_up push_server_up ## 🧪 Run e2e tests on the APIs
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
	git restore authz_server/authorize.keys.json
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
