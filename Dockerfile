FROM ghcr.io/forkbombeu/ncr@sha256:3c4be8b30e56b9cc6871c1f458e2f0802d9de12bc61c9de8b5d7cb5c96c603ba

RUN apt update && apt install -y jq make wget && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --chmod=777 scripts/autorun_search.sh scripts/autorun_search.sh
COPY --chmod=777 scripts/autorun_store.sh scripts/autorun_store.sh
COPY --chmod=777 scripts/authorize.sh scripts/authorize.sh
COPY --chmod=777 scripts/credential.sh scripts/credential.sh
COPY --chmod=777 scripts/verifier.sh scripts/verifier.sh
COPY --chmod=777 scripts/up.sh scripts/up.sh

COPY Makefile Makefile

ENV FILES_DIR=.
