FROM ghcr.io/forkbombeu/ncr@sha256:89083ad6d0363039914e34d02a41964fcd970d71f2426f0d9fca84df9d5b912e

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
