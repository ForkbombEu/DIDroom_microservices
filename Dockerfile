FROM ghcr.io/forkbombeu/ncr:1.39.8

RUN apt update && apt install -y jq make && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --chmod=777 scripts/autorun_search.sh scripts/autorun_search.sh
COPY --chmod=777 scripts/autorun_store.sh scripts/autorun_store.sh
COPY --chmod=777 scripts/authorize.sh scripts/authorize.sh
COPY --chmod=777 scripts/up.sh scripts/up.sh

COPY Makefile Makefile

ENV FILES_DIR=.
