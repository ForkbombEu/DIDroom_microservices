FROM ghcr.io/forkbombeu/ncr:latest
WORKDIR /app
COPY authz_server/ authz_server
COPY credential_issuer/ credential_issuer
COPY public/ public/
CMD ["--public-directory", "public"]
