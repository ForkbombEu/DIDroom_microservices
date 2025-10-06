FROM ghcr.io/forkbombeu/ncr@sha256:77918c47ca7096e3d4b4048dbd8d4810aa0a94085672f3b5992c0ba485754e2b

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
