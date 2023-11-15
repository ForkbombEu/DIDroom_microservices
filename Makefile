.DEFAULT_GOAL := up
.PHONY: help


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
	./ncr -p 3000

