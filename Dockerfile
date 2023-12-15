FROM ghcr.io/forkbombeu/ncr:latest
RUN apt update && apt install -y curl && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY authz_server/ authz_server
COPY credential_issuer/ credential_issuer
COPY public/ public/
HEALTHCHECK --interval=10s --timeout=5s --start-period=5s \
   CMD curl --fail localhost:${PORT}/credential_issuer/health || exit 1
CMD ["--public-directory", "public"]
