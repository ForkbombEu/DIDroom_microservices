.DEFAULT_GOAL := up
.PHONY: help

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

help: ## 🛟 Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-7s\033[0m %s\n", $$1, $$2}'

ncr: ## 📦 Install and setup the server
	@wget -q --show-progress https://github.com/forkbombeu/ncr/releases/latest/download/ncr
	@chmod +x ./ncr
	@echo "📦 Setup is done!"

announce: SERVICE ?= all
announce: ncr ## 📡 Create and send a DID request for the oracle [SERVICE]
ifeq ("${SERVICE}", "all")
	./ncr -p 8000 -z ./authz_server --public-directory public/authz_server & echo $$! > .announce.as.pid
	./ncr -p 8001 -z ./credential_issuer --public-directory public/credential_issuer & echo $$! > .announce.ci.pid
	./ncr -p 8002 -z ./relying_party --public-directory public/relying_party & echo $$! > .announce.rp.pid
	sleep 10
	kill `cat .announce.as.pid` && rm .announce.as.pid
	kill `cat .announce.ci.pid` && rm .announce.ci.pid
	kill `cat .announce.rp.pid` && rm .announce.rp.pid
else ifneq (,$(filter ${SERVICE}, authz_server credential_issuer relying_party))
	./ncr -p 8000 -z ./${SERVICE} --public-directory public/${SERVICE} & echo $$! > .announce.pid
	sleep 10
	kill `cat .announce.pid` && rm .announce.pid
else
	$(error "Unknown service: ${SERVICE}. Known service are: authz_server, credential_issuer, relying_party or all")
endif

up: ncr announce ## 🚀 Up & run the project
	./ncr -p 3000 --hostname $(hn) --public-directory public

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
	cp .env.test .env

authz_server_up: ncr
	./ncr -p 3000 -z ./authz_server --public-directory tests/public/authz_server & echo $$! > .test.authz_server.pid
	sleep 5

credential_issuer_up: ncr
	./ncr -p 3001 -z ./credential_issuer --public-directory tests/public/credential_issuer & echo $$! > .test.credential_issuer.pid
	sleep 5

mobile_zencode_up: ncr
	./ncr -p 3002 -z ./tests/mobile_zencode/wallet & echo $$! > .test.mobile_zencode.pid
	sleep 5

relying_party_up: ncr
	./ncr -p 3003 -z ./relying_party --public-directory tests/public/relying_party & echo $$! > .test.relying_party.pid
	sleep 5

verifier_up: ncr
	./ncr -p 3004 -z ./tests/mobile_zencode/verifier & echo $$! > .test.verifier.pid
	sleep 5

push_server_up: ncr
	./ncr -p 3366 -z ./tests/test_push_server & echo $$! > .test.push_server.pid
	sleep 5

test: tests-well-known tests/mobile_zencode authz_server_up credential_issuer_up mobile_zencode_up relying_party_up verifier_up push_server_up ## 🧪 Run e2e tests on the APIs
	npx stepci run tests/e2e.yml
	@kill `cat .test.credential_issuer.pid` && rm .test.credential_issuer.pid
	@kill `cat .test.authz_server.pid` && rm .test.authz_server.pid
	@kill `cat .test.mobile_zencode.pid` && rm .test.mobile_zencode.pid
	@kill `cat .test.relying_party.pid` && rm .test.relying_party.pid
	@kill `cat .test.verifier.pid` && rm .test.verifier.pid
	@kill `cat .test.push_server.pid` && rm .test.push_server.pid
	rm -fr tests/mobile_zencode
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