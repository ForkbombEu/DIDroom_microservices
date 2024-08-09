FROM ghcr.io/forkbombeu/ncr:latest

RUN apt update && apt install -y jq && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --chmod=777 scripts/autorun_search.sh scripts/autorun_search.sh
COPY --chmod=777 scripts/autorun_store.sh scripts/autorun_store.sh

ENV FILES_DIR=.
