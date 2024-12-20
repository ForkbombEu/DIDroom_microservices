FROM ghcr.io/forkbombeu/ncr@sha256:437b10cbc871a253baf5b387c72fde04f64e8e906e475b723936f5a857a5c32b

RUN apt update && apt install -y jq make && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --chmod=777 scripts/autorun_search.sh scripts/autorun_search.sh
COPY --chmod=777 scripts/autorun_store.sh scripts/autorun_store.sh
COPY --chmod=777 scripts/authorize.sh scripts/authorize.sh
COPY --chmod=777 scripts/up.sh scripts/up.sh

COPY Makefile Makefile

ENV FILES_DIR=.
