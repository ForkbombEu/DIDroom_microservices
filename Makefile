.DEFAULT_GOAL := up
.PHONY: help

FILES_DIR := .
export FILES_DIR

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

setup: ## 📦 Install and setup the server
ifeq (,$(wildcard ncr))
	@wget -q --show-progress https://github.com/forkbombeu/ncr/releases/latest/download/ncr
	@chmod +x ./ncr
	@echo "📦 Setup is done!"
endif

up:setup ## 🚀 Up & run the project
	./ncr -p 3000 --hostname $(hn) --public-directory public

test: ## 🧪 Run e2e tests on the APIs
	@./ncr -p 3000 & echo $$! > .test.ncr.pid
	npx stepci run tests/authz_server.yml
	@kill `cat .test.ncr.pid` && rm .test.ncr.pid

testgen:
	wget http://localhost:3000/oas.json
	npx stepci generate ./oas.json ./tests/oapi.yml
	rm oas.json
