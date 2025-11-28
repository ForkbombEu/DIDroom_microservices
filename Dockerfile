FROM ghcr.io/forkbombeu/ncr@sha256:1f69ed6e90975994dc4132e2ce3c9318a49d1a9d219fe949c4e006ebd091344f

RUN apt update && apt install -y jq make wget && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --chmod=777 scripts/autorun_search.sh scripts/autorun_search.sh
COPY --chmod=777 scripts/autorun_store.sh scripts/autorun_store.sh
COPY --chmod=777 scripts/authorize.sh scripts/authorize.sh
COPY --chmod=777 scripts/credential.sh scripts/credential.sh
COPY --chmod=777 scripts/verifier.sh scripts/verifier.sh
COPY --chmod=777 scripts/up.sh scripts/up.sh
COPY --chmod=777 scripts/qrcode.sh scripts/qrcode.sh

COPY Makefile Makefile

ENV FILES_DIR=.
